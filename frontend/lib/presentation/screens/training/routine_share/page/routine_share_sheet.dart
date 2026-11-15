import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/routine_share_bloc.dart';

/// Hoja «Compartir esta rutina» (ADR 0043): un toque crea el enlace y abre el
/// menú del sistema; si ya se comparte, dice hasta cuándo y deja de
/// compartirla. Quien lo abra solo verá la rutina, nada de quien la comparte.
Future<void> showRoutineShareSheet(BuildContext context, Routine routine) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => BlocProvider(
        create: (_) =>
            getIt<RoutineShareBloc>()
              ..add(RoutineShareEvent.started(routine.id)),
        child: _ShareSheet(routine: routine),
      ),
    );

class _ShareSheet extends StatelessWidget with ErrorsMessageMixin {
  const _ShareSheet({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RoutineShareBloc, RoutineShareState>(
      // Al dejar de compartir se cierra la hoja y el aviso sale en la pantalla
      // de debajo (detrás de la hoja no se vería).
      listenWhen: (p, c) => c.stopped && !p.stopped,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.trainingShareStopped)));
      },
      builder: (context, state) {
        final bloc = context.read<RoutineShareBloc>();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.l,
            0,
            TokensSpacing.l,
            TokensSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.trainingShareTitle,
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: TokensSpacing.s),
              AppHelpToggle(
                help: l10n.trainingShareHelp,
                tooltip: l10n.commonHelpAbout(l10n.trainingShareTitle),
                child: Text(
                  l10n.trainingShareIntro,
                  style: context.textStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              switch (state.status) {
                RoutineShareStatus.loading => const AppLoadingView(),
                RoutineShareStatus.failure => AppErrorView(
                  error: state.error!,
                  onRetry: () =>
                      bloc.add(RoutineShareEvent.started(state.routineId)),
                ),
                RoutineShareStatus.ready => _Actions(
                  state: state,
                  routineName: routine.name,
                ),
              },
            ],
          ),
        );
      },
    );
  }
}

class _Actions extends StatelessWidget with ErrorsMessageMixin {
  const _Actions({required this.state, required this.routineName});

  final RoutineShareState state;
  final String routineName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<RoutineShareBloc>();
    final until = state.sharedUntil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // El fallo se ve dentro de la hoja, no en un aviso tapado por ella.
        if (state.actionError case final error?) ...[
          AppInlineMessage(message: errorMessage(context, error)),
          const SizedBox(height: TokensSpacing.m),
        ],
        if (until != null) ...[
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                size: TokensSize.iconS,
                color: context.colors.primary,
              ),
              const SizedBox(width: TokensSpacing.xs),
              Expanded(
                child: Text(
                  l10n.trainingShareActiveUntil(
                    DateFormat.MMMd().format(until.toLocal()),
                  ),
                  style: context.textStyles.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
        ],
        AppPrimaryButton(
          label: l10n.trainingShareLink,
          icon: AppIcons.share,
          loading: state.busy,
          onPressed: () => bloc.add(
            RoutineShareEvent.shareRequested(
              l10n.trainingShareMessage(routineName),
            ),
          ),
        ),
        if (until != null) ...[
          const SizedBox(height: TokensSpacing.s),
          TextButton(
            onPressed: state.busy
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: l10n.trainingShareStopTitle,
                      message: l10n.trainingShareStopMessage,
                      confirmLabel: l10n.trainingShareStop,
                    );
                    if (ok) bloc.add(const RoutineShareEvent.stopRequested());
                  },
            child: Text(l10n.trainingShareStop),
          ),
        ],
      ],
    );
  }
}
