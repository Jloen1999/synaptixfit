import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/di/app_di.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../extensions/context_extensions.dart';
import '../../../../../mixins/errors_message_mixin.dart';
import '../../../../../theme/tokens.g.dart';
import '../../../../../widgets/widgets.dart';
import '../../../social_routes.dart';
import '../../friend_picker/bloc/friend_picker_bloc.dart';
import '../../widgets/together_widgets.dart';
import '../bloc/study_invite_bloc.dart';

/// «Estudiar con amigos» (ADR 0045): duración de la ronda, cuántas rondas y con
/// quién. Una sola acción principal, «Invitar», que crea la sala y la abre.
/// Desde el Pomodoro llega su asignatura ([subjectId]); [length] permite abrirla
/// con la duración ya elegida.
class StudyInvitePage extends StatelessWidget {
  const StudyInvitePage({super.key, this.length, this.subjectId});

  final StudyRoomLength? length;
  final String? subjectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<StudyInviteBloc>()
            ..add(
              StudyInviteEvent.started(length: length, subjectId: subjectId),
            ),
        ),
        BlocProvider(
          create: (_) => getIt<FriendPickerBloc>()
            ..add(
              const FriendPickerEvent.started(
                kind: TogetherInviteKind.studyRoom,
              ),
            ),
        ),
      ],
      child: const _InviteView(),
    );
  }
}

class _InviteView extends StatelessWidget with ErrorsMessageMixin {
  const _InviteView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocListener<StudyInviteBloc, StudyInviteState>(
      listenWhen: (p, c) =>
          (c.created != null && c.created != p.created) ||
          (c.error != null && c.error != p.error),
      listener: (context, state) {
        if (state.error case final error?) {
          context.showSnack(errorMessage(context, error));
          return;
        }
        context.showSnack(l10n.togetherStudyInvited);
        context.pushReplacement(
          SocialPaths.togetherStudyRoom(state.created!.id),
        );
      },
      child: Scaffold(
        appBar: AppPageBar.reading(title: Text(l10n.togetherStudyWithFriends)),
        body: ListView(
          padding: const EdgeInsets.all(TokensSpacing.m),
          children: [
            AppContentWidth.reading(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHelpToggle(
                    help: l10n.togetherStudyHelp,
                    tooltip: l10n.commonHelpAbout(
                      l10n.togetherStudyWithFriends,
                    ),
                    child: Text(
                      l10n.togetherStudyIntro,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  const _Options(),
                  const SizedBox(height: TokensSpacing.m),
                  AppSectionHeader(title: l10n.togetherFormWho),
                  const FriendPickerList(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TokensSpacing.m),
            child: Builder(
              builder: (context) {
                final saving = context.watch<StudyInviteBloc>().state.saving;
                final picked = context.watch<FriendPickerBloc>().state.selected;
                return AppPrimaryButton(
                  label: l10n.togetherInvite,
                  loading: saving,
                  onPressed: picked.isEmpty
                      ? null
                      : () => context.read<StudyInviteBloc>().add(
                          StudyInviteEvent.submitted(picked),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Duración de cada ronda y cuántas rondas: las opciones y el máximo los manda
/// el servidor (`/together/limits`); hasta que llegan no se enseñan.
class _Options extends StatelessWidget {
  const _Options();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final limits = context.select<FriendPickerBloc, TogetherLimits?>(
      (b) => b.state.limits,
    );
    if (limits == null) return const SizedBox.shrink();
    final lengths = limits.studyRoomLengths;
    final maxRounds = limits.studyRoomRounds;
    return BlocBuilder<StudyInviteBloc, StudyInviteState>(
      builder: (context, state) {
        final bloc = context.read<StudyInviteBloc>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lengths.isNotEmpty)
              AppSegmentedChoice<StudyRoomLength>(
                label: l10n.togetherStudyLength,
                values: [for (final o in lengths) o.length],
                selected: state.length,
                labelOf: (l) {
                  final o = lengths.firstWhere((o) => o.length == l);
                  return l10n.togetherStudyLengthOption(
                    o.focusMinutes,
                    o.breakMinutes,
                  );
                },
                onChanged: (l) {
                  if (l != null) bloc.add(StudyInviteEvent.lengthChosen(l));
                },
              ),
            if (maxRounds > 1) ...[
              const SizedBox(height: TokensSpacing.m),
              AppSegmentedChoice<int>(
                label: l10n.togetherStudyRounds,
                values: [for (var i = 1; i <= maxRounds; i++) i],
                selected: state.rounds.clamp(1, maxRounds),
                labelOf: (n) => '$n',
                onChanged: (n) {
                  if (n != null) bloc.add(StudyInviteEvent.roundsChosen(n));
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
