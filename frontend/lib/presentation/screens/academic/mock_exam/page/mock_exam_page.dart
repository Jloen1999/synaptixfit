import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/question_view.dart';
import '../bloc/mock_exam_bloc.dart';

/// Simulacro cronometrado con sesión persistente. Con [extraMaterialIds] es un
/// simulacro de asignatura que mezcla preguntas de varios apuntes y archivos.
class MockExamPage extends StatelessWidget {
  const MockExamPage({
    super.key,
    required this.materialId,
    this.resume = false,
    this.extraMaterialIds = const [],
    this.questionCount,
  });

  final String materialId;
  final bool resume;
  final List<String> extraMaterialIds;
  final int? questionCount;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<MockExamBloc>()
      ..add(
        MockExamEvent.started(
          materialId: materialId,
          resume: resume,
          extraMaterialIds: extraMaterialIds,
          questionCount: questionCount,
        ),
      ),
    child: const _MockExamView(),
  );
}

class _MockExamView extends StatelessWidget with ErrorsMessageMixin {
  const _MockExamView();

  Future<void> _confirmAbandon(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<MockExamBloc>();
    final ok = await confirmDestructive(
      context,
      title: l10n.academicExamAbandonTitle,
      message: l10n.academicExamAbandonMessage,
      confirmLabel: l10n.academicExamAbandon,
    );
    if (ok) bloc.add(const MockExamEvent.abandoned());
  }

  Future<void> _confirmFinish(BuildContext context, MockExamState state) async {
    final l10n = context.localizations;
    final bloc = context.read<MockExamBloc>();
    if (!state.allAnswered) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.academicExamFinishTitle),
          content: Text(
            l10n.academicExamFinishPending(state.total - state.answered),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.academicFinish),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }
    bloc.add(const MockExamEvent.completed());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<MockExamBloc, MockExamState>(
      listenWhen: (a, b) =>
          a.actionError != b.actionError ||
          a.closedSessionId != b.closedSessionId ||
          a.abandoned != b.abandoned,
      listener: (context, state) {
        if (state.updatedAccount != null) {
          syncSessionAccount(context, state.updatedAccount!);
        }
        if (state.closedSessionId != null) {
          context.pushReplacement(
            AcademicPaths.testResults(state.closedSessionId!),
          );
        } else if (state.abandoned) {
          context.showSnack(l10n.academicExamAbandoned);
          context.pop(true);
        } else if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        }
      },
      builder: (context, state) {
        final bloc = context.read<MockExamBloc>();
        final session = state.session;
        final question = state.current;
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(l10n.academicExamTitle),
            actions: [
              if (session != null) _ElapsedClock(startedAt: session.startedAt),
              if (session != null)
                IconButton(
                  tooltip: l10n.academicExamAbandon,
                  icon: const Icon(AppIcons.close),
                  onPressed: state.finishing
                      ? null
                      : () => _confirmAbandon(context),
                ),
            ],
            bottom: session == null
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: LinearProgressIndicator(
                      value: state.total == 0
                          ? 0
                          : state.answered / state.total,
                    ),
                  ),
          ),
          bottomNavigationBar: question == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            label: l10n.academicFinish,
                            onPressed: state.finishing
                                ? null
                                : () => _confirmFinish(context, state),
                          ),
                        ),
                        const SizedBox(width: TokensSpacing.s),
                        Expanded(
                          child: question.answered
                              ? AppPrimaryButton(
                                  label: l10n.academicNext,
                                  onPressed: state.allAnswered
                                      ? null
                                      : () => bloc.add(
                                          MockExamEvent.questionSelected(
                                            (state.index + 1) % state.total,
                                          ),
                                        ),
                                )
                              : AppPrimaryButton(
                                  label: l10n.academicExamAnswer,
                                  loading: state.submitting,
                                  onPressed: state.draft.trim().isEmpty
                                      ? null
                                      : () => bloc.add(
                                          const MockExamEvent.answerSubmitted(),
                                        ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
          body: switch (state) {
            MockExamState(loading: true) => const AppLoadingView(),
            MockExamState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.pop(),
            ),
            _ when question == null => AppEmptyState(
              icon: Icons.quiz_outlined,
              title: l10n.academicPracticeNoBankTitle,
            ),
            _ => AcademicBody(
              maxWidth: TokensLayout.readingMaxWidth,
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  if (state.finishing) const LinearProgressIndicator(),
                  _QuestionNavigator(state: state),
                  const SizedBox(height: TokensSpacing.m),
                  QuestionView(
                    key: ValueKey(question.id),
                    header: l10n.academicQuestionOf(
                      state.index + 1,
                      state.total,
                    ),
                    statement: question.statement,
                    type: question.type,
                    options: question.options,
                    answer: question.answered ? question.answer : state.draft,
                    onAnswerChanged: question.answered
                        ? (_) {}
                        : (v) => bloc.add(MockExamEvent.answerChanged(v)),
                  ),
                  if (question.answered)
                    Padding(
                      padding: const EdgeInsets.only(top: TokensSpacing.m),
                      child: AppPill(
                        label: l10n.academicExamAnswered,
                        color: context.colors.tertiary,
                        icon: Icons.lock_outline_rounded,
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

class _QuestionNavigator extends StatelessWidget {
  const _QuestionNavigator({required this.state});

  final MockExamState state;

  @override
  Widget build(BuildContext context) {
    final questions = state.session?.questions ?? const [];
    final l10n = context.localizations;
    return SizedBox(
      height: context.scaled(TokensLayout.minTouchTarget),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        separatorBuilder: (_, _) => const SizedBox(width: TokensSpacing.xs),
        itemBuilder: (context, i) {
          final answered = questions[i].answered;
          final current = i == state.index;
          final color = answered
              ? context.colors.tertiary
              : context.colors.outline;
          return Semantics(
            label: l10n.academicQuestionOf(i + 1, questions.length),
            value: answered
                ? l10n.academicQuestionAnswered
                : l10n.academicQuestionPending,
            selected: current,
            child: AppFocusOutline(
              borderRadius: BorderRadius.circular(TokensRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(TokensRadius.pill),
                onTap: () => context.read<MockExamBloc>().add(
                  MockExamEvent.questionSelected(i),
                ),
                child: Container(
                  width: context.scaled(TokensLayout.minTouchTarget),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: answered ? color.withValues(alpha: 0.16) : null,
                    border: Border.all(color: color, width: current ? 2.5 : 1),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: context.textStyles.labelLarge?.copyWith(
                      fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Cronómetro en cliente desde el inicio de la sesión.
class _ElapsedClock extends StatefulWidget {
  const _ElapsedClock({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final safe = elapsed.isNegative ? Duration.zero : elapsed;
    final h = safe.inHours;
    final m = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = h > 0 ? '$h:$m:$s' : '$m:$s';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.s),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: TokensSpacing.xs),
            Text(
              text,
              semanticsLabel: context.localizations.academicExamElapsed(text),
              style: context.textStyles.labelLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
