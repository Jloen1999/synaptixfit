import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/test_session_status.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/practice_hub_bloc.dart';

/// Práctica y tests de un material.
class PracticeHubPage extends StatelessWidget {
  const PracticeHubPage({super.key, required this.materialId});

  final String materialId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<PracticeHubBloc>()..add(PracticeHubEvent.started(materialId)),
    child: const _PracticeHubView(),
  );
}

class _PracticeHubView extends StatelessWidget with ErrorsMessageMixin {
  const _PracticeHubView();

  Future<void> _open(BuildContext context, String location) async {
    final bloc = context.read<PracticeHubBloc>();
    await context.push<Object?>(location);
    bloc.add(const PracticeHubEvent.refreshed());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<PracticeHubBloc, PracticeHubState>(
      listenWhen: (a, b) =>
          a.actionError != b.actionError && b.actionError != null,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.actionError!)),
      builder: (context, state) {
        return Scaffold(
          appBar: AppPageBar(
            title: Text(state.material?.title ?? l10n.academicPracticeTitle),
          ),
          body: switch (state) {
            PracticeHubState(loading: true) => const AppSkeletonList(
              height: 96,
            ),
            PracticeHubState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.read<PracticeHubBloc>().add(
                PracticeHubEvent.started(state.materialId),
              ),
            ),
            PracticeHubState(bank: null) => _NoBank(
              generating: state.generating,
            ),
            _ => RefreshIndicator(
              onRefresh: () async => context.read<PracticeHubBloc>().add(
                const PracticeHubEvent.refreshed(),
              ),
              child: AcademicBody(
                child: ListView(
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  children: [
                    _BankStats(bank: state.bank!),
                    const SizedBox(height: TokensSpacing.l),
                    if (state.activeSession != null)
                      _ModeCard(
                        icon: Icons.play_circle_outline_rounded,
                        color: context.palette.accent,
                        title: l10n.academicExamResume,
                        subtitle: l10n.academicExamProgress(
                          state.activeSession!.answeredCount,
                          state.activeSession!.totalQuestions,
                        ),
                        onTap: () => _open(
                          context,
                          AcademicPaths.exam(state.materialId, resume: true),
                        ),
                      ),
                    _ModeCard(
                      icon: Icons.quiz_outlined,
                      color: context.colors.tertiary,
                      title: l10n.academicFreePracticeTitle,
                      subtitle: l10n.academicFreePracticeHint,
                      onTap: () => _open(
                        context,
                        AcademicPaths.freePractice(state.materialId),
                      ),
                    ),
                    _ModeCard(
                      icon: Icons.style_outlined,
                      color: context.palette.study,
                      title: l10n.academicFlashcardsTitle,
                      subtitle: l10n.academicFlashcardsHint,
                      onTap: () => _open(
                        context,
                        AcademicPaths.flashcards(state.materialId),
                      ),
                    ),
                    _ModeCard(
                      icon: Icons.timer_outlined,
                      color: context.palette.sessions,
                      title: l10n.academicExamTitle,
                      subtitle: l10n.academicExamHint,
                      onTap: () =>
                          _open(context, AcademicPaths.exam(state.materialId)),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: state.generating
                            ? null
                            : () => context.read<PracticeHubBloc>().add(
                                const PracticeHubEvent.bankRequested(),
                              ),
                        icon: state.generating
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(l10n.academicPracticeRegenerate),
                      ),
                    ),
                    if (state.sessions.isNotEmpty) ...[
                      const SizedBox(height: TokensSpacing.m),
                      AppSectionHeader(title: l10n.academicExamHistory),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final s in state.sessions)
                              _SessionTile(
                                session: s,
                                onTap: s.status == TestSessionStatus.inProgress
                                    ? () => _open(
                                        context,
                                        AcademicPaths.exam(
                                          state.materialId,
                                          resume: true,
                                        ),
                                      )
                                    : () => _open(
                                        context,
                                        AcademicPaths.testResults(s.id),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: TokensSpacing.xl),
                  ],
                ),
              ),
            ),
          },
        );
      },
    );
  }
}

class _NoBank extends StatelessWidget {
  const _NoBank({required this.generating});

  final bool generating;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppEmptyState(
      icon: Icons.quiz_outlined,
      title: l10n.academicPracticeNoBankTitle,
      message: generating
          ? l10n.academicAiGenerating
          : l10n.academicPracticeNoBankMessage,
      action: AppPrimaryButton(
        label: l10n.academicPracticeGenerate,
        icon: Icons.auto_awesome_rounded,
        loading: generating,
        onPressed: () => context.read<PracticeHubBloc>().add(
          const PracticeHubEvent.bankRequested(),
        ),
      ),
    );
  }
}

class _BankStats extends StatelessWidget {
  const _BankStats({required this.bank});

  final QuestionBank bank;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Row(
      children: [
        Expanded(
          child: AppMetricTile(
            icon: Icons.help_outline_rounded,
            color: context.colors.tertiary,
            value: '${bank.questions.length}',
            label: l10n.academicPracticeQuestions,
          ),
        ),
        const SizedBox(width: TokensSpacing.s),
        Expanded(
          child: AppMetricTile(
            icon: Icons.edit_note_rounded,
            color: context.palette.sessions,
            value: '${bank.attemptedQuestions}',
            label: l10n.academicPracticeAttempted,
          ),
        ),
        const SizedBox(width: TokensSpacing.s),
        Expanded(
          child: AppMetricTile(
            icon: Icons.check_circle_outline_rounded,
            color: context.palette.success,
            value: '${bank.correctQuestions}',
            label: l10n.academicPracticeCorrect,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TokensSpacing.s),
    child: AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TokensSpacing.s),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(TokensRadius.m),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall),
                Text(subtitle, style: context.textStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onTap});

  final TestSessionSummary session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (label, color) = switch (session.status) {
      TestSessionStatus.inProgress => (
        l10n.academicExamStatusInProgress,
        context.palette.accent,
      ),
      TestSessionStatus.completed => (
        l10n.academicExamStatusCompleted,
        context.palette.success,
      ),
      TestSessionStatus.abandoned => (
        l10n.academicExamStatusAbandoned,
        context.colors.onSurfaceVariant,
      ),
    };
    return AppFocusOutline(
      child: ListTile(
        onTap: onTap,
        title: Text(
          l10n.academicExamScore(session.score, session.totalQuestions),
        ),
        subtitle: Text(dateTime(session.startedAt)),
        trailing: AppPill(label: label, color: color),
      ),
    );
  }
}
