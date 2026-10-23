import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/attachment_picker_bloc.dart';

/// Material elegido para una tarea: un apunte o un archivo.
class ChallengeAttachmentSelection {
  const ChallengeAttachmentSelection.note(String this.noteId, this.label)
    : fileId = null;

  const ChallengeAttachmentSelection.file(String this.fileId, this.label)
    : noteId = null;

  final String? noteId;
  final String? fileId;
  final String label;
}

/// Hoja para elegir un apunte o archivo existente de una asignatura.
Future<ChallengeAttachmentSelection?> showAttachmentPickerSheet(
  BuildContext context, {
  String? subjectId,
}) {
  return showModalBottomSheet<ChallengeAttachmentSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<AttachmentPickerBloc>()
            ..add(AttachmentPickerEvent.started(subjectId: subjectId)),
      child: const _AttachmentPickerView(),
    ),
  );
}

class _AttachmentPickerView extends StatelessWidget {
  const _AttachmentPickerView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<AttachmentPickerBloc, AttachmentPickerState>(
      builder: (context, state) {
        final bloc = context.read<AttachmentPickerBloc>();
        final options = state.options;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.l,
              0,
              TokensSpacing.l,
              TokensSpacing.l,
            ),
            children: [
              Text(
                l10n.challengesAttachTitle,
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: TokensSpacing.m),
              DropdownButtonFormField<String?>(
                key: ValueKey(state.subjects.length),
                initialValue: state.subjectId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.challengesFieldSubject,
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                ),
                items: [
                  for (final s in state.subjects)
                    DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    ),
                  DropdownMenuItem<String?>(
                    child: Text(l10n.challengesAttachUnassigned),
                  ),
                ],
                onChanged: (id) =>
                    bloc.add(AttachmentPickerEvent.subjectChanged(id)),
              ),
              const SizedBox(height: TokensSpacing.m),
              ...switch (state.status) {
                AttachmentPickerStatus.loading => const [
                  AppSkeletonGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSkeleton(height: 56),
                        SizedBox(height: TokensSpacing.s),
                        AppSkeleton(height: 56),
                      ],
                    ),
                  ),
                ],
                AttachmentPickerStatus.failure => [
                  AppErrorView(
                    error: state.error!,
                    onRetry: () => bloc.add(
                      AttachmentPickerEvent.subjectChanged(state.subjectId),
                    ),
                  ),
                ],
                AttachmentPickerStatus.ready
                    when options.notes.isEmpty && options.files.isEmpty =>
                  [
                    AppEmptyState(
                      icon: Icons.folder_open_outlined,
                      title: l10n.challengesAttachEmpty,
                    ),
                  ],
                AttachmentPickerStatus.ready => [
                  if (options.notes.isNotEmpty) ...[
                    AppSectionHeader(title: l10n.challengesAttachNotes),
                    for (final n in options.notes)
                      AppFocusOutline(
                        child: ListTile(
                          leading: Icon(
                            Icons.description_outlined,
                            color: context.colors.tertiary,
                          ),
                          title: Text(n.title),
                          onTap: () => Navigator.pop(
                            context,
                            ChallengeAttachmentSelection.note(n.id, n.title),
                          ),
                        ),
                      ),
                  ],
                  if (options.files.isNotEmpty) ...[
                    const SizedBox(height: TokensSpacing.s),
                    AppSectionHeader(title: l10n.challengesAttachFiles),
                    for (final f in options.files)
                      AppFocusOutline(
                        child: ListTile(
                          leading: Icon(
                            Icons.attach_file_rounded,
                            color: context.colors.tertiary,
                          ),
                          title: Text(f.fileName),
                          onTap: () => Navigator.pop(
                            context,
                            ChallengeAttachmentSelection.file(f.id, f.fileName),
                          ),
                        ),
                      ),
                  ],
                ],
              },
            ],
          ),
        );
      },
    );
  }
}
