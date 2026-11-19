import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/enums/question_creation_enums.dart';
import '../../../../../domain/enums/question_type.dart';
import '../../../../../domain/models/academic/question_creation.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/create_questions_bloc.dart';

/// «Revisa las de tu apunte» (ADR 0058): casilla «Usar» por pregunta,
/// «Cambiar la respuesta» y «Guardar N preguntas» con cuántas son del apunte
/// y cuántas nuevas. Las de respuesta larga salen atenuadas con el motivo.
/// Se abre encima de la hoja con su mismo [CreateQuestionsBloc].
class ReviewQuestionsPage extends StatelessWidget with ErrorsMessageMixin {
  const ReviewQuestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<CreateQuestionsBloc, CreateQuestionsState>(
      builder: (context, state) {
        final bloc = context.read<CreateQuestionsBloc>();
        return Scaffold(
          appBar: AppPageBar(
            leading: const AppBackButton(fallback: AcademicPaths.root),
            title: Text(l10n.reviewQuestionsTitle),
          ),
          body: AcademicBody(
            child: ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                Text(
                  l10n.reviewQuestionsSubtitle(
                    state.usedCount,
                    state.reviewed.length,
                  ),
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (state.scan?.complete == false) ...[
                  const SizedBox(height: TokensSpacing.s),
                  AppInlineMessage(
                    message: l10n.reviewQuestionsIncomplete,
                    tone: AppMessageTone.info,
                  ),
                ],
                const SizedBox(height: TokensSpacing.m),
                for (var i = 0; i < state.reviewed.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                    child: _ReviewCard(
                      question: state.reviewed[i],
                      used: state.used.contains(i),
                      enabled: !state.saving,
                      onToggle: () =>
                          bloc.add(CreateQuestionsEvent.reviewToggled(i)),
                      onChangeAnswer: () async {
                        final answers = await _askAnswer(
                          context,
                          state.reviewed[i],
                        );
                        if (answers != null) {
                          bloc.add(
                            CreateQuestionsEvent.answerChanged(i, answers),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: _SaveBar(state: state),
        );
      },
    );
  }
}

/// «Guardar N preguntas» y el recuento «X de tu apunte y Y nuevas».
class _SaveBar extends StatelessWidget with ErrorsMessageMixin {
  const _SaveBar({required this.state});

  final CreateQuestionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final total = state.totalToSave;
    final split = total == 0
        ? l10n.reviewQuestionsPickOne
        : state.newCount > 0
        ? l10n.reviewQuestionsSplit(state.usedCount, state.newCount)
        : l10n.reviewQuestionsOnlyDocument(state.usedCount);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: AppContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(TokensSpacing.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.saveError case final error?) ...[
                  AppInlineMessage(message: errorMessage(context, error)),
                  const SizedBox(height: TokensSpacing.s),
                ],
                AppPrimaryButton(
                  label: state.saveError != null
                      ? l10n.commonRetry
                      : l10n.reviewQuestionsSave(total),
                  loading: state.saving,
                  onPressed: total == 0
                      ? null
                      : () => context.read<CreateQuestionsBloc>().add(
                          const CreateQuestionsEvent.saveRequested(),
                        ),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.saving ? l10n.createQuestionsCreating : split,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.question,
    required this.used,
    required this.enabled,
    required this.onToggle,
    required this.onChangeAnswer,
  });

  final DocumentQuestion question;
  final bool used;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onChangeAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final q = question;
    final usable = q.usable;
    final type = q.type;
    final muted = context.colors.onSurfaceVariant;
    final kind = type == null
        ? l10n.reviewQuestionsLongAnswer
        : context.questionTypeLabel(type, statement: q.statement);
    final reason = switch (q.status) {
      DocumentQuestionStatus.longAnswer => l10n.reviewQuestionsLongAnswerReason,
      _ when !usable => l10n.reviewQuestionsNoAnswerReason,
      _ => null,
    };
    final proposed =
        usable && q.status == DocumentQuestionStatus.answerProposed;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: AppPill(
                  label: kind,
                  color: usable ? context.colors.tertiary : muted,
                ),
              ),
              const Spacer(),
              // Un solo control: la fila entera. El lector oye «Usar» con el
              // enunciado («Usar» a secas no dice cuál) y si está marcada.
              MergeSemantics(
                child: Semantics(
                  label: q.statement,
                  checked: usable && used,
                  enabled: usable && enabled,
                  child: AppFocusOutline(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TokensRadius.m),
                      onTap: usable && enabled ? onToggle : null,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: TokensLayout.minTouchTarget,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeFocus(
                              child: ExcludeSemantics(
                                child: Checkbox(
                                  value: usable && used,
                                  onChanged: usable && enabled
                                      ? (_) => onToggle()
                                      : null,
                                ),
                              ),
                            ),
                            Text(
                              l10n.reviewQuestionsUse,
                              style: context.textStyles.labelLarge?.copyWith(
                                color: usable ? null : muted,
                              ),
                            ),
                            const SizedBox(width: TokensSpacing.xs),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            q.statement,
            style: context.textStyles.titleSmall?.copyWith(
              color: usable ? null : muted,
            ),
          ),
          if (usable) ...[
            const SizedBox(height: TokensSpacing.s),
            if (type!.hasOptions)
              for (final option in q.options)
                _OptionLine(
                  text: q.correctAnswers.contains(option)
                      ? l10n.reviewQuestionsCorrectOption(option)
                      : option,
                  correct: q.correctAnswers.contains(option),
                )
            else if (!proposed)
              _OptionLine(
                text: l10n.reviewQuestionsAnswer(q.correctAnswers.join(' · ')),
                correct: true,
              ),
            if (type == QuestionType.multipleAnswer)
              Text(
                l10n.reviewQuestionsAllOrNothing,
                style: context.textStyles.bodySmall?.copyWith(color: muted),
              ),
            if (proposed) ...[
              const SizedBox(height: TokensSpacing.xs),
              AppInlineMessage(
                message: l10n.reviewQuestionsProposed(
                  q.correctAnswers.join(' · '),
                ),
                tone: AppMessageTone.warning,
                live: false,
              ),
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: enabled ? onChangeAnswer : null,
                child: Text(
                  l10n.reviewQuestionsChangeAnswer,
                  semanticsLabel: l10n.reviewQuestionsChangeAnswerFor(
                    q.statement,
                  ),
                ),
              ),
            ),
          ] else if (reason != null) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              reason,
              style: context.textStyles.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Una opción de la pregunta; la correcta, resaltada.
class _OptionLine extends StatelessWidget {
  const _OptionLine({required this.text, required this.correct});

  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        border: correct ? Border.all(color: context.palette.success) : null,
        borderRadius: BorderRadius.circular(TokensRadius.s),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensSpacing.sm,
          vertical: TokensSpacing.xs,
        ),
        child: Row(
          children: [
            if (correct) ...[
              Icon(
                Icons.check_rounded,
                size: TokensSize.iconXs,
                color: context.palette.success,
              ),
              const SizedBox(width: TokensSpacing.xs),
            ],
            Expanded(
              child: Text(
                text,
                style: context.textStyles.bodyMedium?.copyWith(
                  fontWeight: correct ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// «Cambiar la respuesta»: elegir la opción (o las opciones) correctas o
/// escribir la respuesta. Devuelve la nueva o `null` si se cancela.
Future<List<String>?> _askAnswer(
  BuildContext context,
  DocumentQuestion question,
) => showDialog<List<String>>(
  context: context,
  builder: (_) => _AnswerDialog(question: question),
);

class _AnswerDialog extends StatefulWidget {
  const _AnswerDialog({required this.question});

  final DocumentQuestion question;

  @override
  State<_AnswerDialog> createState() => _AnswerDialogState();
}

class _AnswerDialogState extends State<_AnswerDialog> {
  late final Set<String> _chosen = {...widget.question.correctAnswers};
  late final TextEditingController _text = TextEditingController(
    text: widget.question.correctAnswers.join(' '),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<String> get _answer => widget.question.type!.hasOptions
      ? [
          for (final o in widget.question.options)
            if (_chosen.contains(o)) o,
        ]
      : [_text.text.trim()];

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final q = widget.question;
    final multiple = q.type == QuestionType.multipleAnswer;
    final valid = _answer.any((a) => a.isNotEmpty);
    return AlertDialog(
      title: Text(l10n.reviewQuestionsChangeAnswer),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.statement, style: context.textStyles.bodyLarge),
            if (multiple)
              Text(
                l10n.academicChooseAllCorrect,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: TokensSpacing.s),
            if (!q.type!.hasOptions)
              TextField(
                controller: _text,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (valid) Navigator.of(context).pop(_answer);
                },
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.reviewQuestionsAnswerField,
                ),
              )
            else if (multiple)
              for (final o in q.options)
                AppFocusOutline(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _chosen.contains(o),
                    title: Text(o),
                    onChanged: (v) => setState(
                      () => v == true ? _chosen.add(o) : _chosen.remove(o),
                    ),
                  ),
                )
            else
              RadioGroup<String>(
                groupValue: _chosen.firstOrNull,
                onChanged: (v) => setState(() {
                  _chosen
                    ..clear()
                    ..addAll([?v]);
                }),
                child: Column(
                  children: [
                    for (final o in q.options)
                      AppFocusOutline(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: o,
                          title: Text(o),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: valid ? () => Navigator.of(context).pop(_answer) : null,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
