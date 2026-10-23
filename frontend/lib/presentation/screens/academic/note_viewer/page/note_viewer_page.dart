import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/ai_assistant_sheet.dart';
import '../bloc/note_viewer_bloc.dart';

/// Visor de un apunte en Markdown.
class NoteViewerPage extends StatelessWidget {
  const NoteViewerPage({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<NoteViewerBloc>()..add(NoteViewerEvent.started(noteId)),
    child: const _NoteViewerView(),
  );
}

class _NoteViewerView extends StatelessWidget with ErrorsMessageMixin {
  const _NoteViewerView();

  Future<void> _edit(BuildContext context, Note note) async {
    final bloc = context.read<NoteViewerBloc>();
    final changed = await context.push<bool>(AcademicPaths.editNote(note.id));
    if (changed ?? false) bloc.add(const NoteViewerEvent.refreshed());
  }

  Future<void> _delete(BuildContext context, Note note) async {
    final l10n = context.localizations;
    final bloc = context.read<NoteViewerBloc>();
    final ok = await confirmDestructive(
      context,
      title: l10n.academicNoteDeleteTitle,
      message: l10n.academicDeleteMessage(note.title),
    );
    if (ok) bloc.add(const NoteViewerEvent.deleteRequested());
  }

  Future<void> _assistant(BuildContext context, NoteViewerState state) async {
    final bloc = context.read<NoteViewerBloc>();
    final note = state.note!;
    await showAiAssistantSheet(
      context,
      sourceType: StudySourceType.note,
      sourceId: note.id,
      title: note.title,
      availability: state.availability,
    );
    bloc.add(const NoteViewerEvent.refreshed());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<NoteViewerBloc, NoteViewerState>(
      listenWhen: (a, b) =>
          a.deleted != b.deleted ||
          a.actionError != b.actionError ||
          a.navigation != b.navigation,
      listener: (context, state) {
        final navigation = state.navigation;
        if (state.deleted) {
          context.showSnack(l10n.academicNoteDeleted);
          context.pop(true);
        } else if (navigation != null) {
          context.push(
            navigation.practice
                ? AcademicPaths.practice(navigation.materialId)
                : AcademicPaths.review(navigation.materialId),
          );
        } else if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        }
      },
      builder: (context, state) {
        final note = state.note;
        if (note == null) {
          return Scaffold(
            appBar: const AppPageBar(),
            body: state.error != null
                ? AppErrorView(
                    error: state.error!,
                    onRetry: () => context.read<NoteViewerBloc>().add(
                      NoteViewerEvent.started(state.noteId),
                    ),
                  )
                : const AppLoadingView(),
          );
        }
        final updated = note.updatedAt ?? note.createdAt;
        return Scaffold(
          appBar: AppPageBar(
            title: Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: l10n.academicAiAssistantTitle,
                icon: Icon(
                  Icons.auto_awesome_rounded,
                  color: context.colors.tertiary,
                ),
                onPressed: () => _assistant(context, state),
              ),
              IconButton(
                tooltip: l10n.commonEdit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(context, note),
              ),
              IconButton(
                tooltip: l10n.commonDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _delete(context, note),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(TokensSpacing.m),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: l10n.academicActionReview,
                      icon: const Icon(Icons.replay_rounded),
                      onPressed: state.busy
                          ? null
                          : () => context.read<NoteViewerBloc>().add(
                              const NoteViewerEvent.materialRequested(
                                practice: false,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: TokensSpacing.s),
                  Expanded(
                    child: AppPrimaryButton(
                      label: l10n.academicActionPractice,
                      icon: Icons.quiz_outlined,
                      onPressed: state.busy
                          ? null
                          : () => context.read<NoteViewerBloc>().add(
                              const NoteViewerEvent.materialRequested(
                                practice: true,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              if (state.busy) const LinearProgressIndicator(),
              Expanded(
                child: AcademicBody(
                  child: ListView(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    children: [
                      Wrap(
                        spacing: TokensSpacing.s,
                        runSpacing: TokensSpacing.xs,
                        children: [
                          AppPill(
                            label: context.visibilityLabel(note.visibility),
                            color: context.colors.onSurfaceVariant,
                            icon: context.visibilityIcon(note.visibility),
                          ),
                          if (note.quickNote)
                            AppPill(
                              label: l10n.academicQuickNote,
                              color: context.palette.accent,
                              icon: Icons.sticky_note_2_outlined,
                            ),
                          if (updated != null)
                            AppPill(
                              label: l10n.academicUpdatedAt(dateTime(updated)),
                              color: context.colors.onSurfaceVariant,
                              icon: Icons.schedule_rounded,
                            ),
                        ],
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      if (note.content.trim().isEmpty)
                        AppEmptyState(
                          icon: Icons.note_alt_outlined,
                          title: l10n.academicNoteEmptyContent,
                          action: AppSecondaryButton(
                            label: l10n.commonEdit,
                            onPressed: () => _edit(context, note),
                          ),
                        )
                      else
                        AcademicMarkdown(data: note.content),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
