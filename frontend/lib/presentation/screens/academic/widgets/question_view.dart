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
    this.explanation,
  });

  final bool correct;
  final String? correctAnswer;
  final String? explanation;
}

/// Enunciado y respuesta de una pregunta (opción múltiple o respuesta corta).
/// Con [feedback] se bloquea y muestra la corrección.
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
    final isChoice =
        widget.type == QuestionType.multipleChoice && widget.options.isNotEmpty;
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
          context.questionTypeLabel(widget.type),
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        if (isChoice)
          for (final option in widget.options)
            _OptionTile(
              label: option,
              selected: widget.answer == option,
              state: !locked
                  ? _OptionState.idle
                  : option == feedback.correctAnswer
                  ? _OptionState.correct
                  : widget.answer == option
                  ? _OptionState.wrong
                  : _OptionState.idle,
              onTap: locked ? null : () => widget.onAnswerChanged(option),
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
                    .withValues(alpha: 0.12),
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
                if (!feedback.correct && feedback.correctAnswer != null) ...[
                  const SizedBox(height: TokensSpacing.xs),
                  Text(l10n.academicCorrectAnswer(feedback.correctAnswer!)),
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
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String label;
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
      _OptionState.idle =>
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: Material(
        color: selected || state != _OptionState.idle
            ? color.withValues(alpha: 0.1)
            : context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          side: BorderSide(color: color),
        ),
        child: AppFocusOutline(
          borderRadius: BorderRadius.circular(TokensRadius.m),
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
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: TokensSpacing.m),
                    Expanded(child: Text(label)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
