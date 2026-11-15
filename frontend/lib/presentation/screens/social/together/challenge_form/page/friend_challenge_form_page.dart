import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/di/app_di.dart';
import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../extensions/context_extensions.dart';
import '../../../../../mixins/errors_message_mixin.dart';
import '../../../../../theme/tokens.g.dart';
import '../../../../../widgets/widgets.dart';
import '../../../../challenges/widgets/challenge_labels.dart';
import '../../../social_routes.dart';
import '../../friend_picker/bloc/friend_picker_bloc.dart';
import '../../widgets/together_labels.dart';
import '../../widgets/together_widgets.dart';
import '../bloc/friend_challenge_form_bloc.dart';

/// «Nuevo reto con amigos» (ADR 0044): una plantilla de reto que se cuenta
/// sola, cuántos días, juntos o en competición, y con quién. Una sola acción
/// principal: «Crear reto».
class FriendChallengeFormPage extends StatelessWidget {
  const FriendChallengeFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<FriendChallengeFormBloc>()
                ..add(const FriendChallengeFormEvent.started()),
        ),
        BlocProvider(
          create: (_) => getIt<FriendPickerBloc>()
            ..add(
              const FriendPickerEvent.started(
                kind: TogetherInviteKind.challenge,
              ),
            ),
        ),
      ],
      child: const _FormView(),
    );
  }
}

class _FormView extends StatelessWidget with ErrorsMessageMixin {
  const _FormView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<FriendChallengeFormBloc, FriendChallengeFormState>(
      listenWhen: (p, c) =>
          (c.created != null && c.created != p.created) ||
          (c.saveError != null && c.saveError != p.saveError),
      listener: (context, state) {
        if (state.saveError case final error?) {
          context.showSnack(errorMessage(context, error));
          return;
        }
        context.showSnack(l10n.togetherChallengeCreated);
        context.pushReplacement(
          SocialPaths.togetherChallenge(state.created!.id),
        );
      },
      builder: (context, state) {
        final bloc = context.read<FriendChallengeFormBloc>();
        return Scaffold(
          appBar: AppPageBar.reading(
            leading: const AppBackButton(fallback: SocialPaths.together),
            title: Text(l10n.togetherNewChallenge),
          ),
          body: switch (state.status) {
            FriendChallengeFormStatus.loading => const AppSkeletonList(),
            FriendChallengeFormStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => bloc.add(const FriendChallengeFormEvent.started()),
            ),
            FriendChallengeFormStatus.ready when state.templates.isEmpty =>
              AppEmptyState(
                icon: AppIcons.challenge,
                title: l10n.togetherNoTemplatesTitle,
                message: l10n.togetherNoTemplatesMessage,
              ),
            FriendChallengeFormStatus.ready => _Form(state: state),
          },
          bottomNavigationBar: state.status == FriendChallengeFormStatus.ready
              ? const _CreateBar()
              : null,
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state});

  final FriendChallengeFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<FriendChallengeFormBloc>();
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        AppContentWidth.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(title: l10n.togetherFormWhat),
              RadioGroup<String>(
                groupValue: state.templateId,
                onChanged: (id) {
                  if (id != null) {
                    bloc.add(FriendChallengeFormEvent.templateSelected(id));
                  }
                },
                child: Column(
                  children: [
                    for (final t in state.templates)
                      AppFocusOutline(
                        child: RadioListTile<String>(
                          value: t.id,
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.title),
                          subtitle: Text(t.rule.goalText(context)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppSegmentedChoice<int>(
                label: l10n.togetherFormDays,
                values: FriendChallengeFormBloc.dayOptions,
                selected: state.days,
                labelOf: l10n.togetherDays,
                onChanged: (v) {
                  if (v != null) {
                    bloc.add(FriendChallengeFormEvent.daysChanged(v));
                  }
                },
              ),
              const SizedBox(height: TokensSpacing.m),
              AppAdaptiveChoice<FriendChallengeMode>(
                label: l10n.togetherFormMode,
                values: FriendChallengeMode.values,
                selected: state.mode,
                labelOf: (m) => m.label(context),
                iconOf: (m) => m == FriendChallengeMode.cooperative
                    ? AppIcons.friends
                    : AppIcons.trendUp,
                hintOf: (m) => m == FriendChallengeMode.cooperative
                    ? l10n.togetherModeTogetherHint
                    : l10n.togetherModeCompetitionHint,
                onChanged: (m) =>
                    bloc.add(FriendChallengeFormEvent.modeChanged(m)),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppSectionHeader(title: l10n.togetherFormWho),
              const FriendPickerList(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateBar extends StatelessWidget {
  const _CreateBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final form = context.watch<FriendChallengeFormBloc>().state;
    final picker = context.watch<FriendPickerBloc>().state;
    final picked = picker.selected;
    if (picker.status == FriendPickerStatus.ready && picker.friends.isEmpty) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TokensSpacing.m),
        child: AppPrimaryButton(
          label: l10n.togetherCreateChallenge,
          loading: form.saving,
          onPressed: picked.isEmpty || form.templateId == null
              ? null
              : () => context.read<FriendChallengeFormBloc>().add(
                  FriendChallengeFormEvent.submitted(picked),
                ),
        ),
      ),
    );
  }
}
