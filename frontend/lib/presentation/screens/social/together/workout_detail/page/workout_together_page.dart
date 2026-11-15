import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../app/di/app_di.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../extensions/context_extensions.dart';
import '../../../../../mixins/errors_message_mixin.dart';
import '../../../../../theme/tokens.g.dart';
import '../../../../../widgets/widgets.dart';
import '../../../social_routes.dart';
import '../../widgets/together_labels.dart';
import '../../widgets/together_widgets.dart';
import '../../widgets/workout_together_progress.dart';
import '../bloc/workout_together_bloc.dart';

/// «Entrenamos juntos» (ADR 0044 y 0047): pantalla de espera con quién está
/// dentro y un único «Empezar» que puede pulsar cualquiera y empieza para
/// todos; si lo pulsa otra persona, se entra sola en la sesión en vivo de
/// siempre. Después, quién lleva cada ejercicio y, al terminar, la tarjeta
/// conjunta.
class WorkoutTogetherPage extends StatelessWidget {
  const WorkoutTogetherPage({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<WorkoutTogetherBloc>()
                ..add(WorkoutTogetherEvent.started(workoutId)),
        ),
        BlocProvider(create: (_) => createSafetyBloc()),
      ],
      child: const _WorkoutView(),
    );
  }
}

class _WorkoutView extends StatelessWidget with ErrorsMessageMixin {
  const _WorkoutView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<WorkoutTogetherBloc>();
    return TogetherSafetyListener(
      onBlocked: (blockedId) {
        if (bloc.state.workout?.host.id == blockedId) {
          Navigator.of(context).maybePop();
        } else {
          bloc.add(const WorkoutTogetherEvent.polled(live: true));
        }
      },
      child: BlocConsumer<WorkoutTogetherBloc, WorkoutTogetherState>(
        listenWhen: (p, c) =>
            (c.openSession != null && c.openSession != p.openSession) ||
            (c.closed && !p.closed) ||
            (c.left && !p.left) ||
            (c.actionError != null && c.actionError != p.actionError),
        listener: (context, state) {
          if (state.actionError case final error?) {
            context.showSnack(errorMessage(context, error));
          } else if (state.openSession case final sessionId?) {
            // Empezó otra persona: se dice al lector una vez y se entra.
            context.push(SocialExternalPaths.trainingSession(sessionId));
            // Se dice cuando la sesión ya está en pantalla: antes, el cambio de
            // pantalla cortaría el anuncio.
            if (state.startedByOther) {
              final view = View.of(context);
              final direction = Directionality.of(context);
              final message = l10n.togetherStartedAnnounce(
                togetherName(context, state.workout?.startedBy?.name ?? ''),
              );
              Future<void>.delayed(
                const Duration(milliseconds: 800),
                () => SemanticsService.sendAnnouncement(view, message, direction),
              );
            }
          } else if (state.left) {
            context.showUndoSnack(
              l10n.togetherWorkoutLeft,
              onUndo: () => bloc.add(const WorkoutTogetherEvent.joined()),
              onCommit: () => context.leaveAfterUndo(SocialPaths.together),
            );
          } else if (state.closed) {
            context.showSnack(l10n.togetherDeclined);
            context.popOrGo(SocialPaths.together);
          }
        },
        builder: (context, state) {
          final w = state.workout;
          return Scaffold(
            appBar: AppPageBar.reading(
              leading: const AppBackButton(fallback: SocialPaths.together),
              title: Text(w?.routineName ?? l10n.togetherWorkoutTitle),
            ),
            body: switch (state.status) {
              WorkoutTogetherStatus.loading => const AppSkeletonList(),
              WorkoutTogetherStatus.failure => AppErrorView(
                error: state.error!,
                onRetry: () =>
                    bloc.add(WorkoutTogetherEvent.started(state.id!)),
              ),
              WorkoutTogetherStatus.ready => _Body(
                workout: w!,
                busy: state.busy,
              ),
            },
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.workout, required this.busy});

  final WorkoutTogether workout;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final w = workout;
    final bloc = context.read<WorkoutTogetherBloc>();
    final me = w.members.where((m) => m.me).firstOrNull;
    final finished = me?.state == WorkoutMemberState.finished;
    final joined = w.myStatus == TogetherMemberStatus.joined;
    final dayLabel = w.dayName?.isNotEmpty == true
        ? w.dayName!
        : l10n.togetherDayNumber(w.dayNumber);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.xxl,
      ),
      children: [
        AppContentWidth.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                w.today
                    ? l10n.togetherWorkoutToday(dayLabel)
                    : l10n.togetherWorkoutOn(
                        dayLabel,
                        DateFormat.MMMEd(
                          context.localizations.localeName,
                        ).format(w.date),
                      ),
                style: context.textStyles.bodyLarge,
              ),
              // A la vez (ADR 0047): antes de empezar se explica que es para
              // todos; después, que ya está en marcha.
              if (w.today && (joined || w.invitation) && !finished) ...[
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  w.started ? l10n.togetherRunning : l10n.togetherWaitingStart,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: TokensSpacing.m),
              if (finished && w.myMinutes != null)
                WorkoutTogetherSummary(workout: w)
              else if (w.today && (joined || w.invitation)) ...[
                AppPrimaryButton(
                  label: w.mySessionId != null
                      ? l10n.togetherKeepTraining
                      : (w.invitation
                            ? l10n.togetherJoinAndStart
                            : l10n.togetherStart),
                  icon: AppIcons.start,
                  loading: busy,
                  onPressed: () =>
                      bloc.add(const WorkoutTogetherEvent.startRequested()),
                ),
                if (w.invitation)
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => bloc.add(const WorkoutTogetherEvent.declined()),
                    child: Text(l10n.togetherDecline),
                  ),
              ],
              const SizedBox(height: TokensSpacing.m),
              AppSectionHeader(title: l10n.togetherWhoDidWhat),
              WorkoutTogetherProgress(workout: w),
              const SizedBox(height: TokensSpacing.m),
              AppSectionHeader(title: l10n.togetherPeople),
              for (final m in w.members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AppAvatar(
                    name: togetherName(context, m.person.name),
                    imageUrl: m.person.avatarUrl,
                  ),
                  title: Text(
                    m.me
                        ? l10n.togetherYou
                        : togetherName(context, m.person.name),
                  ),
                  subtitle: Text(
                    m.status == TogetherMemberStatus.invited
                        ? l10n.togetherMemberInvited
                        : m.state.label(context),
                  ),
                  trailing: m.me
                      ? null
                      : TogetherMemberMenu(
                          person: m.person,
                          reportContext: UserReportContext.workoutTogether,
                        ),
                ),
              if (joined && w.today && !finished) ...[
                const SizedBox(height: TokensSpacing.l),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: busy
                        ? null
                        : () => bloc.add(const WorkoutTogetherEvent.left()),
                    icon: const Icon(AppIcons.leave),
                    label: Text(l10n.togetherLeaveWorkout),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
