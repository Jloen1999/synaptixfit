import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/exercise_guide.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/exercise_guide_bloc.dart';

/// «Las claves», «Errores comunes» y «Tu nota» de un ejercicio (ADR 0031).
/// Crea su propio [ExerciseGuideBloc]; lo usan la ficha del ejercicio y la
/// hoja «Cómo se hace». Sin consejos, solo se ve la nota.
class ExerciseGuideSection extends StatelessWidget {
  const ExerciseGuideSection({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ExerciseGuideBloc>()
            ..add(ExerciseGuideEvent.started(exerciseId)),
      child: const _GuideView(),
    );
  }
}

class _GuideView extends StatelessWidget with ErrorsMessageMixin {
  const _GuideView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ExerciseGuideBloc, ExerciseGuideState>(
      listenWhen: (a, b) => a.noticeId != b.noticeId && b.notice != null,
      listener: (context, state) {
        final bloc = context.read<ExerciseGuideBloc>();
        switch (state.notice!) {
          case ExerciseGuideNotice.saved:
            context.showSnack(l10n.trainingNoteSaved);
          case ExerciseGuideNotice.deleted:
            final text = state.deletedText;
            if (text == null) {
              context.showSnack(l10n.trainingNoteDeleted);
            } else {
              context.showUndoSnack(
                l10n.trainingNoteDeleted,
                onUndo: () => bloc.add(ExerciseGuideEvent.noteSaved(text)),
                onCommit: () {},
              );
            }
          case ExerciseGuideNotice.failed:
            // Lo escrito se guarda en el estado: «Reintentar» lo vuelve a mandar.
            context.showActionSnack(
              errorMessage(context, state.saveError!),
              actionLabel: l10n.commonRetry,
              onAction: () => bloc.add(const ExerciseGuideEvent.noteRetried()),
            );
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return const Padding(
            padding: EdgeInsets.only(top: TokensSpacing.l),
            child: AppSkeletonGroup(
              child: AppSkeleton(height: TokensSize.guideSkeleton),
            ),
          );
        }
        final tips = state.tips;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tips.keyPoints.isNotEmpty) ...[
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.trainingGuideKeyPoints),
              _TipList(
                lines: tips.keyPoints,
                icon: Icons.check_circle_rounded,
                color: context.palette.success,
              ),
            ],
            if (tips.commonMistakes.isNotEmpty) ...[
              const SizedBox(height: TokensSpacing.m),
              AppSectionHeader(title: l10n.trainingGuideMistakes),
              _TipList(
                lines: tips.commonMistakes,
                icon: Icons.cancel_rounded,
                color: context.colors.error,
              ),
            ],
            const SizedBox(height: TokensSpacing.l),
            AppSectionHeader(title: l10n.trainingNoteTitle),
            _NoteCard(state: state),
          ],
        );
      },
    );
  }
}

/// Lista de frases cortas con un icono que dice si es «hazlo» o «evítalo»
/// (el icono va unido al texto para el lector: una parada por frase).
class _TipList extends StatelessWidget {
  const _TipList({
    required this.lines,
    required this.icon,
    required this.color,
  });

  final List<String> lines;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.s),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, color: color, size: TokensSize.iconS),
                  ),
                  const SizedBox(width: TokensSpacing.s),
                  Expanded(
                    child: Text(line, style: context.textStyles.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.state});

  final ExerciseGuideState state;

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<ExerciseGuideBloc>();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) =>
          _NoteSheet(initial: state.pendingText ?? state.note?.text ?? ''),
    );
    if (text != null && !bloc.isClosed) {
      bloc.add(ExerciseGuideEvent.noteSaved(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final error = state.noteError;
    if (error != null) {
      return AppCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.trainingNoteLoadError,
                style: context.textStyles.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                final id = state.exerciseId;
                if (id != null) {
                  context.read<ExerciseGuideBloc>().add(
                    ExerciseGuideEvent.started(id),
                  );
                }
              },
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    final note = state.note;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            note?.text ?? l10n.trainingNoteHint,
            style: note == null
                ? context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  )
                : context.textStyles.bodyLarge,
          ),
          const SizedBox(height: TokensSpacing.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: state.saving ? null : () => _edit(context),
              icon: state.saving
                  ? const SizedBox.square(
                      dimension: TokensSize.iconS,
                      child: CircularProgressIndicator(
                        strokeWidth: TokensSize.spinnerStroke,
                      ),
                    )
                  : Icon(
                      note == null ? Icons.add_rounded : Icons.edit_outlined,
                    ),
              label: Text(
                note == null ? l10n.trainingNoteAdd : l10n.trainingNoteEdit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja para escribir la nota. Devuelve el texto (vacío: borrarla) o nulo si
/// se cierra sin guardar.
class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.initial});

  final String initial;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TokensSpacing.l,
        0,
        TokensSpacing.l,
        TokensSpacing.l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.trainingNoteTitle,
              style: context.textStyles.titleLarge,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.trainingNoteHint,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          AppTextField(
            label: l10n.trainingNoteFieldLabel,
            hint: l10n.trainingNoteFieldHint,
            controller: _controller,
            maxLines: 4,
            minLines: 2,
            maxLength: ExerciseNote.maxLength,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: TokensSpacing.m),
          AppPrimaryButton(
            label: l10n.trainingNoteSave,
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(_controller.text),
          ),
          if (widget.initial.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.s),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(''),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l10n.trainingNoteDelete),
            ),
          ],
        ],
      ),
    );
  }
}
