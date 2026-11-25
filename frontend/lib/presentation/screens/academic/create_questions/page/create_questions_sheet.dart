import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/question_creation_enums.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/models/academic/question_creation.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../bloc/create_questions_bloc.dart';
import 'review_questions_page.dart';

/// Abre la hoja «Crear preguntas» (ADR 0058) de un material ([materialId])
/// o de la asignatura ([subjectId]: primero se elige el apunte). Devuelve el
/// banco guardado o `null` si se cerró sin guardar.
Future<QuestionBank?> showCreateQuestionsSheet(
  BuildContext context, {
  String? materialId,
  String? title,
  String? subjectId,
}) => showModalBottomSheet<QuestionBank>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => BlocProvider(
    create: (_) => getIt<CreateQuestionsBloc>()
      ..add(
        CreateQuestionsEvent.started(
          materialId: materialId,
          title: title,
          subjectId: subjectId,
        ),
      ),
    child: const _CreateQuestionsSheet(),
  ),
);

/// Aviso tras guardar: cuántas se guardaron y, si fueron menos de las
/// pedidas, por qué. Con [onPractice], el botón «Practicar».
void showQuestionsSavedSnack(
  BuildContext context,
  QuestionBank bank, {
  VoidCallback? onPractice,
}) {
  final l10n = context.localizations;
  final created = bank.createdQuestions ?? bank.questions.length;
  final requested = bank.requestedQuestions ?? created;
  final message = created < requested
      ? l10n.createQuestionsPartial(created, requested)
      : l10n.createQuestionsSaved(created);
  if (onPractice == null) {
    context.showSnack(message);
  } else {
    context.showActionSnack(
      message,
      actionLabel: l10n.academicPracticeAction,
      onAction: onPractice,
    );
  }
}

class _CreateQuestionsSheet extends StatefulWidget {
  const _CreateQuestionsSheet();

  @override
  State<_CreateQuestionsSheet> createState() => _CreateQuestionsSheetState();
}

class _CreateQuestionsSheetState extends State<_CreateQuestionsSheet> {
  /// La revisión está abierta encima de la hoja.
  bool _reviewOpen = false;

  Future<void> _openReview(BuildContext context) async {
    final bloc = context.read<CreateQuestionsBloc>();
    _reviewOpen = true;
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const ReviewQuestionsPage()),
      ),
    );
    _reviewOpen = false;
  }

  void _close(BuildContext context, QuestionBank bank) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (_reviewOpen) navigator.pop();
    navigator.pop(bank);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<CreateQuestionsBloc, CreateQuestionsState>(
        listenWhen: (a, b) =>
            a.reviewRequest != b.reviewRequest ||
            (a.saved == null && b.saved != null),
        listener: (context, state) {
          if (state.saved case final bank?) {
            _close(context, bank);
          } else {
            _openReview(context);
          }
        },
        // Mientras se guardan no se cierra: se perdería el aviso del resultado.
        child: BlocSelector<CreateQuestionsBloc, CreateQuestionsState, bool>(
          selector: (s) => s.saving,
          builder: (context, saving) =>
              PopScope(canPop: !saving, child: _sheet()),
        ),
      );

  Widget _sheet() => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (context, controller) => SafeArea(
      child: BlocBuilder<CreateQuestionsBloc, CreateQuestionsState>(
        builder: (context, state) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            0,
            TokensSpacing.m,
            TokensSpacing.l,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                context.localizations.academicCreateQuestions,
                style: context.textStyles.headlineSmall,
              ),
            ),
            if (state.choosingSource ||
                state.loadingSources ||
                state.sourcesError != null)
              _SourcePicker(state: state)
            else
              _Form(state: state),
          ],
        ),
      ),
    ),
  );
}

/// «¿De qué apunte?»: apuntes y archivos que la IA puede leer.
class _SourcePicker extends StatelessWidget {
  const _SourcePicker({required this.state});

  final CreateQuestionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<CreateQuestionsBloc>();
    if (state.loadingSources) {
      return const AppSkeletonList(count: 3, height: 56, shrinkWrap: true);
    }
    if (state.sourcesError case final error?) {
      return AppErrorView(
        error: error,
        onRetry: () => bloc.add(const CreateQuestionsEvent.retried()),
      );
    }
    if (state.sources.isEmpty) {
      final subjectId = state.subjectId;
      return AppEmptyState(
        icon: AppIcons.newNote,
        title: l10n.createQuestionsNoSources,
        message: l10n.createQuestionsPickSourceEmpty,
        action: subjectId == null
            ? null
            : AppPrimaryButton(
                label: l10n.academicNoteNew,
                icon: AppIcons.add,
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(AcademicPaths.newNote(subjectId: subjectId));
                },
              ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: TokensSpacing.m),
        Text(
          l10n.createQuestionsPickSource,
          style: context.textStyles.titleMedium,
        ),
        const SizedBox(height: TokensSpacing.s),
        for (final source in state.sources)
          AppFocusOutline(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                source.type == StudySourceType.file
                    ? AppIcons.noteDocument
                    : AppIcons.quickNote,
                color: context.palette.study,
              ),
              title: Text(
                source.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                source.type == StudySourceType.file
                    ? l10n.createQuestionsFileLabel
                    : l10n.createQuestionsNoteLabel,
              ),
              trailing: const Icon(AppIcons.next),
              onTap: () => bloc.add(CreateQuestionsEvent.sourceChosen(source)),
            ),
          ),
      ],
    );
  }
}

/// Tipo, cuántas, qué hacer con las del documento y con las que ya tienes.
class _Form extends StatelessWidget with ErrorsMessageMixin {
  const _Form({required this.state});

  final CreateQuestionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<CreateQuestionsBloc>();
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final canChange = state.subjectId != null && state.sources.length > 1;
    if (state.prepareError case final error?) {
      return AppErrorView(
        error: error,
        onRetry: () => bloc.add(const CreateQuestionsEvent.retried()),
      );
    }
    final onlyDocument =
        state.usesDocument && state.documentUse == DocumentQuestionUse.only;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.title case final title?)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.createQuestionsFrom(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
              if (canChange)
                TextButton(
                  onPressed: state.saving
                      ? null
                      : () => bloc.add(
                          const CreateQuestionsEvent.sourcePickRequested(),
                        ),
                  child: Text(
                    l10n.createQuestionsChangeSource,
                    semanticsLabel: l10n.createQuestionsChangeSourceLabel,
                  ),
                ),
            ],
          ),
        if (state.preparing) ...[
          const SizedBox(height: TokensSpacing.m),
          const AppSkeletonList(
            count: 3,
            height: 56,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
          ),
        ] else ...[
          if (state.asksNewQuestions) ...[
            const SizedBox(height: TokensSpacing.m),
            AppSegmentedChoice<QuestionFormat>(
              label: l10n.createQuestionsType,
              values: QuestionFormat.values,
              selected: state.format,
              labelOf: (f) => _formatLabel(context, f),
              onChanged: (f) {
                if (f != null) bloc.add(CreateQuestionsEvent.formatChosen(f));
              },
            ),
            const SizedBox(height: TokensSpacing.m),
            AppStepperField(
              label: l10n.createQuestionsHowMany,
              value: state.count,
              min: QuestionCount.min,
              max: QuestionCount.max,
              step: QuestionCount.step,
              hint: l10n.createQuestionsHowManyRange,
              decreaseLabel: l10n.createQuestionsLess,
              increaseLabel: l10n.createQuestionsMore,
              spokenValueOf: l10n.createQuestionsCountValue,
              onChanged: (v) => bloc.add(CreateQuestionsEvent.countChanged(v)),
            ),
          ],
          const SizedBox(height: TokensSpacing.m),
          _DocumentSection(state: state),
          if (state.showsModeChoice) ...[
            const SizedBox(height: TokensSpacing.m),
            _ChoiceGroup<BankUpdateMode>(
              title: l10n.createQuestionsExisting(state.existingCount),
              selected: state.mode,
              values: BankUpdateMode.values,
              labelOf: (m) => m == BankUpdateMode.add
                  ? l10n.createQuestionsAdd
                  : l10n.createQuestionsReplace,
              hintOf: (m) => m == BankUpdateMode.replace
                  ? l10n.createQuestionsReplaceHint
                  : null,
              onChanged: (m) => bloc.add(CreateQuestionsEvent.modeChosen(m)),
            ),
          ],
          const SizedBox(height: TokensSpacing.l),
          if (state.saveError case final error? when !state.usesDocument) ...[
            AppInlineMessage(message: errorMessage(context, error)),
            const SizedBox(height: TokensSpacing.s),
          ],
          AppPrimaryButton(
            label: state.saveError != null && !state.usesDocument
                ? l10n.commonRetry
                : onlyDocument
                ? l10n.createQuestionsReviewOnly
                : l10n.createQuestionsSubmit(state.count),
            loading: state.saving,
            onPressed: state.ready
                ? () => bloc.add(const CreateQuestionsEvent.submitted())
                : null,
          ),
          const SizedBox(height: TokensSpacing.xs),
          if (state.saving)
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.createQuestionsCreating,
                textAlign: TextAlign.center,
                style: muted,
              ),
            )
          else if (state.usesDocument)
            Text(
              l10n.createQuestionsReviewFirst,
              textAlign: TextAlign.center,
              style: muted,
            ),
        ],
      ],
    );
  }

  static String _formatLabel(BuildContext context, QuestionFormat format) {
    final l10n = context.localizations;
    return switch (format) {
      QuestionFormat.singleChoice => l10n.createQuestionsFormatSingle,
      QuestionFormat.multipleAnswer => l10n.createQuestionsFormatMultiple,
      QuestionFormat.fillInBlank => l10n.createQuestionsFormatFill,
      QuestionFormat.flashcard => l10n.createQuestionsFormatCards,
      QuestionFormat.mixed => l10n.createQuestionsFormatMixed,
    };
  }
}

/// Si el documento ya trae preguntas: mirando (la IA tarda), no se pudo
/// mirar (con «Reintentar») o la elección; si no trae, nada.
class _DocumentSection extends StatelessWidget {
  const _DocumentSection({required this.state});

  final CreateQuestionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<CreateQuestionsBloc>();
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    if (state.scanning) {
      return Semantics(
        liveRegion: true,
        child: Row(
          children: [
            const SizedBox.square(
              dimension: TokensSize.iconXs,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(child: Text(l10n.createQuestionsSearching, style: muted)),
          ],
        ),
      );
    }
    if (state.scanError != null) {
      return Row(
        children: [
          Expanded(child: Text(l10n.createQuestionsSearchFailed, style: muted)),
          TextButton(
            onPressed: () => bloc.add(const CreateQuestionsEvent.scanRetried()),
            child: Text(l10n.createQuestionsSearchAgain),
          ),
        ],
      );
    }
    if (!state.showsDocumentChoice) return const SizedBox.shrink();
    return _ChoiceGroup<DocumentQuestionUse>(
      title: l10n.createQuestionsDocFound(state.documentQuestions.length),
      selected: state.documentUse,
      values: DocumentQuestionUse.values,
      labelOf: (u) => switch (u) {
        DocumentQuestionUse.none => l10n.createQuestionsDocNone,
        DocumentQuestionUse.only => l10n.createQuestionsDocOnly,
        DocumentQuestionUse.mix => l10n.createQuestionsDocMix,
      },
      onChanged: (u) => bloc.add(CreateQuestionsEvent.documentUseChosen(u)),
    );
  }
}

/// Grupo de opciones excluyentes con su título (el lector lo anuncia).
class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.selected,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.hintOf,
  });

  final String title;
  final T selected;
  final List<T> values;
  final String Function(T value) labelOf;
  final String? Function(T value)? hintOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(title, style: context.textStyles.titleSmall),
        ),
        const SizedBox(height: TokensSpacing.xs),
        AppCard(
          padding: EdgeInsets.zero,
          child: RadioGroup<T>(
            groupValue: selected,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            child: Column(
              children: [
                for (final v in values)
                  AppFocusOutline(
                    child: RadioListTile<T>(
                      value: v,
                      title: Text(labelOf(v)),
                      subtitle: switch (hintOf?.call(v)) {
                        final hint? => Text(hint),
                        null => null,
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
