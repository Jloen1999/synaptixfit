import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/di/app_di.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../extensions/context_extensions.dart';
import '../../../../../mixins/errors_message_mixin.dart';
import '../../../../../theme/tokens.g.dart';
import '../../../../../widgets/widgets.dart';
import '../../../social_routes.dart';
import '../../friend_picker/bloc/friend_picker_bloc.dart';
import '../../widgets/together_widgets.dart';
import '../bloc/workout_invite_bloc.dart';

/// «Entrenar con amigos» desde una rutina (ADR 0044): elegir de 1 a 4 amigos e
/// «Invitar». Hoy se hace el siguiente día de la rutina (o el que llega en
/// [dayId]); cada uno entrena en su móvil con su sesión de siempre.
class WorkoutInvitePage extends StatelessWidget {
  const WorkoutInvitePage({super.key, required this.routineId, this.dayId});

  final String routineId;
  final String? dayId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<WorkoutInviteBloc>()),
        BlocProvider(
          create: (_) => getIt<FriendPickerBloc>()
            ..add(
              const FriendPickerEvent.started(kind: TogetherInviteKind.workout),
            ),
        ),
      ],
      child: _InviteView(routineId: routineId, dayId: dayId),
    );
  }
}

class _InviteView extends StatelessWidget with ErrorsMessageMixin {
  const _InviteView({required this.routineId, this.dayId});

  final String routineId;
  final String? dayId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocListener<WorkoutInviteBloc, WorkoutInviteState>(
      listenWhen: (p, c) =>
          (c.created != null && c.created != p.created) ||
          (c.error != null && c.error != p.error),
      listener: (context, state) {
        if (state.error case final error?) {
          context.showSnack(errorMessage(context, error));
          return;
        }
        context.showSnack(l10n.togetherWorkoutInvited);
        context.pushReplacement(SocialPaths.togetherWorkout(state.created!.id));
      },
      child: Scaffold(
        appBar: AppPageBar.reading(title: Text(l10n.togetherTrainWithFriends)),
        body: ListView(
          padding: const EdgeInsets.all(TokensSpacing.m),
          children: [
            AppContentWidth.reading(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHelpToggle(
                    help: l10n.togetherWorkoutHelp,
                    tooltip: l10n.commonHelpAbout(
                      l10n.togetherTrainWithFriends,
                    ),
                    child: Text(
                      l10n.togetherWorkoutIntro,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
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
                final saving = context.watch<WorkoutInviteBloc>().state.saving;
                final picked = context.watch<FriendPickerBloc>().state.selected;
                return AppPrimaryButton(
                  label: l10n.togetherInvite,
                  loading: saving,
                  onPressed: picked.isEmpty
                      ? null
                      : () => context.read<WorkoutInviteBloc>().add(
                          WorkoutInviteEvent.submitted(
                            routineId: routineId,
                            dayId: dayId,
                            friendIds: picked,
                          ),
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
