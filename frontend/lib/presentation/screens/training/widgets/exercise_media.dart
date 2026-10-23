import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';

/// Demostración del ejercicio: vídeo (mp4/webm) o imagen animada (GIF).
class ExerciseMedia extends StatelessWidget {
  const ExerciseMedia({
    super.key,
    required this.gifUrl,
    required this.previewUrl,
    required this.semanticLabel,
  });

  final String? gifUrl;
  final String? previewUrl;
  final String semanticLabel;

  static bool _isVideo(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    return path.endsWith('.mp4') ||
        path.endsWith('.webm') ||
        path.endsWith('.mov');
  }

  @override
  Widget build(BuildContext context) {
    final url = gifUrl ?? previewUrl;
    final fallback = Container(
      color: context.colors.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center_rounded,
        size: 64,
        color: context.colors.onSecondaryContainer,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(TokensRadius.l),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Semantics(
          label: semanticLabel,
          image: true,
          child: url == null
              ? fallback
              : _isVideo(url)
              ? _LoopingVideo(url: url, fallback: fallback)
              : ColoredBox(
                  color: context.colors.surfaceContainerLow,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, _) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, _, _) => fallback,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LoopingVideo extends StatefulWidget {
  const _LoopingVideo({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  State<_LoopingVideo> createState() => _LoopingVideoState();
}

class _LoopingVideoState extends State<_LoopingVideo> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _failed = false;
  bool _started = false;

  /// Arranca solo si el sistema no pide reducir el movimiento; en cualquier
  /// caso el usuario puede pausarlo o reanudarlo (WCAG 2.2.2).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final autoplay = !context.reduceMotion;
    _controller
        .initialize()
        .then((_) async {
          await _controller.setLooping(true);
          await _controller.setVolume(0);
          if (autoplay) await _controller.play();
          if (mounted) setState(() {});
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  Future<void> _toggle() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    if (!_controller.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          semanticsLabel: context.localizations.commonLoading,
        ),
      );
    }
    final l10n = context.localizations;
    final playing = _controller.value.isPlaying;
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
        PositionedDirectional(
          end: TokensSpacing.s,
          bottom: TokensSpacing.s,
          child: IconButton.filledTonal(
            tooltip: playing ? l10n.trainingVideoPause : l10n.trainingVideoPlay,
            onPressed: _toggle,
            icon: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
        ),
      ],
    );
  }
}
