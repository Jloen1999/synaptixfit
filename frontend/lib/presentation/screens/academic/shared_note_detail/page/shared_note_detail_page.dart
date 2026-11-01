import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/shared_note_card.dart';
import '../bloc/shared_note_detail_bloc.dart';

/// Lectura de un apunte compartido (`/academic/notes/shared/:noteId`): autor
/// pulsable, asignatura del catálogo y «Guardar copia en mis apuntes».
class SharedNoteDetailPage extends StatelessWidget {
  const SharedNoteDetailPage({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<SharedNoteDetailBloc>()
          ..add(SharedNoteDetailEvent.started(noteId)),
    child: const _SharedNoteDetailView(),
  );
}

class _SharedNoteDetailView extends StatelessWidget with ErrorsMessageMixin {
  const _SharedNoteDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SharedNoteDetailBloc, SharedNoteDetailState>(
      listenWhen: (a, b) => a.copyError != b.copyError && b.copyError != null,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.copyError!)),
      builder: (context, state) {
        final note = state.note;
        return Scaffold(
          // El título largo se lee entero en el cuerpo; la barra es genérica.
          appBar: AppPageBar(title: Text(l10n.academicSharedNoteTitle)),
          bottomNavigationBar: note == null
              ? null
              : SafeArea(
                  child: AcademicBody(
                    child: Padding(
                      padding: const EdgeInsets.all(TokensSpacing.m),
                      child: _BottomAction(
                        note: note,
                        copying: state.copying,
                        copiedNoteId: state.copiedNoteId,
                      ),
                    ),
                  ),
                ),
          body: switch (note) {
            null when state.error != null => AppErrorView(
              error: state.error!,
              onRetry: () => context.read<SharedNoteDetailBloc>().add(
                SharedNoteDetailEvent.started(state.noteId),
              ),
            ),
            null => const AcademicBody(child: _DetailSkeleton()),
            final note => AcademicBody(child: _NoteBody(note: note)),
          },
        );
      },
    );
  }
}

/// Esqueleto con la forma del detalle: autor, pastillas y párrafos.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => const AppSkeletonGroup(
    child: Padding(
      padding: EdgeInsets.all(TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(height: TokensSize.iconL),
          SizedBox(height: TokensSpacing.m),
          AppSkeleton(height: TokensLayout.minTouchTarget),
          SizedBox(height: TokensSpacing.s),
          AppSkeleton(height: TokensSize.iconM),
          SizedBox(height: TokensSpacing.l),
          AppSkeleton(height: TokensSize.heroStat),
          SizedBox(height: TokensSpacing.m),
          AppSkeleton(height: TokensSize.heroStat),
        ],
      ),
    ),
  );
}

class _NoteBody extends StatelessWidget {
  const _NoteBody({required this.note});

  final SharedNote note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        Semantics(
          header: true,
          child: Text(note.title, style: context.textStyles.headlineSmall),
        ),
        const SizedBox(height: TokensSpacing.s),
        SharedNoteAuthor(
          authorId: note.authorId,
          authorName: note.authorName,
          authorAvatarUrl: note.authorAvatarUrl,
        ),
        const SizedBox(height: TokensSpacing.s),
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.xs,
          children: [
            if (note.catalogSubjectName case final subject?
                when subject.isNotEmpty)
              AppPill(
                label: subject,
                color: context.colors.tertiary,
                icon: Icons.school_outlined,
              ),
            AppPill(
              label: context.visibilityLabel(note.visibility),
              color: context.colors.onSurfaceVariant,
              icon: context.visibilityIcon(note.visibility),
            ),
            if (note.updatedAt != null)
              AppPill(
                label: l10n.academicUpdatedAt(dateTime(note.updatedAt!)),
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
          )
        else
          AcademicMarkdown(data: note.content),
      ],
    );
  }
}

/// Acción principal: copiar el apunte de otro (y, ya copiado, abrir la copia)
/// o, si es mío, abrirlo en mis apuntes.
class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.note,
    required this.copying,
    required this.copiedNoteId,
  });

  final SharedNote note;
  final bool copying;
  final String? copiedNoteId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    if (note.mine) {
      return AppSecondaryButton(
        label: l10n.academicSharedOpenMine,
        icon: const Icon(Icons.edit_note_rounded),
        onPressed: () => context.push(AcademicPaths.note(note.id)),
      );
    }
    final copy = copiedNoteId;
    // Una vez copiado no se ofrece copiar otra vez (evita duplicados).
    if (copy != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInlineMessage(
            message: l10n.academicSharedCopied,
            tone: AppMessageTone.success,
          ),
          const SizedBox(height: TokensSpacing.s),
          AppSecondaryButton(
            label: l10n.academicSharedOpenCopy,
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => context.push(AcademicPaths.note(copy)),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.academicSharedCopyHint,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppPrimaryButton(
          label: l10n.academicSharedCopy,
          icon: Icons.content_copy_rounded,
          loading: copying,
          onPressed: copying
              ? null
              : () => context.read<SharedNoteDetailBloc>().add(
                  const SharedNoteDetailEvent.copyRequested(),
                ),
        ),
      ],
    );
  }
}
