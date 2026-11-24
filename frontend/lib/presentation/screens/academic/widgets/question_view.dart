import 'package:flutter/material.dart';

import '../../../../domain/enums/question_type.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import 'academic_visuals.dart';

/// Corrección mostrada bajo una pregunta. [dontKnow]: se contestó «No lo sé»
/// (ADR 0063): se enseña la respuesta y que volverá antes.
class QuestionFeedback {
  const QuestionFeedback({
    required this.correct,
    this.correctAnswer,
    this.correctAnswers = const [],
    this.explanation,
    this.dontKnow = false,
  });

  final bool correct;
  final bool dontKnow;
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
          _FeedbackCard(feedback: feedback),
        ],
      ],
    );
  }
}

/// Corrección: acierto, fallo o «No lo sé», siempre con icono y texto (el
/// color nunca va solo). Se anuncia al aparecer.
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final QuestionFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (color, icon, title) = feedback.dontKnow
        ? (context.colors.tertiary, AppIcons.dontKnow, l10n.academicDontKnowTitle)
        : feedback.correct
        ? (
            context.palette.success,
            Icons.check_circle_rounded,
            l10n.academicAnswerCorrect,
          )
        : (context.colors.error, Icons.cancel_rounded, l10n.academicAnswerWrong);
    return Semantics(
      liveRegion: true,
      container: true,
      child: AppCard(
        color: color.withValues(alpha: AppPill.tintAlpha),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(title, style: context.textStyles.titleSmall),
                ),
              ],
            ),
            if (!feedback.correct && feedback.answers.isNotEmpty) ...[
              const SizedBox(height: TokensSpacing.xs),
              Text(l10n.academicCorrectAnswer(feedback.answers.join(' · '))),
            ],
            if (feedback.dontKnow) ...[
              const SizedBox(height: TokensSpacing.xs),
              Text(l10n.academicDontKnowComesBack),
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
    );
  }
}

/// Acciones de una pregunta: sin contestar, «No lo sé» (con borde) y la
/// principal («Comprobar», «Responder»), en fila si las dos etiquetas caben
/// enteras en su mitad (se mide el ancho real, WCAG 1.4.10) y, si no, una
/// encima de otra, la principal arriba. Ya corregida ([answered]), solo la
/// acción siguiente («Siguiente», «Terminar», «Entregar») en el mismo hueco:
/// si el foco estaba en la barra, pasa a ella y no se pierde al contestar
/// (WCAG 2.4.3).
class QuestionAnswerBar extends StatefulWidget {
  const QuestionAnswerBar({
    super.key,
    required this.questionId,
    required this.primaryLabel,
    required this.onPrimary,
    this.onDontKnow,
    this.busy = false,
    this.answered = false,
    this.primaryIcon,
    this.outlined = false,
  });

  /// Pregunta a la que pertenece: al corregirse esa misma, el foco pasa a la
  /// acción siguiente; al cambiar de pregunta, solo si estaba en la barra.
  final String questionId;
  final String primaryLabel;

  /// Nula mientras no hay respuesta que mandar (botón desactivado).
  final VoidCallback? onPrimary;
  final VoidCallback? onDontKnow;

  /// Se está mandando la respuesta: los dos quedan quietos y la principal
  /// anuncia la carga.
  final bool busy;

  /// La pregunta ya está corregida: sin «No lo sé».
  final bool answered;
  final IconData? primaryIcon;

  /// La acción va con borde (p. ej. «Volver a la lista», que no es la
  /// principal de la pantalla).
  final bool outlined;

  @override
  State<QuestionAnswerBar> createState() => _QuestionAnswerBarState();
}

class _QuestionAnswerBarState extends State<QuestionAnswerBar> {
  final _primaryFocus = FocusNode(debugLabel: 'QuestionAnswerBar.primary');
  final _dontKnowFocus = FocusNode(debugLabel: 'QuestionAnswerBar.dontKnow');

  /// El foco estaba en la barra: al cambiar de botón se le devuelve. Mientras
  /// se manda la respuesta el botón queda desactivado y lo suelta; no cuenta.
  bool _restore = false;

  @override
  void didUpdateWidget(QuestionAnswerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busy) return;
    // Recién corregida (siempre la ha contestado la persona): el foco pasa a la
    // acción siguiente. En otro cambio, solo si estaba en la barra.
    final justAnswered =
        oldWidget.questionId == widget.questionId &&
        !oldWidget.answered &&
        widget.answered;
    final changed =
        oldWidget.questionId != widget.questionId ||
        oldWidget.answered != widget.answered ||
        oldWidget.primaryLabel != widget.primaryLabel ||
        oldWidget.busy;
    if (!justAnswered && !(_restore && changed)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Sin contestar, «Comprobar» suele estar desactivado (no hay respuesta):
      // el foco va a «No lo sé».
      final target = widget.answered || widget.onPrimary != null
          ? _primaryFocus
          : _dontKnowFocus;
      target.requestFocus();
    });
  }

  @override
  void dispose() {
    _primaryFocus.dispose();
    _dontKnowFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final primary = widget.outlined
        ? AppSecondaryButton(
            label: widget.primaryLabel,
            icon: widget.primaryIcon == null ? null : Icon(widget.primaryIcon),
            loading: widget.busy,
            focusNode: _primaryFocus,
            onPressed: widget.onPrimary,
          )
        : AppPrimaryButton(
            label: widget.primaryLabel,
            icon: widget.primaryIcon,
            loading: widget.busy,
            focusNode: _primaryFocus,
            onPressed: widget.onPrimary,
          );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (has) {
        if (has) {
          _restore = true;
        } else if (!widget.busy) {
          _restore = false;
        }
      },
      child: widget.answered
          ? SizedBox(width: double.infinity, child: primary)
          : _withDontKnow(context, l10n, primary),
    );
  }

  Widget _withDontKnow(
    BuildContext context,
    AppLocalizations l10n,
    Widget primary,
  ) {
    final dontKnow = AppSecondaryButton(
      label: l10n.academicDontKnow,
      icon: const Icon(AppIcons.dontKnow),
      focusNode: _dontKnowFocus,
      onPressed: widget.busy ? null : widget.onDontKnow,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = (constraints.maxWidth - TokensSpacing.s) / 2;
        final fits =
            context.buttonWidth(
                  l10n.academicDontKnow,
                  OutlinedButtonTheme.of(context).style,
                  icon: true,
                ) <=
                half &&
            context.buttonWidth(
                  widget.primaryLabel,
                  FilledButtonTheme.of(context).style,
                  icon: widget.primaryIcon != null,
                ) <=
                half;
        if (fits) {
          return Row(
            children: [
              Expanded(child: dontKnow),
              const SizedBox(width: TokensSpacing.s),
              Expanded(child: primary),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primary,
            const SizedBox(height: TokensSpacing.s),
            dontKnow,
          ],
        );
      },
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
