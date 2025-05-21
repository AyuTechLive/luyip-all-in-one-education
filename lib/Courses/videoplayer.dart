import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:chewie/chewie.dart';
// Import for web platform registration
// This is a conditional import that should only be included for web builds
// import 'web_video_player.dart' if (dart.library.html) 'web_video_player.dart';

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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _webController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _useCustomPlayer = true; // Set this to true to force custom player

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      if (_useCustomPlayer) {
        _initializeCustomWebPlayer();
      } else {
        _initializeYoutubePlayer();
      }
    } else {
      _initializeNativePlayer();
    }
  }

  String? _extractVideoId(String url) {
    // Common YouTube URL patterns
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );

    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _initializeYoutubePlayer() {
    final String? videoId = _extractVideoId(widget.videoUrl);

    if (videoId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid YouTube URL';
      });
      return;
    }

    _webController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableCaption: false,
        pointerEvents: PointerEvents.none, // Disable pointer events
        strictRelatedVideos: true,
        showVideoAnnotations: false,
        //privacyEnhanced: true,
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _initializeCustomWebPlayer() async {
    final String? videoId = _extractVideoId(widget.videoUrl);

    if (videoId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid YouTube URL';
      });
      return;
    }

    // Create a unique viewType for this instance
    final String viewType = 'youtube-player-$videoId';

    // In a real implementation, this is where you would register the platform view
    // This registration should happen during initialization and only once per viewType
    // Example:
    // if (kIsWeb) {
    //   WebVideoPlayerFactory.registerCustomYouTubePlayer(viewType, videoId);
    // }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _initializeNativePlayer() async {
    try {
      // For native platforms, use the direct video URL if possible
      // This would require having the direct MP4 URL rather than YouTube URL
      final String? videoId = _extractVideoId(widget.videoUrl);

      if (videoId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid video URL';
        });
        return;
      }

      // In a real implementation, you would need to either:
      // 1. Have direct MP4 URLs instead of YouTube URLs
      // 2. Use a server-side proxy to get the direct MP4 URL from YouTube
      // For now, we'll show an error message
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Direct video playback not available on mobile. Please provide direct MP4 URLs.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing video: $e';
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _webController?.close();
    super.dispose();
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
                          'Loading video...',
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
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                            if (kIsWeb) {
                              if (_useCustomPlayer) {
                                _initializeCustomWebPlayer();
                              } else {
                                _initializeYoutubePlayer();
                              }
                            } else {
                              _initializeNativePlayer();
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (kIsWeb && _useCustomPlayer)
                // Custom web player using IFrameElement
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomYouTubePlayer(
                            videoId: _extractVideoId(widget.videoUrl)!,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              else if (kIsWeb && _webController != null)
                // Standard YouTube player using YoutubePlayerIFrame
                Expanded(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: YoutubePlayer(
                          controller: _webController!,
                          aspectRatio: 16 / 9,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              else if (_chewieController != null)
                // Chewie player for native
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Chewie(
                            controller: _chewieController!,
                          ),
                        ),
                      ),
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

// Custom YouTube player widget that uses HtmlElementView
class CustomYouTubePlayer extends StatelessWidget {
  final String videoId;

  const CustomYouTubePlayer({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Using dart:html for web platform through conditional import
      return HtmlElementViewCustomPlayer(videoId: videoId);
    } else {
      // Fallback for non-web platforms
      return const Center(
        child: Text('Custom player only available on web platform'),
      );
    }
  }
}

// Platform-specific implementation using HtmlElementView
class HtmlElementViewCustomPlayer extends StatelessWidget {
  final String videoId;

  const HtmlElementViewCustomPlayer({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a unique viewType for this instance
    final String viewType = 'youtube-player-$videoId';

    // In a real implementation, we need to register this view type
    // This would be done in the main.dart or during app initialization:
    // WebVideoPlayerFactory.registerCustomYouTubePlayer(viewType, videoId);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: kIsWeb
          ? HtmlElementView(viewType: viewType)
          : Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Custom player only available on web platform',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
