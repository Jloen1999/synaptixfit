import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../app/di/app_di.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../extensions/context_extensions.dart';
import '../../../../../mixins/errors_message_mixin.dart';
import '../../../../../theme/tokens.g.dart';
import '../../../../../widgets/widgets.dart';
import '../../../../planner/widgets/pomodoro_ring_painter.dart';
import '../../widgets/together_labels.dart';
import '../../widgets/together_widgets.dart';
import '../bloc/study_room_bloc.dart';

/// Sala de «Estudiar juntos» (ADR 0045): el temporizador común, quién está,
/// mis reacciones y mi asignatura (que solo veo yo). Cada ronda terminada
/// cuenta como un Pomodoro mío: lo apunta el servidor.
class StudyRoomPage extends StatelessWidget {
  const StudyRoomPage({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<StudyRoomBloc>()..add(StudyRoomEvent.started(roomId)),
        ),
        BlocProvider(create: (_) => createSafetyBloc()),
      ],
      child: const _RoomView(),
    );
  }
}

class _RoomView extends StatefulWidget {
  const _RoomView();

  @override
  State<_RoomView> createState() => _RoomViewState();
}

/// Lleva el foco a lo siguiente cuando el control pulsado desaparece
/// («Unirme» → «Empezar» → cuenta atrás; al terminar, «Volver») y anuncia el
/// final de la sala (WCAG 2.4.3 y 4.1.3).
class _RoomViewState extends State<_RoomView> with ErrorsMessageMixin {
  final _main = FocusNode(debugLabel: 'study-room-main');
  final _clock = FocusNode(debugLabel: 'study-room-clock');

  @override
  void dispose() {
    _main.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _focusAfterFrame(FocusNode node) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && node.canRequestFocus) node.requestFocus();
      });

  void _onRoomChanged(StudyRoom? before, StudyRoom after) {
    final l10n = context.localizations;
    if (before == null) return;
    if (!before.phase.over && after.phase.over) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        after.phase == StudyRoomPhase.finished
            ? l10n.togetherStudyFinishedTitle
            : l10n.togetherStudyExpiredTitle,
        Directionality.of(context),
      );
      _focusAfterFrame(_main);
    } else if (before.invitation && after.joined) {
      _focusAfterFrame(after.phase == StudyRoomPhase.waiting ? _main : _clock);
    } else if (before.phase == StudyRoomPhase.waiting &&
        after.phase != StudyRoomPhase.waiting) {
      _focusAfterFrame(_clock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<StudyRoomBloc>();
    return TogetherSafetyListener(
      // Si el bloqueo me saca a mí, la siguiente lectura dice que ya no estoy
      // y la pantalla lo enseña («Ya no estás en esta sala»).
      onBlocked: (_) => bloc.add(const StudyRoomEvent.polled()),
      child: BlocConsumer<StudyRoomBloc, StudyRoomState>(
        listenWhen: (p, c) =>
            (c.closed && !p.closed) ||
            (c.left && !p.left) ||
            (c.actionError != null && c.actionError != p.actionError),
        listener: (context, state) {
          if (state.actionError case final error?) {
            context.showSnack(errorMessage(context, error));
          } else if (state.left) {
            final navigator = Navigator.of(context);
            context.showUndoSnack(
              l10n.togetherStudyLeft,
              onUndo: () => bloc.add(const StudyRoomEvent.leaveUndone()),
              onCommit: () {
                bloc.add(const StudyRoomEvent.leaveCommitted());
                if (navigator.mounted && navigator.canPop()) navigator.pop();
              },
            );
          } else if (state.closed) {
            context.showSnack(l10n.togetherDeclined);
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          // El listener no ve la sala anterior: se compara aquí, una vez por
          // cambio de sala, y se actúa después de pintar.
          return _RoomChangeWatcher(
            room: state.room,
            onChanged: _onRoomChanged,
            child: Scaffold(
              appBar: AppPageBar.reading(title: Text(l10n.togetherStudyTitle)),
              body: switch (state.status) {
                StudyRoomStatus.loading => const AppSkeletonList(),
                StudyRoomStatus.failure
                    when state.error ==
                        const AppError.business('STUDY_ROOM_NOT_FOUND') =>
                  _Gone(focusNode: _main),
                StudyRoomStatus.failure => AppErrorView(
                  error: state.error!,
                  onRetry: () => bloc.add(StudyRoomEvent.started(state.id!)),
                ),
                StudyRoomStatus.ready when state.room!.phase.over => _Over(
                  room: state.room!,
                  focusNode: _main,
                ),
                StudyRoomStatus.ready => _Body(
                  state: state,
                  mainFocus: _main,
                  clockFocus: _clock,
                ),
              },
            ),
          );
        },
      ),
    );
  }
}

/// Avisa a la pantalla cuando cambia la sala, con la anterior y la nueva.
class _RoomChangeWatcher extends StatefulWidget {
  const _RoomChangeWatcher({
    required this.room,
    required this.onChanged,
    required this.child,
  });

  final StudyRoom? room;
  final void Function(StudyRoom? before, StudyRoom after) onChanged;
  final Widget child;

  @override
  State<_RoomChangeWatcher> createState() => _RoomChangeWatcherState();
}

class _RoomChangeWatcherState extends State<_RoomChangeWatcher> {
  @override
  void didUpdateWidget(_RoomChangeWatcher old) {
    super.didUpdateWidget(old);
    final after = widget.room;
    if (after != null && after != old.room) widget.onChanged(old.room, after);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Sala terminada o caducada: lo que queda es volver.
class _Over extends StatelessWidget {
  const _Over({required this.room, required this.focusNode});

  final StudyRoom room;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final finished = room.phase == StudyRoomPhase.finished;
    return AppEmptyState(
      icon: AppIcons.focusTimer,
      title: finished
          ? l10n.togetherStudyFinishedTitle
          : l10n.togetherStudyExpiredTitle,
      message: finished
          ? l10n.togetherStudyFinishedMessage
          : l10n.togetherStudyExpiredMessage,
      action: AppPrimaryButton(
        label: l10n.togetherStudyBack,
        icon: AppIcons.back,
        focusNode: focusNode,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Ya no estoy en la sala (salí, me bloquearon o ya no existe): reintentar no
/// serviría, así que solo se ofrece volver.
class _Gone extends StatelessWidget {
  const _Gone({required this.focusNode});

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppEmptyState(
      icon: AppIcons.friends,
      title: l10n.togetherStudyGoneTitle,
      message: l10n.socialErrorStudyRoomNotFound,
      action: AppPrimaryButton(
        label: l10n.togetherStudyBack,
        icon: AppIcons.back,
        focusNode: focusNode,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.mainFocus,
    required this.clockFocus,
  });

  final StudyRoomState state;
  final FocusNode mainFocus;
  final FocusNode clockFocus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final room = state.room!;
    final bloc = context.read<StudyRoomBloc>();
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
              AppHelpToggle(
                help: l10n.togetherStudyHelp,
                tooltip: l10n.commonHelpAbout(l10n.togetherStudyTitle),
                child: Text(
                  l10n.togetherStudyIntro,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              Focus(
                focusNode: clockFocus,
                // Nodo propio: la cuenta atrás no se funde con el texto de
                // arriba ni con los botones de abajo.
                child: Semantics(
                  container: true,
                  child: StudyRoomClock(state: state),
                ),
              ),
              const SizedBox(height: TokensSpacing.l),
              if (room.invitation) ...[
                AppPrimaryButton(
                  label: l10n.togetherJoin,
                  loading: state.busy,
                  focusNode: mainFocus,
                  onPressed: () => bloc.add(const StudyRoomEvent.joined()),
                ),
                TextButton(
                  onPressed: state.busy
                      ? null
                      : () => bloc.add(const StudyRoomEvent.declined()),
                  child: Text(l10n.togetherDecline),
                ),
              ] else if (state.inside && room.phase == StudyRoomPhase.waiting)
                AppPrimaryButton(
                  label: l10n.togetherStart,
                  icon: AppIcons.start,
                  loading: state.busy,
                  focusNode: mainFocus,
                  onPressed: () =>
                      bloc.add(const StudyRoomEvent.startRequested()),
                ),
              if (state.inside) ...[
                const SizedBox(height: TokensSpacing.m),
                _Reactions(mine: room.myReaction),
                if (state.subjects.isNotEmpty) ...[
                  const SizedBox(height: TokensSpacing.m),
                  _SubjectPicker(state: state),
                ],
              ],
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.togetherPeople),
              for (final m in room.members) _MemberTile(member: m),
              if (state.inside) ...[
                const SizedBox(height: TokensSpacing.l),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => bloc.add(const StudyRoomEvent.left()),
                    icon: const Icon(AppIcons.leave),
                    label: Text(l10n.togetherStudyLeave),
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

/// Fase y cuenta atrás de la sala. Se repinta cada segundo con el reloj del
/// móvil corregido por el del servidor; al llegar a cero pide al servidor la
/// fase siguiente. Para el lector solo cambia la fase (región viva) y los
/// minutos que quedan, nunca cada segundo.
class StudyRoomClock extends StatefulWidget {
  const StudyRoomClock({super.key, required this.state});

  final StudyRoomState state;

  @override
  State<StudyRoomClock> createState() => _StudyRoomClockState();
}

class _StudyRoomClockState extends State<StudyRoomClock> {
  Timer? _ticker;
  DateTime? _askedFor;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final room = widget.state.room;
    final remaining = widget.state.remainingAt(DateTime.now());
    // Una sola petición por final de fase: la consulta periódica sigue igual.
    if (room != null &&
        room.phase != StudyRoomPhase.waiting &&
        remaining == Duration.zero &&
        _askedFor != room.phaseEndsAt) {
      _askedFor = room.phaseEndsAt;
      context.read<StudyRoomBloc>().add(const StudyRoomEvent.polled());
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static String _clock(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final room = widget.state.room!;
    final focus = room.phase == StudyRoomPhase.focus;
    final waiting = room.phase == StudyRoomPhase.waiting;
    final color = focus ? context.palette.study : context.colors.secondary;
    final phaseText = switch (room.phase) {
      StudyRoomPhase.waiting => l10n.togetherStudyWaiting,
      StudyRoomPhase.focus => l10n.togetherStudyFocusRound(
        room.round,
        room.rounds,
      ),
      _ => l10n.togetherStudyBreakThen(room.round + 1, room.rounds),
    };
    final header = Semantics(
      header: true,
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            waiting
                ? AppIcons.friends
                : (focus ? AppIcons.focusPhase : AppIcons.breakPhase),
            color: waiting ? context.colors.onSurfaceVariant : color,
            size: TokensSize.iconM,
          ),
          const SizedBox(width: TokensSpacing.s),
          Flexible(
            child: Text(
              phaseText,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
          ),
        ],
      ),
    );
    if (waiting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: TokensSpacing.s),
          Text(
            l10n.togetherStudyPlan(
              room.rounds,
              room.focusMinutes,
              room.breakMinutes,
            ),
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    final remaining = widget.state.remainingAt(DateTime.now()) ?? Duration.zero;
    final total = Duration(
      minutes: focus ? room.focusMinutes : room.breakMinutes,
    );
    final fraction = total.inSeconds == 0
        ? 0.0
        : remaining.inSeconds / total.inSeconds;
    // Minutos que quedan, redondeados hacia arriba: «quedan 25 min» al empezar.
    final minutesLeft = (remaining.inSeconds / 60).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: TokensSpacing.m),
        Center(
          child: Semantics(
            container: true,
            label: l10n.togetherStudyMinutesLeft(minutesLeft),
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: TokensSize.pomodoroRing,
              child: CustomPaint(
                painter: PomodoroRingPainter(
                  fraction: fraction,
                  color: color,
                  trackColor: color.withValues(alpha: AppPill.tintAlpha),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _clock(remaining),
                      style: context.textStyles.displayMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Las cuatro reacciones fijas; la mía se ve marcada (con su marca, no solo el
/// color) unos minutos. No se desactivan mientras se guarda: el bloc ignora lo
/// que llega a la vez y así el foco no se pierde.
class _Reactions extends StatelessWidget {
  const _Reactions({required this.mine});

  final StudyRoomReaction? mine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Semantics(
      container: true,
      label: l10n.togetherStudyReactions,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: TokensSpacing.s,
        runSpacing: TokensSpacing.s,
        children: [
          for (final r in StudyRoomReaction.values)
            ChoiceChip(
              label: Text(
                r.emoji,
                semanticsLabel: l10n.togetherStudyReact(r.label(context)),
                style: context.textStyles.titleLarge,
              ),
              selected: r == mine,
              onSelected: (_) =>
                  context.read<StudyRoomBloc>().add(StudyRoomEvent.reacted(r)),
            ),
        ],
      ),
    );
  }
}

/// Con qué asignatura me cuentan las rondas. Solo la veo yo.
class _SubjectPicker extends StatelessWidget {
  const _SubjectPicker({required this.state});

  final StudyRoomState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final current = state.room!.mySubjectId;
    final known = state.subjects.any((s) => s.id == current);
    return DropdownButtonFormField<String?>(
      key: ValueKey(current),
      initialValue: known ? current : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.togetherStudySubjectLabel,
        prefixIcon: const Icon(AppIcons.tabAcademic),
      ),
      items: [
        DropdownMenuItem(child: Text(l10n.togetherStudyNoSubject)),
        for (final subject in state.subjects)
          DropdownMenuItem(
            value: subject.id,
            child: Text(subject.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) =>
          context.read<StudyRoomBloc>().add(StudyRoomEvent.subjectChosen(id)),
    );
  }
}

/// Persona de la sala: dentro, invitada o se ha ido, con su reacción reciente.
class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final StudyRoomMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final m = member;
    final name = m.me ? l10n.togetherYou : togetherName(context, m.person.name);
    final status = switch (m.status) {
      TogetherMemberStatus.joined => l10n.togetherStudyInside,
      TogetherMemberStatus.invited => l10n.togetherMemberInvited,
      _ => l10n.togetherStudyGone,
    };
    final reaction = m.reaction;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppAvatar(
        name: togetherName(context, m.person.name),
        imageUrl: m.person.avatarUrl,
      ),
      title: Text(name),
      subtitle: Text(
        reaction == null
            ? status
            : l10n.togetherStudyStatusReaction(status, reaction.emoji),
        semanticsLabel: reaction == null
            ? status
            : l10n.togetherStudyStatusReaction(status, reaction.label(context)),
      ),
      trailing: m.me
          ? null
          : TogetherMemberMenu(
              person: m.person,
              reportContext: UserReportContext.studyRoom,
            ),
    );
  }
}
