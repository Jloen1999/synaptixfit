import 'package:flutter/material.dart';

import '../../../../domain/enums/question_type.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'academic_visuals.dart';

/// Corrección mostrada bajo una pregunta.
class QuestionFeedback {
  const QuestionFeedback({
    required this.correct,
    this.correctAnswer,
    this.correctAnswers = const [],
    this.explanation,
  });

  final bool correct;
  final String? correctAnswer;

  /// Todas las correctas («Varias correctas»); si va vacía, [correctAnswer].
  final List<String> correctAnswers;
  final String? explanation;

  List<String> get answers =>
      correctAnswers.isNotEmpty ? correctAnswers : [?correctAnswer];
}

/// Enunciado y respuesta de una pregunta (elegir una, varias correctas o
/// respuesta corta). En «Varias correctas» la respuesta son las opciones
/// marcadas unidas con [QuestionAnswers.join]. Con [feedback] se bloquea y
/// muestra la corrección.
class QuestionView extends StatefulWidget {
  const QuestionView({
    super.key,
    required this.statement,
    required this.type,
    required this.options,
    required this.answer,
    required this.onAnswerChanged,
    this.feedback,
    this.header,
  });

  final String statement;
  final QuestionType type;
  final List<String> options;
  final String? answer;
  final ValueChanged<String> onAnswerChanged;
  final QuestionFeedback? feedback;
  final String? header;

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.answer ?? '',
  );

  @override
  void didUpdateWidget(QuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statement != widget.statement) {
      _controller.text = widget.answer ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final locked = feedback != null;
    final l10n = context.localizations;
    final isChoice = widget.type.hasOptions && widget.options.isNotEmpty;
    final multiple = widget.type == QuestionType.multipleAnswer;
    final chosen = multiple
        ? QuestionAnswers.split(widget.answer).toSet()
        : {?widget.answer};
    final correctOnes = feedback?.answers.toSet() ?? const <String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header != null)
          Text(
            widget.header!,
            style: context.textStyles.labelLarge?.copyWith(
              color: context.colors.tertiary,
            ),
          ),
        const SizedBox(height: TokensSpacing.xs),
        Text(widget.statement, style: context.textStyles.titleLarge),
        const SizedBox(height: TokensSpacing.xs),
        Text(
          multiple
              ? l10n.academicChooseAllCorrect
              : context.questionTypeLabel(
                  widget.type,
                  statement: widget.statement,
                ),
          // «Elige todas las correctas» es lo que distingue el tipo: resaltado.
          style: multiple
              ? context.textStyles.labelLarge?.copyWith(
                  color: context.colors.tertiary,
                )
              : context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
        ),
        const SizedBox(height: TokensSpacing.m),
        if (isChoice)
          for (final option in widget.options)
            _OptionTile(
              label: option,
              multiple: multiple,
              selected: chosen.contains(option),
              state: !locked
                  ? _OptionState.idle
                  : correctOnes.contains(option)
                  ? _OptionState.correct
                  : chosen.contains(option)
                  ? _OptionState.wrong
                  : _OptionState.idle,
              onTap: locked
                  ? null
                  : () => widget.onAnswerChanged(
                      multiple
                          ? QuestionAnswers.join(
                              widget.options.where(
                                (o) => o == option
                                    ? !chosen.contains(o)
                                    : chosen.contains(o),
                              ),
                            )
                          : option,
                    ),
            )
        else
          TextField(
            controller: _controller,
            enabled: !locked,
            onChanged: widget.onAnswerChanged,
            decoration: InputDecoration(labelText: l10n.academicAnswerLabel),
          ),
        if (feedback != null) ...[
          const SizedBox(height: TokensSpacing.m),
          AppCard(
            color:
                (feedback.correct
                        ? context.palette.success
                        : context.colors.error)
                    .withValues(alpha: AppPill.tintAlpha),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      feedback.correct
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: feedback.correct
                          ? context.palette.success
                          : context.colors.error,
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    Text(
                      feedback.correct
                          ? l10n.academicAnswerCorrect
                          : l10n.academicAnswerWrong,
                      style: context.textStyles.titleSmall,
                    ),
                  ],
                ),
                if (!feedback.correct && feedback.answers.isNotEmpty) ...[
                  const SizedBox(height: TokensSpacing.xs),
                  Text(
                    l10n.academicCorrectAnswer(feedback.answers.join(' · ')),
                  ),
                ],
                if (feedback.explanation != null &&
                    feedback.explanation!.isNotEmpty) ...[
                  const SizedBox(height: TokensSpacing.xs),
                  Text(
                    feedback.explanation!,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.multiple,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String label;

  /// Casilla («Varias correctas») en vez de botón de opción.
  final bool multiple;
  final bool selected;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OptionState.correct => context.palette.success,
      _OptionState.wrong => context.colors.error,
      _OptionState.idle =>
        selected ? context.colors.tertiary : context.colors.outlineVariant,
    };
    final icon = switch (state) {
      _OptionState.correct => Icons.check_circle_rounded,
      _OptionState.wrong => Icons.cancel_rounded,
      _OptionState.idle when multiple =>
        selected
            ? Icons.check_box_rounded
            : Icons.check_box_outline_blank_rounded,
      _OptionState.idle =>
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: Material(
        color: selected || state != _OptionState.idle
            ? color.withValues(alpha: AppPill.tintAlpha)
            : context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          side: BorderSide(color: color),
        ),
        child: AppFocusOutline(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: Semantics(
            checked: selected,
            inMutuallyExclusiveGroup: !multiple,
            child: InkWell(
              borderRadius: BorderRadius.circular(TokensRadius.m),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: TokensLayout.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensSpacing.m,
                    vertical: TokensSpacing.s,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        // Sin marcar, el icono con contraste suficiente (WCAG
                        // 1.4.11): su forma distingue casilla de círculo.
                        color: state == _OptionState.idle && !selected
                            ? context.colors.outline
                            : color,
                        size: TokensSize.iconS,
                      ),
                      const SizedBox(width: TokensSpacing.m),
                      Expanded(child: Text(label)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
