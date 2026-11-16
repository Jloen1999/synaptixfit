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
import '../../widgets/study_room_times_picker.dart';
import '../../widgets/together_widgets.dart';
import '../bloc/study_invite_bloc.dart';

/// «Estudiar con amigos» (ADR 0045 y 0053): minutos de cada ronda, cuántas
/// rondas y con quién. Una sola acción principal, «Invitar», que crea la sala y
/// la abre. Desde el Pomodoro llegan su asignatura ([subjectId]) y sus minutos
/// ([times]).
class StudyInvitePage extends StatelessWidget {
  const StudyInvitePage({super.key, this.times, this.subjectId});

  final StudyRoomTimes? times;
  final String? subjectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<StudyInviteBloc>()
            ..add(StudyInviteEvent.started(times: times, subjectId: subjectId)),
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
        appBar: AppPageBar.reading(
          leading: const AppBackButton(fallback: SocialPaths.together),
          title: Text(l10n.togetherStudyWithFriends),
        ),
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

/// Minutos de cada ronda y cuántas rondas: los atajos, los límites y el máximo
/// de rondas los manda el servidor (`/together/limits`); mientras llegan, un
/// esqueleto con su forma (si fallan, la lista de amigos ya dice el error).
class _Options extends StatelessWidget {
  const _Options();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (limits, failed) = context
        .select<FriendPickerBloc, (TogetherLimits?, bool)>(
          (b) => (b.state.limits, b.state.status == FriendPickerStatus.failure),
        );
    // Lo que llega del Pomodoro o de un enlace se acota a los límites del
    // servidor en cuanto se conocen (lo hace el bloc): así nunca se manda algo
    // que no vale.
    return BlocListener<FriendPickerBloc, FriendPickerState>(
      listenWhen: (p, c) => c.limits != null && p.limits != c.limits,
      listener: (context, picker) => context.read<StudyInviteBloc>().add(
        StudyInviteEvent.limitsKnown(picker.limits!),
      ),
      child: limits == null
          ? (failed ? const SizedBox.shrink() : const _OptionsSkeleton())
          : BlocBuilder<StudyInviteBloc, StudyInviteState>(
              builder: (context, state) {
                final bloc = context.read<StudyInviteBloc>();
                final maxRounds = limits.studyRoomRounds;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudyRoomTimesPicker(
                      limits: limits,
                      value: state.times,
                      onChanged: (t) =>
                          bloc.add(StudyInviteEvent.timesChosen(t)),
                    ),
                    if (maxRounds > 1) ...[
                      const SizedBox(height: TokensSpacing.m),
                      AppSegmentedChoice<int>(
                        label: l10n.togetherStudyRounds,
                        values: [for (var i = 1; i <= maxRounds; i++) i],
                        selected: state.rounds,
                        labelOf: (n) => '$n',
                        onChanged: (n) {
                          if (n != null) {
                            bloc.add(StudyInviteEvent.roundsChosen(n));
                          }
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

/// Forma de [_Options] mientras llegan los límites: los atajos y los dos
/// ajustes de minutos.
class _OptionsSkeleton extends StatelessWidget {
  const _OptionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final height = context.scaled(TokensSize.controlHeight);
    // El lector oye «Cargando» una vez (los bloques son mudos).
    return AppSkeletonGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: TokensSpacing.s),
            AppSkeleton(height: height),
          ],
        ],
      ),
    );
  }
}
