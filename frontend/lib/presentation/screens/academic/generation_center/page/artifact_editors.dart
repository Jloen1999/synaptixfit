import 'package:flutter/material.dart';

import '../../../../../domain/enums/question_type.dart';
import '../../../../../domain/models/academic/study_artifact.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/academic_widgets.dart';

/// Pantalla completa para corregir el texto de un resumen generado por la IA.
/// Devuelve el texto nuevo o `null` si se cancela.
Future<String?> showSummaryEditor(BuildContext context, String initial) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SummaryEditor(initial: initial),
      ),
    );

class _SummaryEditor extends StatefulWidget {
  const _SummaryEditor({required this.initial});

  final String initial;

  @override
  State<_SummaryEditor> createState() => _SummaryEditorState();
}

class _SummaryEditorState extends State<_SummaryEditor> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _AskBeforeLosing(
        dirty: _controller.text != widget.initial,
        child: Scaffold(
          appBar: AppPageBar(
            title: Text(l10n.academicGenerateFixSummaryTitle),
            actions: [
              TextButton(
                onPressed: _controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_controller.text),
                child: Text(l10n.academicGenerateFixDone),
              ),
            ],
          ),
          body: SafeArea(
            child: AppContentWidth.reading(
              child: Padding(
                padding: const EdgeInsets.all(TokensSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.academicGenerateFixSummaryHint,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          labelText: l10n.academicGenerateFixSummaryLabel,
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
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

/// Hoja para corregir una tarjeta. Devuelve la tarjeta corregida o `null`.
Future<Flashcard?> showFlashcardEditor(BuildContext context, Flashcard card) =>
    showModalBottomSheet<Flashcard>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FlashcardEditor(card: card),
    );

class _FlashcardEditor extends StatefulWidget {
  const _FlashcardEditor({required this.card});

  final Flashcard card;

  @override
  State<_FlashcardEditor> createState() => _FlashcardEditorState();
}

class _FlashcardEditorState extends State<_FlashcardEditor> {
  late final _question = TextEditingController(text: widget.card.question);
  late final _answer = TextEditingController(text: widget.card.answer);

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  bool get _valid =>
      _question.text.trim().isNotEmpty && _answer.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return _EditorSheet(
      title: l10n.academicGenerateFixCardTitle,
      canSave: _valid,
      dirty:
          _question.text != widget.card.question ||
          _answer.text != widget.card.answer,
      onSave: () => Navigator.of(context).pop(
        Flashcard(question: _question.text.trim(), answer: _answer.text.trim()),
      ),
      children: [
        TextField(
          controller: _question,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.academicGenerateFieldQuestion,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        TextField(
          controller: _answer,
          minLines: 1,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.academicGenerateFieldAnswer,
          ),
        ),
      ],
    );
  }
}

/// Hoja para corregir una pregunta del test. Devuelve la pregunta corregida o
/// `null`. En las de elegir, se marca cuál es la buena tocando su círculo.
Future<QuestionDraft?> showQuestionEditor(
  BuildContext context,
  QuestionDraft question,
) => showModalBottomSheet<QuestionDraft>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _QuestionEditor(question: question),
);

class _QuestionEditor extends StatefulWidget {
  const _QuestionEditor({required this.question});

  final QuestionDraft question;

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late final _statement = TextEditingController(
    text: widget.question.statement,
  );
  late final List<TextEditingController> _options = [
    for (final o in widget.question.options) TextEditingController(text: o),
  ];
  late final _answer = TextEditingController(
    text: widget.question.correctAnswer,
  );

  /// Opción marcada como buena (elegir entre varias).
  late int _correct = widget.question.options.indexOf(
    widget.question.correctAnswer,
  );

  bool get _choice => widget.question.type == QuestionType.multipleChoice;

  @override
  void dispose() {
    _statement.dispose();
    for (final c in _options) {
      c.dispose();
    }
    _answer.dispose();
    super.dispose();
  }

  bool get _valid {
    if (_statement.text.trim().isEmpty) return false;
    if (!_choice) return _answer.text.trim().isNotEmpty;
    return _correct >= 0 && _options.every((c) => c.text.trim().isNotEmpty);
  }

  QuestionDraft get _result {
    final options = [for (final c in _options) c.text.trim()];
    return widget.question.copyWith(
      statement: _statement.text.trim(),
      options: _choice ? options : widget.question.options,
      correctAnswer: _choice ? options[_correct] : _answer.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return _EditorSheet(
      title: l10n.academicGenerateFixQuestionTitle,
      canSave: _valid,
      dirty: _result != widget.question,
      onSave: () => Navigator.of(context).pop(_result),
      children: [
        TextField(
          controller: _statement,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.academicGenerateFieldQuestion,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        if (_choice) ...[
          Text(
            l10n.academicGenerateMarkCorrect,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          RadioGroup<int>(
            groupValue: _correct,
            onChanged: (v) => setState(() => _correct = v ?? _correct),
            child: Column(
              children: [
                for (final (i, controller) in _options.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                    child: Row(
                      children: [
                        AppFocusOutline(
                          child: Semantics(
                            label: l10n.academicGenerateCorrectOption(i + 1),
                            child: Radio<int>(value: i),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: l10n.academicGenerateFieldOption(
                                i + 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ] else
          TextField(
            controller: _answer,
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.academicGenerateFieldAnswer,
            ),
          ),
      ],
    );
  }
}

/// Armazón común de las hojas de corrección: título, campos y «Guardar».
class _EditorSheet extends StatelessWidget {
  const _EditorSheet({
    required this.title,
    required this.children,
    required this.canSave,
    required this.onSave,
    required this.dirty,
  });

  final String title;
  final List<Widget> children;
  final bool canSave;
  final VoidCallback onSave;

  /// Hay cambios sin guardar: cerrar la hoja pregunta antes.
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return _AskBeforeLosing(
      dirty: dirty,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: TokensSpacing.l,
              right: TokensSpacing.l,
              bottom: TokensSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.textStyles.titleLarge),
                ),
                const SizedBox(height: TokensSpacing.m),
                ...children,
                const SizedBox(height: TokensSpacing.l),
                AppPrimaryButton(
                  label: l10n.academicGenerateFixApply,
                  icon: Icons.check_rounded,
                  onPressed: canSave ? onSave : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cerrar (atrás, deslizar la hoja o tocar fuera) con cambios sin guardar
/// pregunta antes: corregir lo de la IA cuesta y no debe perderse sin querer.
class _AskBeforeLosing extends StatelessWidget {
  const _AskBeforeLosing({required this.dirty, required this.child});

  final bool dirty;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final l10n = context.localizations;
      final ok = await confirmDestructive(
        context,
        title: l10n.academicGenerateLoseFixTitle,
        message: l10n.academicGenerateLoseFixMessage,
        confirmLabel: l10n.academicGenerateLoseFixConfirm,
      );
      if (ok && context.mounted) Navigator.of(context).pop();
    },
    child: child,
  );
}
