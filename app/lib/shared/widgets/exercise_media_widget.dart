import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/design_system/sv_colors.dart';

enum ExerciseMediaSize { mini, card, hero, dialog }

class ExerciseMediaWidget extends StatefulWidget {
  const ExerciseMediaWidget({
    required this.url,
    this.previewUrl,
    this.size = ExerciseMediaSize.card,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onTap,
    super.key,
  });

  final String? url;
  final String? previewUrl;
  final ExerciseMediaSize size;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  bool get _useVideoPlayer =>
      size == ExerciseMediaSize.hero || size == ExerciseMediaSize.dialog;

  @override
  State<ExerciseMediaWidget> createState() => _ExerciseMediaWidgetState();
}

class _ExerciseMediaWidgetState extends State<ExerciseMediaWidget> {
  static const _maxVideoCacheSize = 6;
  static final Map<String, VideoPlayerController> _videoCache = {};

  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _videoInitFailed = false;

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
    if (_videoCtrl == null) return;
    if (widget._useVideoPlayer) {
      _videoCtrl!.pause();
      _videoCtrl!.seekTo(Duration.zero);
      _cacheController(widget.url, _videoCtrl!);
    } else {
      _videoCtrl!.pause();
      _videoCtrl!.dispose();
    }
    _videoCtrl = null;
    _videoReady = false;
    _videoInitFailed = false;
  }

  void _cacheController(String? url, VideoPlayerController ctrl) {
    if (url == null || url.isEmpty) return;
    _videoCache.remove(url);
    if (_videoCache.length >= _maxVideoCacheSize) {
      _videoCache.remove(_videoCache.keys.first)?.dispose();
    }
    _videoCache[url] = ctrl;
  }

  void _prepare() {
    final url = widget.url;
    if (url == null || url.isEmpty) return;
    if (!url.endsWith('.mp4')) return;
    if (!widget._useVideoPlayer) return;

    final cached = _videoCache.remove(url);
    if (cached != null) {
      _videoCtrl = cached;
      _videoReady = true;
      cached.setVolume(0);
      cached.seekTo(Duration.zero);
      cached.play();
      if (mounted) setState(() {});
      return;
    }

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
      _videoCtrl!.play();
    }).catchError((_) {
      if (!mounted) return;
      _videoCtrl?.dispose();
      _videoCtrl = null;
      setState(() => _videoInitFailed = true);
    });
  }

  static const _heroBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final isHero = widget.size == ExerciseMediaSize.hero;
    final isDialog = widget.size == ExerciseMediaSize.dialog;
    final radius = widget.borderRadius ??
        BorderRadius.circular(widget.size == ExerciseMediaSize.mini ? 8 : 14);
    final content = _buildContent(context, radius);

    if (isDialog) {
      return ClipRRect(borderRadius: radius, child: content);
    }

    if (isHero) {
      final screenW = MediaQuery.of(context).size.width;
      final maxH = screenW >= 900 ? 350.0 : 280.0;
      return Container(
        constraints: BoxConstraints(
          maxWidth: screenW - 32,
          maxHeight: maxH,
        ),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _heroBg,
          borderRadius: radius,
          border: Border.all(
            color: SVColors.outlineVariant.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: SVColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
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
      return _buildMp4Thumbnail(radius);
    }

    if (widget._useVideoPlayer) {
      if (!url.endsWith('.mp4')) {
        return _buildMp4Thumbnail(radius);
      }
      if (_videoInitFailed) {
        return _buildFallback(context, radius);
      }
      if (_videoReady && _videoCtrl != null) {
        final videoRatio = _videoCtrl!.value.aspectRatio;
        return AspectRatio(
          aspectRatio: videoRatio,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              VideoPlayer(_videoCtrl!),
              if (!_videoCtrl!.value.isPlaying) _playButtonOverlay(),
            ],
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildThumbnailWhileLoading(radius),
          _buildVideoLoading(radius),
        ],
      );
    }

    return _buildMp4Thumbnail(radius);
  }

  Widget _buildThumbnailWhileLoading(BorderRadiusGeometry radius) {
    final preview = widget.previewUrl;
    if (preview != null && preview.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: preview,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMp4Thumbnail(BorderRadiusGeometry radius) {
    final preview = widget.previewUrl;
    final isHero = widget._useVideoPlayer;
    if (preview != null && preview.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: preview,
        fit: isHero ? BoxFit.contain : widget.fit,
        placeholder: (_, __) => _buildThumbnailPlaceholder(radius),
        errorWidget: (_, __, ___) => _buildThumbnailPlaceholder(radius),
      );
    }
    return _buildThumbnailPlaceholder(radius);
  }

  Widget _buildThumbnailPlaceholder(BorderRadiusGeometry radius) {
    final isTiny = widget.size == ExerciseMediaSize.mini;
    return Container(
      decoration: BoxDecoration(
        color: widget._useVideoPlayer ? _heroBg : null,
        gradient: widget._useVideoPlayer
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2B4A), Color(0xFF1A3A5C)],
              ),
        borderRadius: radius,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: isTiny ? 16 : 28,
              color: widget._useVideoPlayer
                  ? SVColors.outlineVariant.withValues(alpha: 0.3)
                  : SVColors.secondaryContainer.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLoading(BorderRadiusGeometry radius) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: radius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_rounded,
              size: 48, color: SVColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Cargando video...',
              style: TextStyle(
                  color: SVColors.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              color: SVColors.primary,
              backgroundColor: SVColors.outlineVariant.withValues(alpha: 0.2),
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
    final isHero = widget._useVideoPlayer;
    return Container(
      decoration: BoxDecoration(
        color: isHero ? _heroBg : SVColors.surfaceContainerHighest,
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
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.fitness_center_rounded,
                          size: 28,
                          color: isHero
                              ? SVColors.onSurfaceMuted
                              : SVColors.onSurfaceMuted)),
                ),
              ),
              if (isHero) ...[
                const SizedBox(height: 8),
                Text('Vista previa no disponible',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: SVColors.onSurfaceMuted)),
              ],
            ] else
              Icon(Icons.fitness_center_rounded,
                  size: 20,
                  color: isHero
                      ? SVColors.onSurfaceMuted
                      : SVColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}
