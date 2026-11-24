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
  Widget build(BuildContext context) {
    final start = MockExamEvent.started(
      materialId: materialId,
      resume: resume,
      extraMaterialIds: extraMaterialIds,
      questionCount: questionCount,
    );
    return BlocProvider(
      create: (_) => getIt<MockExamBloc>()..add(start),
      child: _MockExamView(
        start: start,
        back: AcademicPaths.practice(materialId),
      ),
    );
  }
}

class _MockExamView extends StatelessWidget with ErrorsMessageMixin {
  const _MockExamView({required this.start, required this.back});

  /// De dónde cuelga la pantalla: a dónde lleva la flecha sin pila.
  final String back;

  /// Cómo se abrió: «Reintentar» lo repite.
  final MockExamEvent start;

  /// Siguiente pregunta sin contestar tras la actual (da la vuelta).
  static int _nextPending(MockExamState state) {
    final qs = state.session?.questions ?? const [];
    for (var i = 1; i <= qs.length; i++) {
      final candidate = (state.index + i) % qs.length;
      if (!qs[candidate].answered) return candidate;
    }
    return state.index;
  }

  /// Antes de entregar con preguntas sin contestar, se explica qué pasará
  /// con ellas (regla del servidor, ADR 0063): sin ninguna respuesta no
  /// cuenta; si no, las que faltan cuentan como «No lo sé».
  Future<void> _confirmFinish(BuildContext context, MockExamState state) async {
    final l10n = context.localizations;
    final bloc = context.read<MockExamBloc>();
    if (!state.allAnswered) {
      // Si contaría lo dice el servidor (`countsIfSubmitted`), no el cliente.
      final none = !(state.session?.countsIfSubmitted ?? true);
      final pending = state.total - state.answered;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            none
                ? l10n.academicExamFinishEmptyTitle
                : l10n.academicExamFinishTitle,
          ),
          content: Text(
            none
                ? l10n.academicExamFinishEmptyMessage
                : '${l10n.academicExamFinishPending(pending)} '
                      '${l10n.academicExamFinishPendingDontKnow(pending)}',
          ),
          // Sin respuestas, lo destacado (y con el foco) es seguir contestando;
          // entregar queda como texto.
          actions: none
              ? [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.academicExamSubmitAnyway),
                  ),
                  FilledButton(
                    autofocus: true,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.academicExamKeepAnswering),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    autofocus: true,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.academicExamSubmit),
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
          a.closedSessionId != b.closedSessionId,
      listener: (context, state) {
        if (state.updatedAccount != null) {
          syncSessionAccount(context, state.updatedAccount!);
        }
        if (state.closedSessionId != null) {
          context.pushReplacement(
            AcademicPaths.testResults(state.closedSessionId!),
          );
        } else if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        }
      },
      builder: (context, state) {
        final bloc = context.read<MockExamBloc>();
        final session = state.session;
        final question = state.current;
        // Salir con la flecha deja el simulacro en curso (no hay «Abandonar»):
        // se dice que sigue y que se retoma al volver a abrirlo.
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop &&
                session != null &&
                state.closedSessionId == null &&
                !state.notCounted) {
              context.showSnack(l10n.academicExamResumeLater);
            }
          },
          child: Scaffold(
            appBar: AppPageBar.reading(
              leading: AppBackButton(fallback: back),
              title: Text(l10n.academicExamTitle),
              actions: [
                if (session != null && !state.notCounted)
                  _ElapsedClock(startedAt: session.startedAt),
              ],
              bottom: session == null || state.notCounted
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(
                        TokensSize.progressBar,
                      ),
                      child: LinearProgressIndicator(
                        minHeight: TokensSize.progressBar,
                        value: state.total == 0
                            ? 0
                            : state.answered / state.total,
                      ),
                    ),
            ),
            bottomNavigationBar: question == null || state.notCounted
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(TokensSpacing.m),
                      // Un solo hueco: tras «No lo sé», «Siguiente» (o
                      // «Entregar» si ya están todas) ocupa el sitio de
                      // «Responder» y se queda con el foco.
                      child: QuestionAnswerBar(
                        questionId: question.id,
                        answered: question.answered,
                        primaryLabel: !question.answered
                            ? l10n.academicExamAnswer
                            : state.allAnswered
                            ? l10n.academicExamSubmit
                            : l10n.academicNext,
                        primaryIcon: question.answered && state.allAnswered
                            ? AppIcons.send
                            : null,
                        busy: question.answered
                            ? state.finishing
                            : state.submitting,
                        onPrimary: !question.answered
                            ? (state.draft.trim().isEmpty
                                  ? null
                                  : () => bloc.add(
                                      const MockExamEvent.answerSubmitted(),
                                    ))
                            : state.allAnswered
                            ? () => _confirmFinish(context, state)
                            : () => bloc.add(
                                MockExamEvent.questionSelected(
                                  _MockExamView._nextPending(state),
                                ),
                              ),
                        onDontKnow: () => bloc.add(
                          const MockExamEvent.dontKnowSubmitted(),
                        ),
                      ),
                    ),
                  ),
            body: switch (state) {
              MockExamState(loading: true) => const AppLoadingView(),
              MockExamState(:final error?) => AppErrorView(
                error: error,
                onRetry: () => bloc.add(start),
              ),
              MockExamState(notCounted: true) => _NotCountedView(back: back),
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
                      // Con «No lo sé» se ve la respuesta al momento; el resto
                      // se corrige al entregar, como en un examen.
                      feedback: question.dontKnow
                          ? QuestionFeedback(
                              correct: false,
                              dontKnow: true,
                              correctAnswer: question.correctAnswer,
                              correctAnswers: question.correctAnswers,
                              explanation: question.explanation,
                            )
                          : null,
                    ),
                    if (question.answered && !question.dontKnow)
                      Padding(
                        padding: const EdgeInsets.only(top: TokensSpacing.m),
                        child: AppPill(
                          label: l10n.academicExamAnswered,
                          color: context.colors.tertiary,
                          icon: Icons.lock_outline_rounded,
                        ),
                      ),
                    // Entregar sin contestarlas todas: aparte, con borde (la
                    // acción principal de abajo es contestar).
                    if (!state.allAnswered) ...[
                      const SizedBox(height: TokensSpacing.xl),
                      AppSecondaryButton(
                        label: l10n.academicExamSubmit,
                        icon: const Icon(AppIcons.send),
                        loading: state.finishing,
                        onPressed: () => _confirmFinish(context, state),
                      ),
                    ],
                  ],
                ),
              ),
            },
          ),
        );
      },
    );
  }
}

/// Entregado sin ninguna respuesta: se dice claramente que no cuenta.
class _NotCountedView extends StatelessWidget {
  const _NotCountedView({required this.back});

  final String back;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Semantics(
      liveRegion: true,
      container: true,
      child: AppEmptyState(
        icon: AppIcons.info,
        title: l10n.academicExamNotCountedTitle,
        message: l10n.academicExamNotCountedMessage,
        action: AppPrimaryButton(
          label: l10n.commonBack,
          onPressed: () => context.popOrGo(back, true),
        ),
      ),
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
          final question = questions[i];
          final answered = question.answered;
          final current = i == state.index;
          final color = answered
              ? context.colors.tertiary
              : context.colors.outline;
          return Semantics(
            label: l10n.academicQuestionOf(i + 1, questions.length),
            // «No lo sé» tiene su propio estado (icono y texto), no «Respondida».
            value: question.dontKnow
                ? l10n.academicStandingDontKnow
                : answered
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
                    color: answered
                        ? color.withValues(alpha: AppPill.tintAlpha)
                        : null,
                    border: Border.all(
                      color: color,
                      width: current
                          ? TokensSize.focusRing
                          : TokensSize.focusRing / 2,
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: question.dontKnow
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${i + 1}',
                                style: context.textStyles.labelSmall?.copyWith(
                                  fontWeight: current
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                              Icon(
                                AppIcons.dontKnow,
                                size: TokensSize.iconXs,
                                color: color,
                              ),
                            ],
                          )
                        : Text(
                            '${i + 1}',
                            style: context.textStyles.labelLarge?.copyWith(
                              fontWeight: current
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
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
              size: TokensSize.iconXs,
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
