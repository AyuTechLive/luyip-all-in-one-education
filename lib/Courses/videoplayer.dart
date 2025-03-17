import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

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
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  final YoutubeExplode _youtubeExplode = YoutubeExplode();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Extract YouTube video ID from URL
      final videoId = _extractVideoId(widget.videoUrl);

      if (videoId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid YouTube URL';
        });
        return;
      }

      // Get the streams manifest
      final manifest = await _youtubeExplode.videos.streamsClient.getManifest(
        videoId,
      );

      // Get the highest quality muxed stream
      final streamInfo = manifest.muxed.withHighestBitrate();
      if (streamInfo == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No playable stream found for this video';
        });
        return;
      }

      // Get the stream URL
      final streamUrl = streamInfo.url.toString();

      // Create a VideoPlayerController with the stream URL
      _controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));

      // Initialize the controller and play the video
      await _controller!.initialize();
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error playing video: ${e.toString()}';
        });
      }
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

  @override
  void dispose() {
    _controller?.dispose();
    _youtubeExplode.close();
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
                            _initializePlayer();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_controller != null && _controller!.value.isInitialized)
                Expanded(
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: ColorManager.primary,
                          bufferedColor: ColorManager.primary.withOpacity(0.3),
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _controller!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: ColorManager.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_controller!.value.isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.replay_10,
                              color: ColorManager.primary,
                            ),
                            onPressed: () {
                              final currentPosition =
                                  _controller!.value.position;
                              final newPosition =
                                  currentPosition - const Duration(seconds: 10);
                              _controller!.seekTo(newPosition);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.forward_10,
                              color: ColorManager.primary,
                            ),
                            onPressed: () {
                              final currentPosition =
                                  _controller!.value.position;
                              final newPosition =
                                  currentPosition + const Duration(seconds: 10);
                              _controller!.seekTo(newPosition);
                            },
                          ),
                        ],
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
