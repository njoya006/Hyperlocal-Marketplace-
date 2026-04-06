import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Subtle looping video background for auth screens with smooth animations.
class AuthVideoBackground extends StatefulWidget {
  /// Creates [AuthVideoBackground].
  const AuthVideoBackground({super.key});

  @override
  State<AuthVideoBackground> createState() => _AuthVideoBackgroundState();
}

class _AuthVideoBackgroundState extends State<AuthVideoBackground>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
        );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller =
          VideoPlayerController.asset('assets/videos/auth_bg_alt.mp4');

      // Preload video for smoother playback
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Configure playback settings
      await controller.setLooping(true);
      await controller.setVolume(0);

      // Set playback speed for smoother motion (slightly slower)
      await controller.setPlaybackSpeed(1.0);

      // Start playback
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _ready = true;
        _hasError = false;
      });

      // Trigger fade-in animation
      _fadeController.forward();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ready = false;
        _hasError = true;
      });
      debugPrint('Video initialization error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return _buildFallbackBackground();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video background
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
            // Optional: Add a subtle vignette overlay for depth
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build fallback background with gradient and optional loading state.
  Widget _buildFallbackBackground() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1E16),
            const Color(0xFF1A3A2C),
            const Color(0xFF2E7D32),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading background...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            )
          : _buildLoadingSkeleton(),
    );
  }

  /// Build animated loading skeleton while video is buffering.
  Widget _buildLoadingSkeleton() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated shimmer lines
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ).createShader(bounds);
            },
            child: Container(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        // Center loading indicator
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withValues(alpha: 0.6),
                  ),
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
