import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/shared_notes_bloc.dart';

/// Apuntes compartidos por amigos.
class SharedNotesPage extends StatelessWidget {
  const SharedNotesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<SharedNotesBloc>()..add(const SharedNotesEvent.started()),
    child: const _SharedNotesView(),
  );
}

class _SharedNotesView extends StatelessWidget {
  const _SharedNotesView();

  void _open(BuildContext context, SharedNote note) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            0,
            TokensSpacing.m,
            TokensSpacing.xl,
          ),
          children: [
            Text(note.title, style: sheetContext.textStyles.titleLarge),
            const SizedBox(height: TokensSpacing.s),
            Row(
              children: [
                AppAvatar(
                  name: note.authorName,
                  imageUrl: note.authorAvatarUrl,
                  radius: 14,
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(
                    note.authorName,
                    style: sheetContext.textStyles.labelLarge,
                  ),
                ),
              ],
            ),
            const Divider(height: TokensSpacing.l),
            if (note.content.trim().isEmpty)
              Text(sheetContext.localizations.academicNoteEmptyContent)
            else
              AcademicMarkdown(data: note.content),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar(title: Text(l10n.academicSharedNotesTitle)),
      body: BlocBuilder<SharedNotesBloc, SharedNotesState>(
        builder: (context, state) {
          if (state.loading) return const AppSkeletonList(count: 6);
          if (state.error != null) {
            return AppErrorView(
              error: state.error!,
              onRetry: () => context.read<SharedNotesBloc>().add(
                const SharedNotesEvent.started(),
              ),
            );
          }
          if (state.items.isEmpty) {
            return AppEmptyState(
              icon: Icons.people_alt_outlined,
              title: l10n.academicSharedEmptyTitle,
              message: l10n.academicSharedEmptyMessage,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<SharedNotesBloc>().add(
              const SharedNotesEvent.started(),
            ),
            child: AcademicBody(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 300) {
                    context.read<SharedNotesBloc>().add(
                      const SharedNotesEvent.moreRequested(),
                    );
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  itemCount: state.items.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: TokensSpacing.s),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(TokensSpacing.m),
                        child: AppLoadingView(),
                      );
                    }
                    final note = state.items[index];
                    return AppCard(
                      onTap: () => _open(context, note),
                      child: Row(
                        children: [
                          AppAvatar(
                            name: note.authorName,
                            imageUrl: note.authorAvatarUrl,
                          ),
                          const SizedBox(width: TokensSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textStyles.titleSmall,
                                ),
                                Text(
                                  [
                                    note.authorName,
                                    if (note.updatedAt != null)
                                      shortDate(note.updatedAt!),
                                  ].join(' · '),
                                  style: context.textStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            context.visibilityIcon(note.visibility),
                            size: 18,
                            color: context.colors.onSurfaceVariant,
                            semanticLabel: context.visibilityLabel(
                              note.visibility,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
