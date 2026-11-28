import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/use_cases/training/start_free_session_use_case.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../exercise_explorer/bloc/exercise_explorer_bloc.dart';
import '../../training_effect.dart';
import '../../training_routes.dart';
import '../../widgets/exercise_picker_list.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../bloc/free_session_start_bloc.dart';

/// «Sesión libre: cómo empezar» (ADR 0067): elegir ejercicios con el buscador o
/// por grupo muscular, o empezar desde un entreno anterior o un día de
/// plantilla. Una sola acción principal: «Empezar con N ejercicios».
class FreeSessionStartPage extends StatelessWidget {
  const FreeSessionStartPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            getIt<FreeSessionStartBloc>()
              ..add(const FreeSessionStartEvent.started()),
      ),
      BlocProvider(
        create: (_) =>
            getIt<ExerciseExplorerBloc>()
              ..add(const ExerciseExplorerEvent.started()),
      ),
    ],
    child: const _StartView(),
  );
}

class _StartView extends StatelessWidget {
  const _StartView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<FreeSessionStartBloc>();
    return BlocConsumer<FreeSessionStartBloc, FreeSessionStartState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) {
        switch (state.effect!) {
          // La sesión sustituye a esta pantalla: «atrás» vuelve a Entreno.
          case TrainingEffectOpenSession(:final sessionId):
            context.pushReplacement(TrainingPaths.session(sessionId));
          case final other:
            const TrainingEffectHandler().handle(context, other);
        }
      },
      builder: (context, state) {
        final count = state.chosen.length;
        final last = state.recent.firstOrNull;
        return Scaffold(
          appBar: AppPageBar(
            leading: const AppBackButton(fallback: TrainingPaths.root),
            title: Text(l10n.trainingFreeSession),
          ),
          body: TrainingContent(
            child: ExercisePickerList(
              selectedIds: {for (final e in state.chosen) e.id},
              onToggle: (e) =>
                  bloc.add(FreeSessionStartEvent.exerciseToggled(e)),
              leading: [
                Text(
                  l10n.trainingFreeStartIntro,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.trainingFreeStartFrom,
                    style: context.textStyles.titleMedium,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
                _SourceRow(
                  icon: AppIcons.repeatWorkout,
                  title: l10n.trainingFreeRepeat,
                  subtitle: last == null
                      ? (state.recentLoaded ? l10n.trainingFreeRepeatNone : '')
                      : _entryLine(context, last),
                  onTap: last == null || state.starting
                      ? null
                      : () => _repeat(context, state.recent),
                ),
                const SizedBox(height: TokensSpacing.s),
                _SourceRow(
                  icon: AppIcons.templateDay,
                  title: l10n.trainingFreeTemplateDay,
                  subtitle: l10n.trainingFreeTemplateDayHint,
                  onTap: state.starting ? null : () => _templateDay(context),
                ),
                const SizedBox(height: TokensSpacing.l),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.trainingFreeChooseExercises,
                    style: context.textStyles.titleMedium,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(TokensSpacing.m),
              child: TrainingContent(
                child: AppPrimaryButton(
                  label: count == 0
                      ? l10n.trainingFreeStartEmpty
                      : l10n.trainingFreeStartWith(count),
                  icon: AppIcons.freeSession,
                  loading: state.starting,
                  onPressed: state.starting
                      ? null
                      : () => bloc.add(
                          const FreeSessionStartEvent.startRequested(),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _repeat(
    BuildContext context,
    List<SessionHistoryEntry> recent,
  ) async {
    final bloc = context.read<FreeSessionStartBloc>();
    final chosen = await showModalBottomSheet<SessionHistoryEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => _RepeatSheet(recent: recent),
    );
    if (chosen != null) {
      bloc.add(
        FreeSessionStartEvent.startRequested(RepeatSession(chosen.session.id)),
      );
    }
  }

  Future<void> _templateDay(BuildContext context) async {
    final bloc = context.read<FreeSessionStartBloc>()
      ..add(const FreeSessionStartEvent.templatesRequested())
      ..add(const FreeSessionStartEvent.templateOpened(null));
    final day = await showModalBottomSheet<TemplateDay>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _TemplateDaySheet()),
    );
    if (day != null) bloc.add(FreeSessionStartEvent.startRequested(day));
  }
}

/// «Pierna y empuje · lun 23 nov»: nombre del entreno y su fecha.
String _entryLine(BuildContext context, SessionHistoryEntry entry) {
  final l10n = context.localizations;
  final name = entry.dayNumber != null
      ? dayTitle(l10n, entry.dayNumber!, entry.dayName)
      : l10n.trainingFreeSession;
  final at = entry.session.completedAt ?? entry.session.startedAt;
  return '$name · ${DateFormat.MMMEd(l10n.localeName).format(at)}';
}

/// Fila «empezar desde…»: icono, título y una línea; toda la fila es el botón.
class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppTintedIcon(icon: icon),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(AppIcons.next),
        ],
      ),
    ),
  );
}

/// Hoja «Repetir un entreno»: los últimos entrenos; tocar uno lo empieza.
class _RepeatSheet extends StatelessWidget {
  const _RepeatSheet({required this.recent});

  final List<SessionHistoryEntry> recent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        0,
        TokensSpacing.m,
        TokensSpacing.l,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.trainingFreeRepeat,
            style: context.textStyles.titleLarge,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        for (final entry in recent) ...[
          _SourceRow(
            icon: AppIcons.repeatWorkout,
            title: _entryLine(context, entry),
            subtitle: entry.session.exercises.isEmpty
                ? ''
                : l10n.trainingFreeExerciseCount(
                    entry.session.exercises.length,
                  ),
            onTap: () => Navigator.of(context).pop(entry),
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
      ],
    );
  }
}

/// Hoja «Un día de una plantilla»: la lista de plantillas y, al abrir una,
/// sus días (`GET /training/templates/{id}`); tocar un día lo empieza.
class _TemplateDaySheet extends StatelessWidget {
  const _TemplateDaySheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<FreeSessionStartBloc>();
    return BlocBuilder<FreeSessionStartBloc, FreeSessionStartState>(
      builder: (context, state) {
        final detail = state.templateDetail;
        final children = <Widget>[
          Semantics(
            header: true,
            child: Text(
              detail?.summary.name ?? l10n.trainingFreeTemplateDay,
              style: context.textStyles.titleLarge,
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          if (state.templatesError != null)
            AppErrorView(
              error: state.templatesError!,
              onRetry: () => state.openTemplateId == null
                  ? bloc.add(const FreeSessionStartEvent.templatesRequested())
                  : bloc.add(
                      FreeSessionStartEvent.templateOpened(
                        state.openTemplateId,
                      ),
                    ),
            )
          else if (state.openTemplateId == null) ...[
            if (state.templates == null)
              const AppSkeletonList(count: 3, height: TokensSize.skeletonRow)
            else
              for (final t in state.templates!) ...[
                _SourceRow(
                  icon: AppIcons.templateDay,
                  title: t.name,
                  subtitle: l10n.trainingFreeTemplateDays(t.daysPerWeek),
                  onTap: () =>
                      bloc.add(FreeSessionStartEvent.templateOpened(t.id)),
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
          ] else ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () =>
                    bloc.add(const FreeSessionStartEvent.templateOpened(null)),
                icon: const Icon(AppIcons.previous),
                label: Text(l10n.trainingFreeOtherTemplate),
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            if (detail == null)
              const AppSkeletonList(count: 3, height: TokensSize.skeletonRow)
            else
              for (final day in detail.days.where(
                (d) => d.exercises.isNotEmpty,
              )) ...[
                _SourceRow(
                  icon: AppIcons.freeSession,
                  title: dayTitle(l10n, day.dayNumber, day.name),
                  subtitle: l10n.trainingFreeExerciseCount(
                    day.exercises.length,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(TemplateDay(detail.summary.id, day.dayNumber)),
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
          ],
        ];
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            0,
            TokensSpacing.m,
            TokensSpacing.l,
          ),
          children: children,
        );
      },
    );
  }
}
