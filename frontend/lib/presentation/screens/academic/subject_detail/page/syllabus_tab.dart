import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/enums/ai_document_type.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/study_document.dart';
import '../../../../../domain/models/academic/subject_file.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/ai_assistant_sheet.dart';
import '../../widgets/file_pick.dart';
import '../bloc/subject_detail_bloc.dart';
import '../bloc/subject_progress_bloc.dart';
import '../bloc/subject_syllabus_bloc.dart';

/// Pestaña Temario: apuntes y archivos de la asignatura.
class SyllabusTab extends StatelessWidget with ErrorsMessageMixin {
  const SyllabusTab({super.key});

  /// Abre una ruta y, al volver, recarga el temario y la cabecera (recuentos).
  Future<void> _openAndRefresh(BuildContext context, String location) async {
    final syllabus = context.read<SubjectSyllabusBloc>();
    final detail = context.read<SubjectDetailBloc>();
    await context.push<Object?>(location);
    syllabus.add(const SubjectSyllabusEvent.refreshed());
    detail.add(const SubjectDetailEvent.refreshed());
  }

  Future<void> _upload(BuildContext context) async {
    final bloc = context.read<SubjectSyllabusBloc>();
    final picked = await pickUploadFile();
    if (!context.mounted) return;
    switch (picked) {
      case PickedPayload(:final payload):
        bloc.add(SubjectSyllabusEvent.uploadRequested(payload));
      case PickedTooLarge():
        context.showSnack(
          errorMessage(context, const AppError.business('FILE_TOO_LARGE')),
        );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SubjectSyllabusBloc, SubjectSyllabusState>(
      listenWhen: (a, b) =>
          a.message != b.message ||
          a.actionError != b.actionError ||
          a.navigation != b.navigation,
      listener: (context, state) {
        final navigation = state.navigation;
        if (navigation != null) {
          context.push(
            navigation.practice
                ? AcademicPaths.practice(navigation.materialId)
                : AcademicPaths.review(navigation.materialId),
          );
        } else if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        } else if (state.message != null) {
          context.showSnack(switch (state.message!) {
            SyllabusMessage.fileUploaded => l10n.academicFileUploaded,
            SyllabusMessage.fileDeleted => l10n.academicFileDeleted,
            SyllabusMessage.noteDeleted => l10n.academicNoteDeleted,
          });
          // Los archivos nuevos pueden servir para la guía docente.
          context.read<SubjectProgressBloc>().add(
            const SubjectProgressEvent.refreshed(),
          );
          context.read<SubjectDetailBloc>().add(
            const SubjectDetailEvent.refreshed(),
          );
        }
      },
      builder: (context, state) {
        if (state.loading) return const AppSkeletonList(count: 5);
        if (state.error != null) {
          return AppErrorView(
            error: state.error!,
            onRetry: () => context.read<SubjectSyllabusBloc>().add(
              SubjectSyllabusEvent.started(state.subjectId),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<SubjectSyllabusBloc>().add(
            const SubjectSyllabusEvent.refreshed(),
          ),
          child: AcademicBody(
            child: ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                if (state.busy) const LinearProgressIndicator(),
                _GenerateBanner(
                  onTap: () => _openAndRefresh(
                    context,
                    AcademicPaths.generate(subjectId: state.subjectId),
                  ),
                ),
                const SizedBox(height: TokensSpacing.l),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.academicNotesTitle(state.notes.length),
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.academicScanTitle,
                      icon: const Icon(Icons.document_scanner_outlined),
                      onPressed: () => _openAndRefresh(
                        context,
                        AcademicPaths.scanNote(subjectId: state.subjectId),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAndRefresh(
                        context,
                        AcademicPaths.newNote(subjectId: state.subjectId),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.academicNoteNew),
                    ),
                  ],
                ),
                const SizedBox(height: TokensSpacing.s),
                if (state.notes.isEmpty)
                  _EmptyHint(
                    icon: Icons.note_alt_outlined,
                    text: l10n.academicNotesEmpty,
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final note in state.notes)
                          _NoteTile(
                            note: note,
                            availability:
                                state.availability[note.id] ??
                                DocumentAvailability.none,
                            onOpen: () => _openAndRefresh(
                              context,
                              AcademicPaths.note(note.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: TokensSpacing.l),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.academicFilesTitle(state.files.length),
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: state.uploading
                          ? null
                          : () => _upload(context),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(l10n.academicFileUpload),
                    ),
                  ],
                ),
                if (state.uploading) ...[
                  const SizedBox(height: TokensSpacing.s),
                  Text(
                    l10n.academicFileUploading(
                      ((state.uploadProgress ?? 0) * 100).round(),
                    ),
                    style: context.textStyles.labelMedium,
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  AcademicProgressBar(
                    value: state.uploadProgress ?? 0,
                    color: context.colors.tertiary,
                  ),
                ],
                const SizedBox(height: TokensSpacing.s),
                if (state.files.isEmpty)
                  _EmptyHint(
                    icon: Icons.folder_open_outlined,
                    text: l10n.academicFilesEmpty,
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final file in state.files)
                          _FileTile(
                            file: file,
                            availability:
                                state.availability[file.id] ??
                                DocumentAvailability.none,
                            onOpen: () => _openAndRefresh(
                              context,
                              AcademicPaths.file(file.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: TokensSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GenerateBanner extends StatelessWidget {
  const _GenerateBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      onTap: onTap,
      color: context.colors.tertiaryContainer.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: context.colors.tertiary),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.academicGenerateTitle,
                  style: context.textStyles.titleSmall,
                ),
                Text(
                  l10n.academicGenerateBanner,
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Icon(icon, color: context.colors.onSurfaceVariant),
        const SizedBox(width: TokensSpacing.m),
        Expanded(
          child: Text(
            text,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Iconos de los documentos de IA guardados; cada uno abre su documento.
class _SavedDocIcons extends StatelessWidget {
  const _SavedDocIcons({
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.availability,
  });

  final StudySourceType sourceType;
  final String sourceId;
  final String title;
  final DocumentAvailability availability;

  @override
  Widget build(BuildContext context) {
    final types = [
      for (final t in const [
        AiDocumentType.summary,
        AiDocumentType.mindMap,
        AiDocumentType.practice,
      ])
        if (availability.has(t)) t,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final type in types)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: context.aiDocumentLabel(type),
            icon: Icon(
              aiDocumentIcon(type),
              color: context.colors.tertiary,
              size: 20,
            ),
            onPressed: () => context.push(
              AcademicPaths.aiDocument(sourceType, sourceId, type, title),
            ),
          ),
      ],
    );
  }
}

enum _SourceAction { assistant, review, practice, delete }

class _SourceMenu extends StatelessWidget {
  const _SourceMenu({required this.onSelected, required this.aiEnabled});

  final ValueChanged<_SourceAction> onSelected;
  final bool aiEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return PopupMenuButton<_SourceAction>(
      tooltip: l10n.academicMoreActions,
      onSelected: onSelected,
      itemBuilder: (_) => [
        if (aiEnabled)
          PopupMenuItem(
            value: _SourceAction.assistant,
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: Text(l10n.academicAiAssistantTitle),
            ),
          ),
        if (aiEnabled)
          PopupMenuItem(
            value: _SourceAction.review,
            child: ListTile(
              leading: const Icon(Icons.replay_rounded),
              title: Text(l10n.academicActionReview),
            ),
          ),
        if (aiEnabled)
          PopupMenuItem(
            value: _SourceAction.practice,
            child: ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: Text(l10n.academicActionPractice),
            ),
          ),
        PopupMenuItem(
          value: _SourceAction.delete,
          child: ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: context.colors.error,
            ),
            title: Text(l10n.commonDelete),
          ),
        ),
      ],
    );
  }
}

Future<void> _handleSourceAction(
  BuildContext context, {
  required _SourceAction action,
  required StudySourceType sourceType,
  required String sourceId,
  required String title,
  required DocumentAvailability availability,
}) async {
  final bloc = context.read<SubjectSyllabusBloc>();
  final l10n = context.localizations;
  switch (action) {
    case _SourceAction.assistant:
      await showAiAssistantSheet(
        context,
        sourceType: sourceType,
        sourceId: sourceId,
        title: title,
        availability: availability,
      );
    case _SourceAction.review || _SourceAction.practice:
      bloc.add(
        SubjectSyllabusEvent.materialRequested(
          sourceType: sourceType,
          sourceId: sourceId,
          practice: action == _SourceAction.practice,
        ),
      );
    case _SourceAction.delete:
      final isNote = sourceType == StudySourceType.note;
      final ok = await confirmDestructive(
        context,
        title: isNote
            ? l10n.academicNoteDeleteTitle
            : l10n.academicFileDeleteTitle,
        message: l10n.academicDeleteMessage(title),
      );
      if (!ok) return;
      bloc.add(
        isNote
            ? SubjectSyllabusEvent.noteDeleted(sourceId)
            : SubjectSyllabusEvent.fileDeleted(sourceId),
      );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.availability,
    required this.onOpen,
  });

  final Note note;
  final DocumentAvailability availability;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final updated = note.updatedAt ?? note.createdAt;
    return AppFocusOutline(
      child: ListTile(
        onTap: onOpen,
        leading: Icon(
          note.quickNote
              ? Icons.sticky_note_2_outlined
              : Icons.description_outlined,
          color: context.colors.tertiary,
        ),
        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Icon(
              context.visibilityIcon(note.visibility),
              size: 14,
              color: context.colors.onSurfaceVariant,
              semanticLabel: context.visibilityLabel(note.visibility),
            ),
            if (updated != null) ...[
              const SizedBox(width: TokensSpacing.xs),
              Text(shortDate(updated)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SavedDocIcons(
              sourceType: StudySourceType.note,
              sourceId: note.id,
              title: note.title,
              availability: availability,
            ),
            _SourceMenu(
              aiEnabled: true,
              onSelected: (action) => _handleSourceAction(
                context,
                action: action,
                sourceType: StudySourceType.note,
                sourceId: note.id,
                title: note.title,
                availability: availability,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.file,
    required this.availability,
    required this.onOpen,
  });

  final SubjectFile file;
  final DocumentAvailability availability;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppFocusOutline(
      child: ListTile(
        onTap: onOpen,
        leading: Icon(fileIcon(file), color: context.colors.tertiary),
        title: Text(
          file.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            fileSize(file.sizeBytes),
            if (file.createdAt != null) shortDate(file.createdAt!),
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SavedDocIcons(
              sourceType: StudySourceType.file,
              sourceId: file.id,
              title: file.fileName,
              availability: availability,
            ),
            _SourceMenu(
              aiEnabled: file.aiReadable,
              onSelected: (action) => _handleSourceAction(
                context,
                action: action,
                sourceType: StudySourceType.file,
                sourceId: file.id,
                title: file.fileName,
                availability: availability,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
