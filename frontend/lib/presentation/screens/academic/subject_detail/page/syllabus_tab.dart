import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/enums/ai_document_type.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/study_document.dart';
import '../../../../../domain/models/academic/subject_material.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../material_share/bloc/material_share_bloc.dart';
import '../../material_share/page/material_share_sheet.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/ai_assistant_sheet.dart';
import '../../widgets/file_pick.dart';
import '../../widgets/material_tile.dart';
import '../bloc/subject_detail_bloc.dart';
import '../bloc/subject_progress_bloc.dart';
import '../bloc/subject_syllabus_bloc.dart';

/// Pestaña Apuntes: una sola lista «Material» con apuntes y archivos juntos
/// (ADR 0064). Cada fila dice qué es, se abre con un toque y lleva «Acciones»
/// (repasar, practicar, la ayuda de la IA, compartir, descargar y eliminar).
class SyllabusTab extends StatelessWidget with ErrorsMessageMixin {
  const SyllabusTab({super.key});

  /// Abre una ruta y, al volver, recarga la lista y la cabecera (recuentos).
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

  String _route(SubjectMaterial material) => switch (material) {
    NoteMaterial(:final note) => AcademicPaths.note(note.id),
    FileMaterial(:final file) => AcademicPaths.file(file.id),
  };

  Future<void> _actions(
    BuildContext context,
    SubjectMaterial material,
    DocumentAvailability availability,
  ) async {
    final syllabus = context.read<SubjectSyllabusBloc>();
    final share = context.read<MaterialShareBloc>();
    final action = await showMaterialActionsSheet(context, material);
    if (action == null || !context.mounted) return;
    switch (action) {
      case MaterialAction.open:
        await _openAndRefresh(context, _route(material));
      case MaterialAction.review || MaterialAction.practice:
        syllabus.add(
          SubjectSyllabusEvent.materialRequested(
            sourceType: material.sourceType,
            sourceId: material.id,
            practice: action == MaterialAction.practice,
          ),
        );
      case MaterialAction.assistant:
        await showAiAssistantSheet(
          context,
          sourceType: material.sourceType,
          sourceId: material.id,
          title: material.title,
          availability: availability,
        );
        syllabus.add(const SubjectSyllabusEvent.refreshed());
      case MaterialAction.share:
        await showMaterialShareSheet(context, material);
      case MaterialAction.download:
        share.add(MaterialShareEvent.downloadRequested(material));
      case MaterialAction.delete:
        await _delete(context, material);
    }
  }

  Future<void> _delete(BuildContext context, SubjectMaterial material) async {
    final l10n = context.localizations;
    final bloc = context.read<SubjectSyllabusBloc>();
    final isNote = material is NoteMaterial;
    final ok = await confirmDestructive(
      context,
      title: isNote ? l10n.academicNoteDeleteTitle : l10n.academicFileDeleteTitle,
      message: l10n.academicDeleteMessage(material.title),
    );
    if (!ok || bloc.isClosed) return;
    bloc.add(
      isNote
          ? SubjectSyllabusEvent.noteDeleted(material.id)
          : SubjectSyllabusEvent.fileDeleted(material.id),
    );
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
        final materials = state.materials;
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
                Semantics(
                  header: true,
                  child: Text(
                    l10n.academicMaterialTitle(materials.length),
                    style: context.textStyles.titleMedium,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
                // Las tres formas de añadir, como botones con borde y en un
                // Wrap: con el texto grande bajan de línea en vez de cortarse.
                Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.s,
                  children: [
                    AppSecondaryButton(
                      label: l10n.academicNoteNew,
                      icon: const Icon(AppIcons.add),
                      onPressed: () => _openAndRefresh(
                        context,
                        AcademicPaths.newNote(subjectId: state.subjectId),
                      ),
                    ),
                    Semantics(
                      label: l10n.academicScanEntrySemantics,
                      button: true,
                      excludeSemantics: true,
                      // Excluye al botón: el lector pulsa este nodo.
                      onTap: () => _openAndRefresh(
                        context,
                        AcademicPaths.scanNote(subjectId: state.subjectId),
                      ),
                      child: AppSecondaryButton(
                        label: l10n.academicScanEntry,
                        icon: const Icon(AppIcons.camera),
                        onPressed: () => _openAndRefresh(
                          context,
                          AcademicPaths.scanNote(subjectId: state.subjectId),
                        ),
                      ),
                    ),
                    AppSecondaryButton(
                      label: l10n.academicFileUpload,
                      icon: const Icon(AppIcons.upload),
                      onPressed: state.uploading ? null : () => _upload(context),
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
                const SizedBox(height: TokensSpacing.m),
                if (materials.isEmpty)
                  AppEmptyState(
                    icon: AppIcons.folderEmpty,
                    title: l10n.academicMaterialEmptyTitle,
                    message: l10n.academicMaterialEmptyBody,
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, material) in materials.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          MaterialTile(
                            material: material,
                            availability:
                                state.availability[material.id] ??
                                DocumentAvailability.none,
                            onOpen: () =>
                                _openAndRefresh(context, _route(material)),
                            onActions: () => _actions(
                              context,
                              material,
                              state.availability[material.id] ??
                                  DocumentAvailability.none,
                            ),
                            onOpenDocument: (type) => _openDocument(
                              context,
                              material,
                              type,
                            ),
                          ),
                        ],
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

  void _openDocument(
    BuildContext context,
    SubjectMaterial material,
    AiDocumentType type,
  ) => context.push(
    AcademicPaths.aiDocument(
      material.sourceType,
      material.id,
      type,
      material.title,
    ),
  );
}

class _GenerateBanner extends StatelessWidget {
  const _GenerateBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      onTap: onTap,
      color: context.colors.tertiaryContainer,
      child: Row(
        children: [
          Icon(AppIcons.proposal, color: context.colors.tertiary),
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
          const Icon(AppIcons.next),
        ],
      ),
    );
  }
}
