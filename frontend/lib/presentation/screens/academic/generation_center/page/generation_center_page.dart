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
        return Scaffold(
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
            _ when artifact != null => _ArtifactView(artifact: artifact),
            _ => _SetupView(state: state),
          },
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
        icon: Icons.auto_awesome_rounded,
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
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          decoration: InputDecoration(labelText: l10n.academicNoteTitleLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.commonSave),
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
    return BottomAppBar(
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.academicGenerateDiscard,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => bloc.add(const GenerationCenterEvent.discarded()),
          ),
          IconButton(
            tooltip: l10n.academicAiRegenerate,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                bloc.add(const GenerationCenterEvent.generateRequested()),
          ),
          const Spacer(),
          AppPrimaryButton(
            label: asNote
                ? l10n.academicGenerateSaveNote
                : l10n.academicGenerateSaveQuiz,
            icon: asNote ? Icons.note_add_outlined : Icons.quiz_outlined,
            loading: state.saving,
            onPressed: () => _save(context),
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TokensSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(artifactIcon(kind), size: 40, color: context.colors.tertiary),
          const SizedBox(height: TokensSpacing.m),
          const SizedBox(width: 160, child: LinearProgressIndicator()),
          const SizedBox(height: TokensSpacing.m),
          Text(
            context.localizations.academicAiGenerating,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ArtifactView extends StatelessWidget {
  const _ArtifactView({required this.artifact});

  final StudyArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    if (artifact.kind == ArtifactKind.mindMap && artifact.mindMap != null) {
      return MindMapView(map: artifact.mindMap!);
    }
    return AcademicBody(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: [
          Text(artifact.title, style: context.textStyles.titleLarge),
          const SizedBox(height: TokensSpacing.s),
          AppPill(
            label: l10n.academicGenerateEphemeral,
            color: context.palette.warning,
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: TokensSpacing.m),
          if (artifact.markdown != null && artifact.markdown!.isNotEmpty)
            AcademicMarkdown(data: artifact.markdown!),
          for (final card in artifact.flashcards)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.question, style: context.textStyles.titleSmall),
                    const Divider(height: TokensSpacing.l),
                    Text(card.answer),
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
                      '${i + 1}. ${q.statement}',
                      style: context.textStyles.titleSmall,
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    if (q.type == QuestionType.multipleChoice)
                      for (final o in q.options)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: TokensSpacing.xxs,
                          ),
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
                              ),
                              const SizedBox(width: TokensSpacing.s),
                              Expanded(child: Text(o)),
                            ],
                          ),
                        )
                    else
                      Text(l10n.academicCorrectAnswer(q.correctAnswer)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
