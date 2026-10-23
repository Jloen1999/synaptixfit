import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/question_view.dart';
import '../../widgets/result_summary.dart';
import '../bloc/free_practice_bloc.dart';

/// Práctica libre con corrección inmediata y explicación.
class FreePracticePage extends StatelessWidget {
  const FreePracticePage({super.key, required this.materialId});

  final String materialId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<FreePracticeBloc>()..add(FreePracticeEvent.started(materialId)),
    child: const _FreePracticeView(),
  );
}

class _FreePracticeView extends StatelessWidget with ErrorsMessageMixin {
  const _FreePracticeView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<FreePracticeBloc, FreePracticeState>(
      listenWhen: (a, b) =>
          a.actionError != b.actionError ||
          a.updatedAccount != b.updatedAccount,
      listener: (context, state) {
        if (state.updatedAccount != null) {
          syncSessionAccount(context, state.updatedAccount!);
        }
        if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        }
      },
      builder: (context, state) {
        final bloc = context.read<FreePracticeBloc>();
        final question = state.current;
        final checked = state.currentResult;
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(l10n.academicFreePracticeTitle),
            bottom: state.total == 0 || state.result != null
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: LinearProgressIndicator(
                      value: (state.index + 1) / state.total,
                    ),
                  ),
          ),
          bottomNavigationBar: question == null || state.result != null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    child: checked == null
                        ? AppPrimaryButton(
                            label: l10n.academicCheck,
                            loading: state.checking,
                            onPressed: state.draft.trim().isEmpty
                                ? null
                                : () => bloc.add(
                                    const FreePracticeEvent.checked(),
                                  ),
                          )
                        : state.isLast
                        ? AppPrimaryButton(
                            label: l10n.academicFinish,
                            loading: state.finishing,
                            onPressed: () =>
                                bloc.add(const FreePracticeEvent.finished()),
                          )
                        : AppPrimaryButton(
                            label: l10n.academicNext,
                            onPressed: () => bloc.add(
                              const FreePracticeEvent.nextRequested(),
                            ),
                          ),
                  ),
                ),
          body: switch (state) {
            FreePracticeState(loading: true) => const AppLoadingView(),
            FreePracticeState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.pop(),
            ),
            FreePracticeState(:final result?) => AcademicBody(
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.l),
                children: [
                  ResultSummary(
                    title: l10n.academicFreePracticeDone,
                    correct: result.correct,
                    total: result.total,
                    xp: result.xpAwarded,
                  ),
                  const SizedBox(height: TokensSpacing.xl),
                  AppPrimaryButton(
                    label: l10n.commonBack,
                    onPressed: () => context.pop(true),
                  ),
                ],
              ),
            ),
            _ => AcademicBody(
              maxWidth: TokensLayout.readingMaxWidth,
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  QuestionView(
                    key: ValueKey(question!.id),
                    header: l10n.academicQuestionOf(
                      state.index + 1,
                      state.total,
                    ),
                    statement: question.statement,
                    type: question.type,
                    options: question.options,
                    answer: checked == null
                        ? state.draft
                        : state.answers[question.id],
                    onAnswerChanged: (v) =>
                        bloc.add(FreePracticeEvent.answerChanged(v)),
                    feedback: checked == null
                        ? null
                        : QuestionFeedback(
                            correct: checked.correct,
                            correctAnswer:
                                checked.correctAnswer ?? question.correctAnswer,
                            explanation:
                                checked.explanation ?? question.explanation,
                          ),
                  ),
                ],
              ),
            ),
          },
        );
      },
    );
  }
}
