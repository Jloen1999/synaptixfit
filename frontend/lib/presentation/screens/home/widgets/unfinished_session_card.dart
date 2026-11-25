import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../../training/widgets/exercise_thumbnail.dart';
import '../../training/widgets/training_dialogs.dart';
import '../../training/widgets/training_labels.dart';

/// «Sin terminar: Pierna y empuje» arriba de Inicio (ADR 0059): cuál es,
/// cuándo empezó y cuánto se hizo, con dos botones y debajo de cada uno qué
/// hace. «Guardar lo hecho» la termina con lo registrado (pide minutos y
/// esfuerzo, como en Gimnasio); «Descartar» (rojo y aparte) confirma y deja
/// «Deshacer». Cuándo sale lo decide el servidor (de otro día o abierta más
/// de 6 h). Lo resuelve el bloc de Inicio.
class UnfinishedSessionCard extends StatelessWidget {
  const UnfinishedSessionCard({
    super.key,
    required this.session,
    required this.onSave,
    required this.onDiscard,
    this.busy = false,
    this.titleFocus,
    this.onOpen,
  });

  final HomeUnfinishedSession session;

  /// Minutos y esfuerzo elegidos para guardarla.
  final void Function(SessionFigures figures) onSave;
  final VoidCallback onDiscard;
  final bool busy;

  /// Recibe el foco cuando «Empezar» no pudo por esta sesión.
  final FocusNode? titleFocus;

  /// Abre la sesión (lo que se marcó; allí también se termina o descarta).
  final VoidCallback? onOpen;

  /// Nombre de la sesión: el del día, el día de la semana o «Sesión libre».
  static String nameOf(BuildContext context, HomeUnfinishedSession s) {
    final l10n = context.localizations;
    final number = s.dayNumber;
    if (number == null) return s.dayName ?? l10n.trainingSessionFree;
    return dayTitle(l10n, number, s.dayName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final name = nameOf(context, session);
    final started = l10n.homeUnfinishedStarted(
      DateFormat.MMMMEEEEd(l10n.localeName).format(session.startedAt),
      DateFormat.Hm(l10n.localeName).format(session.startedAt),
    );
    final total = session.exercisesTotal;
    final done = session.exercisesDone;
    final progress = total == null
        ? l10n.homeUnfinishedExercisesDone(done)
        : l10n.homeUnfinishedExercisesOf(done, total);
    final accent = context.palette.warning;
    final hint = context.textStyles.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final title = l10n.homeUnfinishedTitle(name);

    Widget withHint(Widget button, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        const SizedBox(height: TokensSpacing.xxs),
        Text(text, style: hint),
      ],
    );

    final save = withHint(
      AppPrimaryButton(
        label: l10n.homeUnfinishedSave,
        loading: busy,
        onPressed: busy
            ? null
            : () async {
                final figures = await showSessionFiguresDialog(
                  context,
                  confirmLabel: l10n.commonSave,
                  subtitle: name,
                );
                if (figures != null) onSave(figures);
              },
      ),
      l10n.homeUnfinishedSaveHint(done),
    );
    // Descartar no guarda: en rojo y aparte (vocabulario §4).
    final discard = withHint(
      AppDangerButton(
        icon: null,
        onPressed: busy
            ? null
            : () async {
                final ok = await showConfirmDialog(
                  context,
                  title: l10n.homeUnfinishedDiscardTitle(name),
                  message: l10n.homeUnfinishedDiscardMessage,
                  confirmLabel: l10n.homeUnfinishedDiscard,
                );
                if (ok) onDiscard();
              },
        label: l10n.homeUnfinishedDiscard,
      ),
      l10n.homeUnfinishedDiscardHint,
    );

    return Semantics(
      container: true,
      child: AppCard(
        padding: const EdgeInsets.all(TokensSpacing.m),
        color: Color.alphaBlend(
          accent.withValues(alpha: AppPill.tintAlpha),
          context.colors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCardTapArea(
              onTap: onOpen,
              semanticHint: l10n.homeUnfinishedOpenHint,
              child: Row(
                children: [
                  ExerciseThumbnail(
                    url: session.coverImageUrl,
                    size: TokensSize.thumbnailS,
                  ),
                  const SizedBox(width: TokensSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MaybeAnchor(
                          focusNode: titleFocus,
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: context.textStyles.titleMedium,
                            ),
                          ),
                        ),
                        Text(
                          '$started · $progress',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onOpen != null)
                    Icon(
                      AppIcons.next,
                      size: TokensSize.iconS,
                      color: context.colors.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            // Lado a lado en móvil; con texto grande, uno debajo del otro.
            if (context.largeText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  save,
                  const SizedBox(height: TokensSpacing.m),
                  discard,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: save),
                  const SizedBox(width: TokensSpacing.m),
                  Expanded(child: discard),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Ancla de foco solo si hay nodo (en los tests de la tarjeta suelta no hay).
class _MaybeAnchor extends StatelessWidget {
  const _MaybeAnchor({required this.focusNode, required this.child});

  final FocusNode? focusNode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final node = focusNode;
    return node == null ? child : AppFocusAnchor(focusNode: node, child: child);
  }
}
