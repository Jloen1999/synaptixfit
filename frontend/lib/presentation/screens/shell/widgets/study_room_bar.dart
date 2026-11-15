import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/app_di.dart';
import '../../../../domain/enums/together_enums.dart';
import '../../../extensions/context_extensions.dart';
import '../../../widgets/widgets.dart';
import '../../social/social_routes.dart';
import '../bloc/study_room_bar_bloc.dart';

/// Textos del aviso del móvil al acabar cada fase de la sala.
StudyRoomAlertTexts studyRoomAlertTexts(BuildContext context) {
  final l10n = context.localizations;
  return StudyRoomAlertTexts(
    title: l10n.togetherStudyTitle,
    focusEndBody: l10n.togetherStudyAlertFocusBody,
    breakEndBody: l10n.togetherStudyAlertBreakBody,
    // El mismo canal que el Pomodoro: en Android es un solo «Temporizador».
    channelName: l10n.plannerPomodoroAlertChannel,
  );
}

/// Barra fina con la sala «Estudiar juntos» en la que estoy, sobre la
/// navegación (como la del Pomodoro, [AppTimerStrip]): la fase y su cuenta
/// atrás; tocarla vuelve a la sala. Sin pausa: la sala no se pausa. Sin sala
/// no ocupa nada.
class StudyRoomBar extends StatelessWidget {
  const StudyRoomBar({super.key});

  static String _clock(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyRoomBarBloc, StudyRoomBarState>(
      bloc: getIt<StudyRoomBarBloc>(),
      builder: (context, state) {
        final id = state.roomId;
        final phase = state.phase;
        if (id == null || phase == null) return const SizedBox.shrink();
        final l10n = context.localizations;
        final focus = phase == StudyRoomPhase.focus;
        final label = switch (phase) {
          StudyRoomPhase.focus => l10n.togetherStudyFocusRound(
            state.round,
            state.rounds,
          ),
          StudyRoomPhase.rest => l10n.togetherStudyBreakThen(
            state.round + 1,
            state.rounds,
          ),
          _ => l10n.togetherStudyWaiting,
        };
        final seconds = state.remainingSeconds;
        // A cero, mientras llega la fase siguiente del servidor, sin reloj.
        final clock = seconds == null || seconds == 0 ? '' : _clock(seconds);
        return AppTimerStrip(
          color: focus ? context.palette.study : context.colors.secondary,
          icon: AppIcons.friends,
          label: label,
          clock: clock,
          semanticLabel: clock.isEmpty
              ? l10n.togetherStudyBarLabelNoClock(label)
              : l10n.togetherStudyBarLabel(label, clock),
          onTap: () =>
              unawaited(context.push<void>(SocialPaths.togetherStudyRoom(id))),
        );
      },
    );
  }
}
