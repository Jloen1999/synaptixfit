import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/result_summary.dart';
import '../bloc/test_results_bloc.dart';

/// Resultados de un simulacro: nota, XP y revisión de cada pregunta.
class TestResultsPage extends StatelessWidget {
  const TestResultsPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<TestResultsBloc>()..add(TestResultsEvent.started(sessionId)),
    child: const _TestResultsView(),
  );
}

class _TestResultsView extends StatelessWidget {
  const _TestResultsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar(title: Text(l10n.academicExamResultsTitle)),
      body: BlocBuilder<TestResultsBloc, TestResultsState>(
        builder: (context, state) {
          if (state.loading) return const AppLoadingView();
          if (state.error != null) {
            return AppErrorView(
              error: state.error!,
              onRetry: () => context.read<TestResultsBloc>().add(
                TestResultsEvent.started(state.sessionId),
              ),
            );
          }
          final session = state.session!;
          final duration = session.completedAt?.difference(session.startedAt);
          return AcademicBody(
            child: ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                const SizedBox(height: TokensSpacing.s),
                ResultSummary(
                  title: l10n.academicExamScore(
                    session.score,
                    session.totalQuestions,
                  ),
                  correct: session.score,
                  total: session.totalQuestions,
                  xp: session.xpGranted,
                  extra: duration == null
                      ? null
                      : Text(
                          l10n.academicExamDuration(
                            duration.inMinutes,
                            duration.inSeconds.remainder(60),
                          ),
                          style: context.textStyles.bodyMedium,
                        ),
                ),
                const SizedBox(height: TokensSpacing.l),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: l10n.academicExamRetry,
                        icon: const Icon(Icons.replay_rounded),
                        onPressed: () => context.pushReplacement(
                          AcademicPaths.exam(session.materialId),
                        ),
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    Expanded(
                      child: AppPrimaryButton(
                        label: l10n.commonBack,
                        onPressed: () => context.pop(true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(title: l10n.academicExamReview),
                for (final (i, q) in session.questions.indexed)
                  _ReviewItem(index: i, question: q),
                const SizedBox(height: TokensSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.index, required this.question});

  final int index;
  final SessionQuestion question;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final correct = question.correct ?? false;
    final color = !question.answered
        ? context.colors.outline
        : correct
        ? context.palette.success
        : context.colors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  !question.answered
                      ? Icons.remove_circle_outline_rounded
                      : correct
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color,
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(
                    '${index + 1}. ${question.statement}',
                    style: context.textStyles.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              question.answered
                  ? l10n.academicYourAnswer(question.answer ?? '')
                  : l10n.academicNotAnswered,
            ),
            if (!correct && question.correctAnswer != null)
              Text(l10n.academicCorrectAnswer(question.correctAnswer!)),
            if (question.explanation != null &&
                question.explanation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xs),
                child: Text(
                  question.explanation!,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: TokensSpacing.xs),
            AppPill(
              label: context.questionTypeLabel(question.type),
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
