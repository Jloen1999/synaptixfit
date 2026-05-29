import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/design_system/sv_colors.dart';

enum ExerciseMediaSize { mini, card, hero }

class ExerciseMediaWidget extends StatefulWidget {
  const ExerciseMediaWidget({
    required this.url,
    this.size = ExerciseMediaSize.card,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onTap,
    super.key,
  });

  final String? url;
  final ExerciseMediaSize size;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  bool get _useVideoPlayer => size == ExerciseMediaSize.hero;

  @override
  State<ExerciseMediaWidget> createState() => _ExerciseMediaWidgetState();
}

class _ExerciseMediaWidgetState extends State<ExerciseMediaWidget> {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _videoInitFailed = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant ExerciseMediaWidget old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _disposeVideo();
      _prepare();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _videoCtrl?.pause();
    _videoCtrl?.dispose();
    _videoCtrl = null;
    _videoReady = false;
    _videoInitFailed = false;
  }

  void _prepare() {
    final url = widget.url;
    if (url == null || url.isEmpty) return;
    if (!url.endsWith('.mp4')) return;
    if (_videoCtrl != null) return;

    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoCtrl!.initialize().then((_) {
      if (!mounted) {
        _videoCtrl?.dispose();
        _videoCtrl = null;
        return;
      }
      setState(() => _videoReady = true);
      _videoCtrl!.setLooping(true);
      _videoCtrl!.setVolume(0);
      if (widget._useVideoPlayer) {
        _videoCtrl!.play();
      }
    }).catchError((_) {
      if (!mounted) return;
      _videoCtrl?.dispose();
      _videoCtrl = null;
      setState(() => _videoInitFailed = true);
    });
  }

  void _toggleMute() {
    if (_videoCtrl == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoCtrl!.setVolume(_isMuted ? 0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHero = widget._useVideoPlayer;
    final radius = widget.borderRadius ??
        BorderRadius.circular(widget.size == ExerciseMediaSize.mini ? 8 : 14);
    final content = _buildContent(context, radius);

    if (isHero) {
      final screenW = MediaQuery.of(context).size.width;
      final h = screenW >= 900 ? 280.0 : 220.0;
      return Container(
        height: h,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: SVColors.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    final w = widget.size == ExerciseMediaSize.mini ? 48.0 : 72.0;
    return SizedBox(
      width: w,
      height: w,
      child: ClipRRect(borderRadius: radius, child: content),
    );
  }

  Widget _buildContent(BuildContext context, BorderRadiusGeometry radius) {
    final url = widget.url;
    if (url == null || url.isEmpty) {
      return _buildFallback(context, radius);
    }

    if (url.endsWith('.mp4')) {
      if (_videoInitFailed) {
        return _buildFallback(context, radius);
      }
      if (_videoReady && _videoCtrl != null) {
        final isHero = widget._useVideoPlayer;
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            VideoPlayer(_videoCtrl!),
            if (isHero) ...[
              Positioned(top: 8, right: 8, child: _muteButton()),
              if (!_videoCtrl!.value.isPlaying) _playButtonOverlay(),
            ] else
              GestureDetector(
                onTap: () {
                  if (!_videoCtrl!.value.isPlaying) {
                    _videoCtrl!.play();
                    setState(() {});
                  }
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        size: widget.size == ExerciseMediaSize.mini ? 16 : 24,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
              ),
          ],
        );
      }
      return _buildVideoLoading(radius);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: widget.fit,
      placeholder: (_, __) => Container(
        color: SVColors.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      errorWidget: (_, __, ___) => _buildFallback(context, radius),
    );
  }

  Widget _muteButton() {
    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVideoLoading(BorderRadiusGeometry radius) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A40), Color(0xFF0D1B2A)],
        ),
        borderRadius: radius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_rounded, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          Text('Cargando video...',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              color: SVColors.secondaryContainer,
              backgroundColor: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playButtonOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(14),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SVColors.secondaryContainer.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: SVColors.secondary.withValues(alpha: 0.4),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded,
              size: 32, color: SVColors.secondary),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, BorderRadiusGeometry radius) {
    final isTiny = widget.size == ExerciseMediaSize.mini;
    return Container(
      decoration: BoxDecoration(
        color: SVColors.surfaceContainerHighest,
        borderRadius: radius,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isTiny) ...[
              Opacity(
                opacity: 0.4,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset('assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.fitness_center_rounded,
                          size: 28,
                          color: SVColors.onSurfaceMuted)),
                ),
              ),
              if (widget.size == ExerciseMediaSize.hero) ...[
                const SizedBox(height: 8),
                Text('Vista previa no disponible',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: SVColors.onSurfaceMuted)),
              ],
            ] else
              const Icon(Icons.fitness_center_rounded,
                  size: 20, color: SVColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}
