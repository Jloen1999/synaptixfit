import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/ai_document_type.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/models/academic/study_document.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/mind_map_view.dart';
import '../bloc/ai_document_bloc.dart';

/// Resumen, mapa mental o práctica generados por la IA sobre una fuente.
class AiDocumentPage extends StatelessWidget {
  const AiDocumentPage({
    super.key,
    required this.sourceType,
    required this.sourceId,
    required this.type,
    required this.title,
  });

  final StudySourceType sourceType;
  final String sourceId;
  final AiDocumentType type;
  final String title;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<AiDocumentBloc>()
      ..add(
        AiDocumentEvent.started(
          sourceType: sourceType,
          sourceId: sourceId,
          type: type,
        ),
      ),
    child: _AiDocumentView(title: title),
  );
}

class _AiDocumentView extends StatelessWidget with ErrorsMessageMixin {
  const _AiDocumentView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<AiDocumentBloc, AiDocumentState>(
      listenWhen: (a, b) =>
          (a.actionError != b.actionError && b.actionError != null) ||
          (a.savedNoteId != b.savedNoteId && b.savedNoteId != null),
      listener: (context, state) {
        if (state.savedNoteId != null) {
          context.showSnack(l10n.academicAiSavedAsNote);
          context.pushReplacement(AcademicPaths.note(state.savedNoteId!));
          return;
        }
        context.showSnack(errorMessage(context, state.actionError!));
      },
      builder: (context, state) {
        final doc = state.document;
        return Scaffold(
          appBar: AppPageBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.aiDocumentLabel(state.type)),
                if (title.isNotEmpty || doc?.sourceTitle != null)
                  Text(
                    doc?.sourceTitle ?? title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            actions: [
              if (doc != null)
                IconButton(
                  tooltip: l10n.academicAiRegenerate,
                  icon: const Icon(Icons.refresh_rounded),
                  // Se explica antes: la versión actual se sustituye.
                  onPressed: state.regenerating
                      ? null
                      : () async {
                          final bloc = context.read<AiDocumentBloc>();
                          final ok = await showConfirmDialog(
                            context,
                            title: l10n.academicAiRegenerateTitle,
                            message: l10n.academicAiRegenerateMessage,
                            confirmLabel: l10n.academicAiRegenerateConfirm,
                            destructive: false,
                          );
                          if (ok && !bloc.isClosed) {
                            bloc.add(const AiDocumentEvent.regenerated());
                          }
                        },
                ),
            ],
          ),
          body: Column(
            children: [
              if (state.regenerating)
                Semantics(
                  liveRegion: true,
                  label: l10n.academicAiGenerating,
                  child: LinearProgressIndicator(
                    value: context.reduceMotion ? 0.5 : null,
                  ),
                ),
              Expanded(child: _body(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, AiDocumentState state) {
    final l10n = context.localizations;
    if (state.loading) {
      return AppWorkingView(
        icon: AppIcons.proposal,
        title: l10n.academicAiGenerating,
      );
    }
    if (state.error != null) {
      return AppErrorView(
        error: state.error!,
        onRetry: () => context.read<AiDocumentBloc>().add(
          AiDocumentEvent.started(
            sourceType: state.sourceType,
            sourceId: state.sourceId,
            type: state.type,
          ),
        ),
      );
    }
    final doc = state.document!;
    return switch (doc.type) {
      AiDocumentType.mindMap when doc.mindMap != null => Column(
        children: [
          _SavedBanner(doc: doc),
          if (state.canSaveAsNote) _SaveAsNoteRow(state: state, title: title),
          Expanded(child: MindMapView(map: doc.mindMap!)),
        ],
      ),
      AiDocumentType.practice => _PracticeReady(doc: doc),
      _ => AcademicBody(
        child: ListView(
          padding: const EdgeInsets.all(TokensSpacing.m),
          children: [
            _SavedBanner(doc: doc),
            if (state.canSaveAsNote) _SaveAsNoteRow(state: state, title: title),
            const SizedBox(height: TokensSpacing.m),
            AcademicMarkdown(data: doc.markdown ?? ''),
          ],
        ),
      ),
    };
  }
}

/// Lo que genera la IA no se edita aquí (se sobrescribe al regenerar): para
/// corregirlo o guardarlo con los demás apuntes, se copia a un apunte propio.
class _SaveAsNoteRow extends StatelessWidget {
  const _SaveAsNoteRow({required this.state, required this.title});

  final AiDocumentState state;
  final String title;

  Future<void> _save(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<AiDocumentBloc>();
    final doc = state.document!;
    final controller = TextEditingController(
      text: l10n.academicAiNoteTitle(
        context.aiDocumentLabel(doc.type),
        doc.sourceTitle ?? title,
      ),
    );
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.academicAiSaveAsNote),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.academicAiSaveAsNoteHint),
            const SizedBox(height: TokensSpacing.m),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              decoration: InputDecoration(
                labelText: l10n.academicNoteTitleLabel,
              ),
            ),
          ],
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
    if (chosen != null) {
      bloc.add(AiDocumentEvent.saveAsNoteRequested(title: chosen.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.academicAiFixHint,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          AppSecondaryButton(
            label: l10n.academicAiSaveAsNote,
            icon: const Icon(Icons.note_add_outlined),
            loading: state.saving,
            onPressed: () => _save(context),
          ),
        ],
      ),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.doc});

  final StudyDocument doc;

  @override
  Widget build(BuildContext context) {
    final updated = doc.updatedAt;
    return Padding(
      padding: const EdgeInsets.all(TokensSpacing.s),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AppPill(
          label: updated == null
              ? context.localizations.academicAiSaved
              : context.localizations.academicAiSavedAt(dateTime(updated)),
          color: context.palette.success,
          icon: Icons.check_rounded,
        ),
      ),
    );
  }
}

class _PracticeReady extends StatelessWidget {
  const _PracticeReady({required this.doc});

  final StudyDocument doc;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final materialId = doc.materialId;
    return AppEmptyState(
      icon: Icons.quiz_rounded,
      title: l10n.academicAiPracticeReady(doc.questionCount ?? 0),
      message: l10n.academicAiPracticeReadyHint,
      action: materialId == null
          ? null
          : AppPrimaryButton(
              label: l10n.academicPracticeStart,
              icon: Icons.play_arrow_rounded,
              onPressed: () =>
                  context.pushReplacement(AcademicPaths.practice(materialId)),
            ),
    );
  }
}
