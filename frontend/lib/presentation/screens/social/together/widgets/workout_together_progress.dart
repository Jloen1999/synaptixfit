import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/together_enums.dart';
import '../../../../../domain/models/social/together.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../social_routes.dart';
import '../live/bloc/workout_together_live_bloc.dart';
import 'together_labels.dart';

/// Por cada ejercicio del día, quién lo tiene hecho y quién lo tiene por hacer
/// (ADR 0044). Solo eso: nunca pesos, repeticiones ni esfuerzo.
class WorkoutTogetherProgress extends StatelessWidget {
  const WorkoutTogetherProgress({
    super.key,
    required this.workout,
    this.othersOnly = false,
  });

  final WorkoutTogether workout;

  /// En la sesión en vivo no hace falta verse a uno mismo.
  final bool othersOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final people = [
      for (final m in workout.members)
        if (m.status == TogetherMemberStatus.joined && !(othersOnly && m.me)) m,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final slot in workout.exercises)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
            child: Semantics(
              container: true,
              label: [
                slot.name,
                for (final m in people)
                  l10n.togetherSlotState(
                    m.me
                        ? l10n.togetherYou
                        : togetherName(context, m.person.name),
                    m.doneSlots.contains(slot.index)
                        ? l10n.togetherDone
                        : l10n.togetherToDo,
                  ),
              ].join('. '),
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      slot.name,
                      style: context.textStyles.bodyMedium,
                    ),
                  ),
                  for (final m in people)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: TokensSpacing.xs,
                      ),
                      child: _PersonMark(
                        member: m,
                        done: m.doneSlots.contains(slot.index),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Avatar de la persona con una marca de «Hecho» (o un aro vacío, «Por hacer»).
class _PersonMark extends StatelessWidget {
  const _PersonMark({required this.member, required this.done});

  final WorkoutTogetherMember member;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final name = togetherName(context, member.person.name);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppAvatar(name: name, imageUrl: member.person.avatarUrl),
        PositionedDirectional(
          end: -TokensSpacing.xxs,
          bottom: -TokensSpacing.xxs,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? AppIcons.done : AppIcons.todo,
              size: TokensSize.iconXs,
              color: done ? context.palette.success : context.colors.outline,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta conjunta al terminar: quiénes, mis minutos y cuántos ejercicios.
/// Sin pesos ni esfuerzo de nadie.
class WorkoutTogetherSummary extends StatelessWidget {
  const WorkoutTogetherSummary({super.key, required this.workout, this.onOpen});

  final WorkoutTogether workout;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final w = workout;
    final others = [
      for (final m in w.members)
        if (!m.me && m.state != WorkoutMemberState.notStarted)
          togetherName(context, m.person.name),
    ];
    final mine = w.members.where((m) => m.me).firstOrNull;
    return AppCard(
      color: context.palette.accentContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              others.isEmpty
                  ? l10n.togetherSummaryAloneTitle
                  : l10n.togetherSummaryTitle,
              style: context.textStyles.titleMedium,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            others.isEmpty
                ? l10n.togetherSummaryAlone
                : l10n.togetherSummaryWith(others.join(', ')),
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.togetherSummaryStats(
              w.myMinutes ?? 0,
              mine?.doneSlots.length ?? 0,
            ),
            style: context.textStyles.bodyMedium,
          ),
          if (onOpen != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onOpen,
                child: Text(l10n.commonView),
              ),
            ),
        ],
      ),
    );
  }
}

/// Entreno juntos dentro de la sesión en vivo (ADR 0044 y 0047): lee el
/// entreno de la sesión con [WorkoutTogetherLiveBloc] (en directo y, de
/// respaldo, cada poco) y lo da a [WorkoutTogetherPanel]. Cuando la pausa del
/// grupo cambia, avisa a la sesión ([onGroupPauseChanged]), que la adopta y la
/// anuncia al lector. No toca la sesión ni sus borradores.
class WorkoutTogetherLiveScope extends StatelessWidget {
  const WorkoutTogetherLiveScope({
    super.key,
    required this.sessionId,
    required this.onGroupPauseChanged,
    required this.child,
  });

  final String sessionId;

  /// [pausedBy]: nombre de quien puso la pausa si no fui yo; nulo si fui yo o
  /// si el grupo ya no está en pausa.
  final void Function(BuildContext context, String? pausedBy)
  onGroupPauseChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<WorkoutTogetherLiveBloc>()
            ..add(WorkoutTogetherLiveEvent.started(sessionId)),
      child: BlocListener<WorkoutTogetherLiveBloc, WorkoutTogetherLiveState>(
        // Solo cambios de verdad: la primera lectura no es una pausa nueva.
        listenWhen: (p, c) =>
            p.workout != null &&
            c.workout != null &&
            (p.workout!.pausedAt != c.workout!.pausedAt ||
                p.workout!.pausedBy?.id != c.workout!.pausedBy?.id),
        listener: (context, state) {
          final w = state.workout!;
          final by = w.pausedBy;
          final other = w.paused && by != null && by.id != w.myId;
          onGroupPauseChanged(
            context,
            other ? togetherName(context, by.name) : null,
          );
        },
        child: child,
      ),
    );
  }
}

/// Panel plegable de la sesión en vivo: con quién entreno y quién lleva cada
/// ejercicio. Lee el bloc de [WorkoutTogetherLiveScope]; si la sesión no es de
/// entrenar juntos no pinta nada.
class WorkoutTogetherPanel extends StatelessWidget {
  const WorkoutTogetherPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<WorkoutTogetherLiveBloc, WorkoutTogetherLiveState>(
      builder: (context, state) {
        final w = state.workout;
        if (w == null) return const SizedBox.shrink();
        final others = [
          for (final m in w.members)
            if (!m.me && m.status == TogetherMemberStatus.joined)
              togetherName(context, m.person.name),
        ];
        return Padding(
          padding: const EdgeInsets.only(bottom: TokensSpacing.m),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              leading: const Icon(AppIcons.friends),
              title: Text(
                others.isEmpty
                    ? l10n.togetherWaitingFriends
                    : l10n.togetherTrainingWith(others.join(', ')),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                0,
                TokensSpacing.m,
                TokensSpacing.m,
              ),
              children: [WorkoutTogetherProgress(workout: w, othersOnly: true)],
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta conjunta en el resumen de una sesión terminada, si fue de entrenar
/// juntos (lee una vez, sin consulta periódica).
class WorkoutTogetherSessionCard extends StatelessWidget {
  const WorkoutTogetherSessionCard({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<WorkoutTogetherLiveBloc>()
            ..add(WorkoutTogetherLiveEvent.started(sessionId, poll: false)),
      child: BlocBuilder<WorkoutTogetherLiveBloc, WorkoutTogetherLiveState>(
        builder: (context, state) {
          final w = state.workout;
          if (w == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.m),
            child: WorkoutTogetherSummary(
              workout: w,
              onOpen: () => context.push(SocialPaths.togetherWorkout(w.id)),
            ),
          );
        },
      ),
    );
  }
}
