import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/artifact_kind.dart';
import '../../../../../domain/enums/question_type.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/models/academic/study_artifact.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/file_pick.dart';
import '../../widgets/mind_map_view.dart';
import '../bloc/generation_center_bloc.dart';
import 'artifact_editors.dart';

/// Centro de generación multi-fuente con IA.
class GenerationCenterPage extends StatelessWidget {
  const GenerationCenterPage({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<GenerationCenterBloc>()
          ..add(GenerationCenterEvent.started(subjectId: subjectId)),
    child: const _GenerationCenterView(),
  );
}

class _GenerationCenterView extends StatelessWidget with ErrorsMessageMixin {
  const _GenerationCenterView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // La subida avisa por su cuenta: un aviso de guardado no la repite.
    return BlocListener<GenerationCenterBloc, GenerationCenterState>(
      listenWhen: (a, b) =>
          (b.uploadError != null && a.uploadError != b.uploadError) ||
          (b.uploadOutcome != null && a.uploadOutcome != b.uploadOutcome),
      listener: (context, state) => context.showSnack(
        state.uploadError != null
            ? errorMessage(context, state.uploadError!)
            : state.uploadOutcome == FileUploadOutcome.readable
            ? l10n.academicFileUploaded
            : l10n.academicGenerateFileUnreadable,
      ),
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<GenerationCenterBloc, GenerationCenterState>(
      listenWhen: (a, b) =>
          a.savedNoteId != b.savedNoteId ||
          a.savedMaterialId != b.savedMaterialId ||
          a.saveError != b.saveError ||
          a.generateError != b.generateError,
      listener: (context, state) {
        if (state.savedNoteId != null) {
          context.showSnack(l10n.academicGenerateSavedNote);
          context.pushReplacement(AcademicPaths.note(state.savedNoteId!));
        } else if (state.savedMaterialId != null) {
          context.showSnack(l10n.academicGenerateSavedQuiz);
          context.pushReplacement(
            AcademicPaths.practice(state.savedMaterialId!),
          );
        } else if (state.saveError != null) {
          context.showSnack(errorMessage(context, state.saveError!));
        } else if (state.generateError != null) {
          context.showSnack(errorMessage(context, state.generateError!));
        }
      },
      builder: (context, state) {
        final artifact = state.artifact;
        return PopScope(
          canPop: !state.edited,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final ok = await showConfirmDialog(
              context,
              title: l10n.academicGenerateLoseEditsTitle,
              message: l10n.academicGenerateLoseEditsMessage,
              confirmLabel: l10n.academicGenerateLoseEditsConfirm,
            );
            if (ok && context.mounted) context.pop();
          },
          child: Scaffold(
          appBar: AppPageBar(title: Text(l10n.academicGenerateTitle)),
          bottomNavigationBar: artifact == null
              ? _GenerateBar(state: state)
              : _ResultBar(state: state),
          body: switch (state) {
            GenerationCenterState(loading: true) => const AppSkeletonList(
              count: 5,
            ),
            GenerationCenterState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.read<GenerationCenterBloc>().add(
                const GenerationCenterEvent.started(),
              ),
            ),
            GenerationCenterState(generating: true) => _GeneratingView(
              kind: state.kind,
            ),
            _ when artifact != null => _ArtifactView(
              artifact: artifact,
              edited: state.edited,
              canUndo: state.beforeRemoval != null,
            ),
            _ => _SetupView(state: state),
          },
          ),
        );
      },
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({required this.state});

  final GenerationCenterState state;

  /// Crea un apunte en la asignatura y, al volver, recarga las fuentes.
  Future<void> _createNote(BuildContext context, String subjectId) async {
    final bloc = context.read<GenerationCenterBloc>();
    await context.push<Object?>(AcademicPaths.newNote(subjectId: subjectId));
    bloc.add(GenerationCenterEvent.subjectSelected(subjectId));
  }

  /// Sube un archivo a la asignatura elegida (lo hace el bloc).
  Future<void> _uploadFile(BuildContext context) async {
    final bloc = context.read<GenerationCenterBloc>();
    final l10n = context.localizations;
    final picked = await pickUploadFile();
    if (!context.mounted) return;
    switch (picked) {
      case PickedPayload(:final payload):
        bloc.add(GenerationCenterEvent.fileUploadRequested(payload));
      case PickedTooLarge():
        context.showSnack(l10n.academicErrorFileTooLarge);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<GenerationCenterBloc>();
    if (state.subjects.isEmpty) {
      return AppEmptyState(
        icon: Icons.school_outlined,
        title: l10n.academicEmptyTitle,
        message: l10n.academicGenerateNoSubjects,
      );
    }
    return AcademicBody(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: [
          Text(
            l10n.academicGenerateStepSubject,
            style: context.textStyles.titleSmall,
          ),
          const SizedBox(height: TokensSpacing.s),
          DropdownButtonFormField<String>(
            key: ValueKey(state.subjectId),
            initialValue: state.subjectId,
            isExpanded: true,
            hint: Text(l10n.academicGeneratePickSubject),
            items: [
              for (final s in state.subjects)
                DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              if (id != null) {
                bloc.add(GenerationCenterEvent.subjectSelected(id));
              }
            },
          ),
          const SizedBox(height: TokensSpacing.l),
          Text(
            l10n.academicGenerateStepKind,
            style: context.textStyles.titleSmall,
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              for (final kind in ArtifactKind.values)
                ChoiceChip(
                  avatar: Icon(artifactIcon(kind), size: TokensSize.iconXs),
                  label: Text(context.artifactLabel(kind)),
                  selected: state.kind == kind,
                  onSelected: (_) =>
                      bloc.add(GenerationCenterEvent.kindSelected(kind)),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.l),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.academicGenerateStepSources,
                  style: context.textStyles.titleSmall,
                ),
              ),
              Text(
                l10n.academicGenerateSelectedCount(
                  state.selected.length,
                  GenerationCenterBloc.maxSources,
                ),
                style: context.textStyles.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          if (state.subjectId == null)
            Text(l10n.academicGeneratePickSubjectFirst)
          else if (state.loadingSources)
            const AppSkeletonGroup(child: AppSkeleton(height: 160))
          else if (state.sourcesError != null)
            AppErrorView(
              error: state.sourcesError!,
              onRetry: () => bloc.add(
                GenerationCenterEvent.subjectSelected(state.subjectId!),
              ),
            )
          else if (state.notes.isEmpty && state.files.isEmpty)
            AppCard(
              child: AppEmptyState.compact(
                icon: Icons.note_add_outlined,
                title: l10n.academicGenerateNoSources,
                // Crear la fuente aquí mismo: antes había que salir a buscarla.
                action: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.s,
                  children: [
                    AppSecondaryButton(
                      label: l10n.academicGenerateCreateNote,
                      icon: const Icon(Icons.edit_note_rounded),
                      onPressed: () => _createNote(context, state.subjectId!),
                    ),
                    AppSecondaryButton(
                      label: l10n.academicGenerateUploadFile,
                      icon: const Icon(Icons.upload_file_rounded),
                      loading: state.uploading,
                      onPressed: () => _uploadFile(context),
                    ),
                  ],
                ),
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final note in state.notes)
                    _SourceTile(
                      source: StudySourceRef(
                        type: StudySourceType.note,
                        id: note.id,
                      ),
                      icon: Icons.description_outlined,
                      title: note.title,
                      selected: state.selected,
                    ),
                  for (final file in state.files)
                    _SourceTile(
                      source: StudySourceRef(
                        type: StudySourceType.file,
                        id: file.id,
                      ),
                      icon: fileIcon(file),
                      title: file.fileName,
                      selected: state.selected,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.icon,
    required this.title,
    required this.selected,
  });

  final StudySourceRef source;
  final IconData icon;
  final String title;
  final Set<StudySourceRef> selected;

  @override
  Widget build(BuildContext context) => AppFocusOutline(
    child: CheckboxListTile(
      value: selected.contains(source),
      onChanged: (_) => context.read<GenerationCenterBloc>().add(
        GenerationCenterEvent.sourceToggled(source),
      ),
      secondary: Icon(icon, color: context.colors.tertiary),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}

class _GenerateBar extends StatelessWidget {
  const _GenerateBar({required this.state});

  final GenerationCenterState state;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(TokensSpacing.m),
      child: AppPrimaryButton(
        label: context.localizations.academicGenerateAction,
        icon: Icons.lightbulb_outline_rounded,
        loading: state.generating,
        onPressed: state.selected.isEmpty || state.generating
            ? null
            : () => context.read<GenerationCenterBloc>().add(
                const GenerationCenterEvent.generateRequested(),
              ),
      ),
    ),
  );
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.state});

  final GenerationCenterState state;

  /// Descartar o volver a generar borra las correcciones: si las hay, se
  /// pregunta antes (no se pierde trabajo sin querer).
  Future<void> _keepingEdits(BuildContext context, VoidCallback action) async {
    if (state.edited) {
      final l10n = context.localizations;
      final ok = await showConfirmDialog(
        context,
        title: l10n.academicGenerateLoseEditsTitle,
        message: l10n.academicGenerateLoseEditsMessage,
        confirmLabel: l10n.academicGenerateLoseEditsConfirm,
      );
      if (!ok) return;
    }
    action();
  }

  Future<void> _save(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<GenerationCenterBloc>();
    final controller = TextEditingController(text: state.artifact?.title ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.academicGenerateSaveTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.of(dialogContext).pop(value);
          },
          decoration: InputDecoration(labelText: l10n.academicNoteTitleLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (_, _) => FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(l10n.commonSave),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null) {
      bloc.add(GenerationCenterEvent.saveRequested(title: title));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final asNote =
        state.artifact?.kind == ArtifactKind.summary ||
        state.artifact?.kind == ArtifactKind.mindMap;
    final bloc = context.read<GenerationCenterBloc>();
    final save = AppPrimaryButton(
      label: asNote
          ? l10n.academicGenerateSaveNote
          : l10n.academicGenerateSaveQuiz,
      icon: asNote ? Icons.note_add_outlined : Icons.quiz_outlined,
      loading: state.saving,
      onPressed: state.canSave ? () => _save(context) : null,
    );
    final tools = [
      IconButton(
            tooltip: l10n.academicGenerateDiscard,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _keepingEdits(
              context,
              () => bloc.add(const GenerationCenterEvent.discarded()),
            ),
          ),
          IconButton(
            tooltip: l10n.academicAiRegenerate,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _keepingEdits(
              context,
              () => bloc.add(const GenerationCenterEvent.generateRequested()),
            ),
          ),
    ];
    if (context.largeText) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TokensSpacing.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: tools),
              save,
            ],
          ),
        ),
      );
    }
    return BottomAppBar(
      child: Row(
        children: [
          ...tools,
          const SizedBox(width: TokensSpacing.s),
          Flexible(
            child: Align(alignment: AlignmentDirectional.centerEnd, child: save),
          ),
        ],
      ),
    );
  }
}

class _GeneratingView extends StatelessWidget {
  const _GeneratingView({required this.kind});

  final ArtifactKind kind;

  @override
  Widget build(BuildContext context) => AppWorkingView(
    icon: artifactIcon(kind),
    title: context.localizations.academicAiGenerating,
  );
}

/// Resultado de la IA listo para revisar: se puede corregir el texto del
/// resumen y cada tarjeta o pregunta, o quitar las que sobren, antes de guardar.
class _ArtifactView extends StatelessWidget {
  const _ArtifactView({
    required this.artifact,
    required this.edited,
    required this.canUndo,
  });

  final StudyArtifact artifact;
  final bool edited;

  /// Hay un «quitar» que se puede deshacer.
  final bool canUndo;

  Future<void> _fixSummary(BuildContext context) async {
    final bloc = context.read<GenerationCenterBloc>();
    final text = await showSummaryEditor(context, artifact.markdown ?? '');
    if (text != null && text != artifact.markdown) {
      bloc.add(GenerationCenterEvent.summaryEdited(text));
    }
  }

  Future<void> _fixCard(BuildContext context, int index) async {
    final bloc = context.read<GenerationCenterBloc>();
    final card = await showFlashcardEditor(context, artifact.flashcards[index]);
    if (card != null) {
      bloc.add(GenerationCenterEvent.flashcardEdited(index, card));
    }
  }

  Future<void> _fixQuestion(BuildContext context, int index) async {
    final bloc = context.read<GenerationCenterBloc>();
    final q = await showQuestionEditor(context, artifact.questions[index]);
    if (q != null) bloc.add(GenerationCenterEvent.questionEdited(index, q));
  }

  void _remove(BuildContext context, int index) {
    final l10n = context.localizations;
    final bloc = context.read<GenerationCenterBloc>()
      ..add(GenerationCenterEvent.itemRemoved(index));
    // El foco pasa al siguiente elemento de la lista (el que ocupa su sitio).
    FocusScope.of(context).nextFocus();
    context.showUndoSnack(
      artifact.flashcards.isNotEmpty
          ? l10n.academicGenerateCardRemoved
          : l10n.academicGenerateQuestionRemoved,
      onUndo: () => bloc.add(const GenerationCenterEvent.removalUndone()),
      onCommit: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    if (artifact.kind == ArtifactKind.mindMap && artifact.mindMap != null) {
      return MindMapView(map: artifact.mindMap!);
    }
    final hasText = artifact.markdown != null && artifact.markdown!.isNotEmpty;
    final emptyList =
        !hasText && artifact.flashcards.isEmpty && artifact.questions.isEmpty;
    return AcademicBody(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: [
          Text(artifact.title, style: context.textStyles.titleLarge),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              AppPill(
                label: l10n.academicGenerateEphemeral,
                color: context.palette.warning,
                icon: Icons.info_outline_rounded,
              ),
              if (edited)
                AppPill(
                  label: l10n.academicGenerateEditedPill,
                  color: context.palette.success,
                  icon: Icons.edit_note_rounded,
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          // La IA se equivoca a veces: decirlo y dar la forma de arreglarlo.
          Text(
            l10n.academicGenerateReviewHint,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          if (hasText) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => _fixSummary(context),
                icon: const Icon(Icons.edit_rounded),
                label: Text(l10n.academicGenerateFixSummary),
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            AcademicMarkdown(data: artifact.markdown!),
          ],
          if (emptyList)
            AppEmptyState(
              icon: Icons.layers_clear_rounded,
              title: l10n.academicGenerateAllRemoved,
              message: l10n.academicGenerateAllRemovedHint,
              action: Wrap(
                alignment: WrapAlignment.center,
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  if (canUndo)
                    AppSecondaryButton(
                      label: l10n.commonUndo,
                      icon: const Icon(Icons.undo_rounded),
                      onPressed: () => context.read<GenerationCenterBloc>().add(
                        const GenerationCenterEvent.removalUndone(),
                      ),
                    ),
                  AppSecondaryButton(
                    label: l10n.academicGenerateRegenerate,
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => context.read<GenerationCenterBloc>().add(
                      const GenerationCenterEvent.generateRequested(),
                    ),
                  ),
                ],
              ),
            ),
          for (final (i, card) in artifact.flashcards.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.question, style: context.textStyles.titleSmall),
                    const Divider(height: TokensSpacing.l),
                    Text(card.answer),
                    _ItemActions(
                      onFix: () => _fixCard(context, i),
                      onRemove: () => _remove(context, i),
                      fixLabel: l10n.academicGenerateFixCardNamed(i + 1),
                      removeLabel: l10n.academicGenerateRemoveCardNamed(i + 1),
                    ),
                  ],
                ),
              ),
            ),
          for (final (i, q) in artifact.questions.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.academicGenerateNumbered(i + 1, q.statement),
                      style: context.textStyles.titleSmall,
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    if (q.type == QuestionType.multipleChoice)
                      for (final o in q.options)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: TokensSpacing.xxs,
                          ),
                          child: MergeSemantics(
                            child: Row(
                              children: [
                                Icon(
                                  o == q.correctAnswer
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: TokensSize.iconXs,
                                  color: o == q.correctAnswer
                                      ? context.palette.success
                                      : context.colors.onSurfaceVariant,
                                  semanticLabel: o == q.correctAnswer
                                      ? l10n.academicGenerateCorrectAnswer
                                      : null,
                                ),
                                const SizedBox(width: TokensSpacing.s),
                                Expanded(child: Text(o)),
                              ],
                            ),
                          ),
                        )
                    else
                      Text(l10n.academicCorrectAnswer(q.correctAnswer)),
                    _ItemActions(
                      onFix: () => _fixQuestion(context, i),
                      onRemove: () => _remove(context, i),
                      fixLabel: l10n.academicGenerateFixQuestionNamed(i + 1),
                      removeLabel: l10n.academicGenerateRemoveQuestionNamed(
                        i + 1,
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
}

/// «Corregir» y «Quitar» al pie de una tarjeta o pregunta, con su nombre
/// completo para el lector de pantalla («Corregir la pregunta 3»).
class _ItemActions extends StatelessWidget {
  const _ItemActions({
    required this.onFix,
    required this.onRemove,
    required this.fixLabel,
    required this.removeLabel,
  });

  final VoidCallback onFix;
  final VoidCallback onRemove;
  final String fixLabel;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.s),
      child: Wrap(
        spacing: TokensSpacing.s,
        children: [
          TextButton.icon(
            onPressed: onFix,
            icon: const Icon(Icons.edit_rounded),
            label: Text(l10n.academicGenerateFix, semanticsLabel: fixLabel),
          ),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: Text(l10n.academicGenerateRemove, semanticsLabel: removeLabel),
          ),
        ],
      ),
    );
  }
}
