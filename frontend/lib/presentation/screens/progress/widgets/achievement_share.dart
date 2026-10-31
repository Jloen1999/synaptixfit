import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../domain/errors/app_error.dart';
import '../../../extensions/context_extensions.dart';
import '../../../mixins/errors_message_mixin.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Tarjeta cuadrada de un logro para compartir como imagen (1080 × 1080 px):
/// la marca, el emblema, el título y una línea de detalle sobre un degradado del
/// color del logro. Siempre con el tema oscuro, se vea la app como se vea.
class AchievementShareCard extends StatelessWidget {
  const AchievementShareCard({
    super.key,
    required this.emblem,
    required this.title,
    required this.detail,
    required this.accent,
  });

  /// Lado de la tarjeta en puntos; se captura a 1080 px.
  static const side = 320.0;

  final Widget emblem;
  final String title;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          return Container(
            width: side,
            height: side,
            padding: const EdgeInsets.all(TokensSpacing.l),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokensRadius.xl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    accent.withValues(alpha: TokensOpacity.glow / 2),
                    colors.surface,
                  ),
                  colors.surface,
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const AppBrandMark(size: TokensSize.iconL),
                    const SizedBox(width: TokensSpacing.s),
                    Text(
                      'SynaptixFit',
                      style: context.textStyles.titleMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                emblem,
                const SizedBox(height: TokensSpacing.m),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.headlineSmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Vista previa de [card] con «Compartir imagen». Al pulsarlo dibuja la tarjeta
/// a 1080 px y se la pasa a [onShare] (que la envía al bloc de la pantalla).
Future<void> showAchievementShareDialog(
  BuildContext context, {
  required AchievementShareCard card,
  required ValueChanged<Uint8List> onShare,
}) => showDialog<void>(
  context: context,
  builder: (_) => _AchievementShareDialog(card: card, onShare: onShare),
);

class _AchievementShareDialog extends StatefulWidget {
  const _AchievementShareDialog({required this.card, required this.onShare});

  final AchievementShareCard card;
  final ValueChanged<Uint8List> onShare;

  @override
  State<_AchievementShareDialog> createState() =>
      _AchievementShareDialogState();
}

class _AchievementShareDialogState extends State<_AchievementShareDialog>
    with ErrorsMessageMixin {
  final _boundary = GlobalKey();
  bool _rendering = false;
  bool _failed = false;

  Future<void> _share() async {
    setState(() {
      _rendering = true;
      _failed = false;
    });
    ByteData? data;
    try {
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: 1080 / AchievementShareCard.side,
      );
      data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
    } catch (_) {
      data = null;
    } finally {
      // Pase lo que pase, el botón deja de cargar.
      if (mounted) setState(() => _rendering = false);
    }
    if (!mounted) return;
    if (data == null) {
      setState(() => _failed = true);
      return;
    }
    Navigator.of(context).pop();
    widget.onShare(data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AlertDialog(
      title: Text(l10n.achievementSharePreview),
      content: SizedBox(
        width: AchievementShareCard.side,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FittedBox(
              child: Semantics(
                label: '${widget.card.title}. ${widget.card.detail}',
                excludeSemantics: true,
                // La imagen es de tamaño fijo: con el texto del sistema
                // ampliado se saldría de la tarjeta (la vista previa se
                // escala entera con FittedBox).
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.noScaling),
                  child: RepaintBoundary(key: _boundary, child: widget.card),
                ),
              ),
            ),
            if (_failed) ...[
              const SizedBox(height: TokensSpacing.m),
              AppInlineMessage(
                message: errorMessage(context, const AppError.unknown()),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        AppPrimaryButton(
          label: l10n.achievementShareAction,
          icon: Icons.ios_share_rounded,
          loading: _rendering,
          onPressed: _share,
        ),
      ],
    );
  }
}
