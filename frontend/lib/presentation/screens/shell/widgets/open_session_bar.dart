import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/app_di.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../../training/training_routes.dart';
import '../../training/widgets/training_labels.dart';
import '../bloc/open_session_bar_bloc.dart';

/// Barra fina sobre la navegación con la sesión de entreno que quedó abierta
/// («Sesión en pausa · 24:10 · Volver»), como la del Pomodoro. Tocarla vuelve
/// a la sesión. Sin sesión abierta no ocupa nada.
class OpenSessionBar extends StatelessWidget {
  const OpenSessionBar({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<OpenSessionBarBloc>()..add(const OpenSessionBarEvent.started()),
    child: BlocBuilder<OpenSessionBarBloc, OpenSessionBarState>(
      builder: (context, state) {
        final session = state.session;
        if (session == null) return const SizedBox.shrink();
        final l10n = context.localizations;
        final paused = session.isPaused;
        final trained = paused ? session.activeSecondsAt(session.pausedAt!) : 0;
        final status = paused
            ? l10n.trainingOpenSessionPaused(formatClock(trained))
            : l10n.trainingOpenSessionRunning;
        // «24:10» se leería como una hora: al lector, en minutos y segundos.
        final spokenStatus = paused
            ? l10n.trainingOpenSessionPaused(spokenClock(l10n, trained))
            : status;
        final color = paused ? context.palette.warning : context.palette.accent;
        return Material(
          color: Color.alphaBlend(
            color.withValues(alpha: AppPill.tintAlpha),
            context.colors.surfaceContainer,
          ),
          child: AppFocusOutline(
            child: InkWell(
              onTap: () => unawaited(
                context.push<void>(TrainingPaths.session(session.id)),
              ),
              child: Semantics(
                container: true,
                button: true,
                label: l10n.trainingOpenSessionSpoken(spokenStatus),
                excludeSemantics: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: TokensSize.listTileMin,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TokensSpacing.m,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          paused
                              ? Icons.pause_circle_rounded
                              : Icons.fitness_center_rounded,
                          color: color,
                          size: TokensSize.iconS,
                        ),
                        const SizedBox(width: TokensSpacing.s),
                        Expanded(
                          child: Text(
                            status,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelLarge,
                          ),
                        ),
                        const SizedBox(width: TokensSpacing.s),
                        Text(
                          l10n.trainingOpenSessionBack,
                          style: context.textStyles.labelLarge?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(AppIcons.next, color: context.colors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
