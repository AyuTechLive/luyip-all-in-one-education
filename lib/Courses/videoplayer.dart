import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:luyip_website_edu/helpers/video_helper.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui' as ui;

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String subtitle;

  const VideoPlayerPage({
    Key? key,
    required this.videoUrl,
    required this.title,
    this.subtitle = '',
  }) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  YoutubePlayerController? _mobileController;
  bool _isLoading = true;
  String? _errorMessage;
  String? _videoId;
  late String _webViewType;
  Timer? _securityTimer;

  @override
  void initState() {
    super.initState();
    _initializeSecurePlayer();
    if (kIsWeb) {
      _startSecurityMonitoring();
    }
  }

  void _startSecurityMonitoring() {
    _securityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && kIsWeb) {
        _clearConsole();
        _preventInspection();
      }
    });
  }

  void _clearConsole() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['console.clear()']);
      } catch (e) {
        // Silently fail
      }
    }
  }

  void _preventInspection() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          '''
          // Disable right-click context menu
          document.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            return false;
          });
          
          // Disable F12, Ctrl+Shift+I, Ctrl+U, Ctrl+S
          document.addEventListener('keydown', function(e) {
            if (e.key === 'F12' || 
                (e.ctrlKey && e.shiftKey && e.key === 'I') ||
                (e.ctrlKey && e.key === 'u') ||
                (e.ctrlKey && e.key === 's')) {
              e.preventDefault();
              return false;
            }
          });
          
          // Disable text selection
          document.addEventListener('selectstart', function(e) {
            e.preventDefault();
            return false;
          });
        '''
        ]);
      } catch (e) {
        // Silently fail
      }
    }
  }

  bool _isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
        url.contains('firebase') ||
        url.endsWith('.mp4');
  }

  String? _extractVideoId(String url) {
    if (_isFirebaseStorageUrl(url)) {
      return null; // This is a Firebase storage URL, not YouTube
    }

    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtu\.be\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com\/v\/)([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  void _initializeSecurePlayer() async {
    if (_isFirebaseStorageUrl(widget.videoUrl)) {
      // Handle Firebase Storage MP4 video
      if (kIsWeb) {
        await _initializeSecureMP4Player();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'MP4 playback on mobile not implemented';
        });
      }
    } else {
      // Handle YouTube video
      final String? videoId = _extractVideoId(widget.videoUrl);

      if (videoId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid video URL';
        });
        return;
      }

      setState(() {
        _videoId = videoId;
      });

      if (kIsWeb) {
        _initializeSecureWebPlayer(videoId);
      } else {
        _initializeMobilePlayer(videoId);
      }
    }
  }

  Future<void> _initializeSecureMP4Player() async {
    try {
      // Create unique view type for this video player
      _webViewType =
          'secure-mp4-player-${DateTime.now().millisecondsSinceEpoch}';

      // Register the view factory for the video player
      _registerSecureVideoPlayer();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading protected video: $e';
      });
    }
  }

  void _registerSecureVideoPlayer() {
    if (kIsWeb) {
      // Register the platform view factory
      ui_web.platformViewRegistry.registerViewFactory(_webViewType,
          (int viewId) {
        final videoElement = html.VideoElement()
          ..src = widget.videoUrl
          ..controls = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = 'black'
          ..preload = 'metadata'
          ..setAttribute('controlsList', 'nodownload noremoteplayback')
          ..setAttribute('disablePictureInPicture', 'true')
          ..setAttribute('crossorigin', 'anonymous');

        // Add security event listeners
        videoElement.onContextMenu.listen((event) {
          event.preventDefault();
        });

        videoElement.onDragStart.listen((event) {
          event.preventDefault();
        });

        // Prevent keyboard shortcuts on video
        videoElement.onKeyDown.listen((event) {
          if (event.ctrlKey || event.metaKey) {
            event.preventDefault();
          }
        });

        // Hide source URL in developer tools
        js.context.callMethod('eval', [
          '''
          (function() {
            const video = arguments[0];
            
            // Override src property to hide real URL
            Object.defineProperty(video, 'currentSrc', {
              get: function() { return 'protected://video.source'; },
              configurable: false
            });
            
            // Monitor for tampering
            let originalSrc = video.src;
            Object.defineProperty(video, 'src', {
              get: function() { return 'protected://video.source'; },
              set: function(value) { 
                if (value === originalSrc) {
                  video.setAttribute('src', value);
                }
              },
              configurable: false
            });
            
            // Remove from network tab visibility (attempt)
            video.addEventListener('loadstart', function() {
              console.clear();
            });
            
            // Error handling
            video.addEventListener('error', function(e) {
              console.error('Video load error:', e);
            });
            
            video.addEventListener('loadedmetadata', function() {
              console.log('Video loaded successfully');
            });
            
          })
        ''',
          [videoElement]
        ]);

        return videoElement;
      });
    }
  }

  void _initializeSecureWebPlayer(String videoId) {
    try {
      _webViewType = 'secure-player-${DateTime.now().millisecondsSinceEpoch}';

      if (kIsWeb) {
        registerSecureYouTubePlayer(_webViewType, videoId);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading protected video: $e';
      });
    }
  }

  void _initializeMobilePlayer(String videoId) {
    try {
      _mobileController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          startAt: 0,
          hideControls: false,
          controlsVisibleAtStart: true,
          hideThumbnail: false,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing mobile player: $e';
      });
    }
  }

  @override
  void dispose() {
    _mobileController?.dispose();
    _securityTimer?.cancel();
    super.dispose();
  }

  Widget _buildSecureMP4Player() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        color: Colors.black,
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: HtmlElementView(viewType: _webViewType),
        ),
      ),
    );
  }

  Widget _buildSecureWebPlayer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: HtmlElementView(viewType: _webViewType),
        ),
      ),
    );
  }

  Widget _buildMobilePlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: YoutubePlayer(
        controller: _mobileController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: ColorManager.primary,
        progressColors: ProgressBarColors(
          playedColor: ColorManager.primary,
          handleColor: ColorManager.primary,
        ),
        onReady: () {
          debugPrint('YouTube player is ready');
        },
        onEnded: (data) {
          debugPrint('Video ended');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: ColorManager.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textDark),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: ColorManager.textMedium,
                      fontSize: 16,
                    ),
                  ),
                ),
              if (_isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: ColorManager.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading protected video...',
                          style: TextStyle(color: ColorManager.textMedium),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: ColorManager.textMedium),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _initializeSecurePlayer();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (kIsWeb && _isFirebaseStorageUrl(widget.videoUrl))
                // Secure MP4 Player for Firebase Storage
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildSecureMP4Player()),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              else if (kIsWeb && _videoId != null)
                // Secure YouTube Web Player
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildSecureWebPlayer()),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              else if (!kIsWeb && _mobileController != null)
                // Mobile Player
                Expanded(
                  child: Column(
                    children: [
                      _buildMobilePlayer(),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text('Failed to initialize video player'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
