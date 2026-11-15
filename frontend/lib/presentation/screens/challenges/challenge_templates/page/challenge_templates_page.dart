import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/challenges/challenge_template.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../challenges_routes.dart';
import '../../widgets/challenge_content_width.dart';
import '../../widgets/challenge_labels.dart';
import '../bloc/challenge_templates_bloc.dart';

/// Progreso › Retos › Plantillas (ADR 0043): retos productivos que el servidor
/// cuenta solo con lo que ya se hace en la app. «Empezar este reto» crea uno
/// propio con un toque y lo abre.
class ChallengeTemplatesPage extends StatelessWidget {
  const ChallengeTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ChallengeTemplatesBloc>()
            ..add(const ChallengeTemplatesEvent.started()),
      child: const _TemplatesView(),
    );
  }
}

class _TemplatesView extends StatelessWidget with ErrorsMessageMixin {
  const _TemplatesView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ChallengeTemplatesBloc, ChallengeTemplatesState>(
      listenWhen: (p, c) =>
          (c.started != null && p.started != c.started) ||
          (c.startError != null && p.startError != c.startError),
      listener: (context, state) {
        if (state.startError case final error?) {
          context.showSnack(errorMessage(context, error));
          return;
        }
        final challenge = state.started!;
        context.showSnack(l10n.challengesTemplatesStarted(challenge.title));
        // El detalle es otra pantalla completa: sustituye a la galería.
        context.pushReplacement(ChallengesPaths.detail(challenge.id));
      },
      builder: (context, state) {
        final bloc = context.read<ChallengeTemplatesBloc>();
        return Scaffold(
          appBar: AppPageBar(
            leading: const AppBackButton(fallback: ChallengesPaths.list),
            title: Text(l10n.challengesTemplatesTitle),
          ),
          body: switch (state.status) {
            ChallengeTemplatesStatus.loading => const AppSkeletonList(),
            ChallengeTemplatesStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => bloc.add(const ChallengeTemplatesEvent.started()),
            ),
            ChallengeTemplatesStatus.ready => ListView(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                TokensSpacing.s,
                TokensSpacing.m,
                TokensSpacing.xxl,
              ),
              children: [
                ChallengeContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHelpToggle(
                        help: l10n.challengesTemplatesHelp,
                        tooltip: l10n.commonHelpAbout(
                          l10n.challengesTemplatesTitle,
                        ),
                        child: Text(
                          l10n.challengesTemplatesIntro,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      if (state.templates.isEmpty)
                        AppEmptyState.compact(
                          icon: Icons.flag_outlined,
                          title: l10n.challengesTemplatesEmpty,
                          message: l10n.challengesTemplatesEmptyHint,
                          action: AppSecondaryButton(
                            label: l10n.challengesNew,
                            icon: const Icon(AppIcons.add),
                            onPressed: () =>
                                context.pushReplacement(ChallengesPaths.create),
                          ),
                        )
                      else
                        for (final t in state.templates)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensSpacing.s,
                            ),
                            child: _TemplateCard(
                              template: t,
                              busy: state.startingId == t.id,
                              disabled: state.startingId != null,
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.busy,
    required this.disabled,
  });

  final ChallengeTemplate template;
  final bool busy;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final t = template;
    final accent = t.type.color(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(t.type.icon, color: accent),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(t.title, style: context.textStyles.titleMedium),
              ),
            ],
          ),
          if (t.goal.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(t.goal, style: context.textStyles.bodyMedium),
          ],
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              AppPill(
                icon: Icons.flag_outlined,
                label: l10n.challengesTemplatesGoal(t.rule.goalText(context)),
                color: accent,
              ),
              AppPill(
                icon: AppIcons.calendar,
                label: l10n.challengesTemplatesLasts(t.days),
              ),
              if (t.rule.privateOnly)
                AppPill(
                  icon: AppIcons.readOnly,
                  label: l10n.challengesTemplatesPrivate,
                ),
              if (t.running)
                AppPill(
                  icon: Icons.play_circle_outline_rounded,
                  label: l10n.challengesTemplatesRunning,
                  color: context.palette.success,
                ),
            ],
          ),
          if (!t.running) ...[
            const SizedBox(height: TokensSpacing.m),
            Semantics(
              label: l10n.challengesTemplatesStartNamed(t.title),
              excludeSemantics: true,
              button: true,
              enabled: !disabled,
              onTap: disabled
                  ? null
                  : () => context.read<ChallengeTemplatesBloc>().add(
                      ChallengeTemplatesEvent.startRequested(t.id),
                    ),
              child: AppSecondaryButton(
                label: l10n.challengesTemplatesStart,
                icon: const Icon(Icons.play_arrow_rounded),
                loading: busy,
                onPressed: disabled
                    ? null
                    : () => context.read<ChallengeTemplatesBloc>().add(
                        ChallengeTemplatesEvent.startRequested(t.id),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
