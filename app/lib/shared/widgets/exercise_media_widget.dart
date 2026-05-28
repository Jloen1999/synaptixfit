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

  @override
  State<ExerciseMediaWidget> createState() => _ExerciseMediaWidgetState();
}

class _ExerciseMediaWidgetState extends State<ExerciseMediaWidget> {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _isVideo = false;

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
    _videoCtrl?.dispose();
    _videoCtrl = null;
    _videoReady = false;
    _isVideo = false;
  }

  void _prepare() {
    final url = widget.url;
    if (url == null || url.isEmpty) return;

    if (url.endsWith('.mp4') && widget.size == ExerciseMediaSize.hero) {
      _isVideo = true;
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _videoReady = true);
          _videoCtrl!.setLooping(true);
          _videoCtrl!.play();
        }).catchError((_) {
          if (!mounted) return;
          setState(() => _videoReady = true);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    final radius = widget.borderRadius ??
        BorderRadius.circular(widget.size == ExerciseMediaSize.mini ? 8 : 14);

    return ClipRRect(
      borderRadius: radius,
      child: GestureDetector(
        onTap: () {
          if (_isVideo && _videoReady && _videoCtrl != null) {
            setState(() {
              if (_videoCtrl!.value.isPlaying) {
                _videoCtrl!.pause();
              } else {
                _videoCtrl!.play();
              }
            });
          }
          widget.onTap?.call();
        },
        child: _buildContent(context, url, radius),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, String? url, BorderRadiusGeometry radius) {
    if (url == null || url.isEmpty) return _buildFallback(context, radius);

    if (_isVideo) {
      if (_videoReady && _videoCtrl != null) {
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            VideoPlayer(_videoCtrl!),
            if (!_videoCtrl!.value.isPlaying) _playButtonOverlay(),
          ],
        );
      }
      return _buildVideoPlaceholder(context, radius);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: widget.fit,
      placeholder: (_, __) => _buildPlaceholder(context, radius),
      errorWidget: (_, __, ___) => _buildFallback(context, radius),
    );
  }

  Widget _buildVideoPlaceholder(
      BuildContext context, BorderRadiusGeometry radius) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A40), Color(0xFF0D1B2A)],
        ),
        borderRadius: radius,
      ),
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_rounded,
                  size: widget.size == ExerciseMediaSize.hero ? 48 : 24,
                  color: Colors.white.withValues(alpha: 0.5)),
              if (widget.size == ExerciseMediaSize.hero) ...[
                const SizedBox(height: 12),
                Text(
                  'Cargando video...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    color: SVColors.secondaryContainer,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ],
            ],
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

  Widget _buildPlaceholder(BuildContext context, BorderRadiusGeometry radius) {
    return Container(
      color: SVColors.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
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
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.fitness_center_rounded,
                      size: isTiny ? 20 : 28,
                      color: SVColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
              if (widget.size == ExerciseMediaSize.hero) ...[
                const SizedBox(height: 8),
                Text(
                  'Vista previa no disponible',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SVColors.onSurfaceMuted,
                      ),
                ),
              ],
            ] else
              Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: SVColors.onSurfaceMuted,
              ),
          ],
        ),
      ),
    );
  }
}
