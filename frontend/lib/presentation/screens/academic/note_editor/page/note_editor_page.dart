import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/markdown_toolbar.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/note_editor_bloc.dart';

/// Editor Markdown con vista previa, visibilidad y nota rápida.
class NoteEditorPage extends StatelessWidget {
  const NoteEditorPage({
    super.key,
    this.noteId,
    this.subjectId,
    this.quickNote = false,
  });

  final String? noteId;
  final String? subjectId;
  final bool quickNote;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<NoteEditorBloc>()
      ..add(
        NoteEditorEvent.started(
          noteId: noteId,
          subjectId: subjectId,
          quickNote: quickNote,
        ),
      ),
    child: _NoteEditorView(isNew: noteId == null),
  );
}

class _NoteEditorView extends StatefulWidget {
  const _NoteEditorView({required this.isNew});

  final bool isNew;

  @override
  State<_NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<_NoteEditorView>
    with ErrorsMessageMixin {
  final _title = TextEditingController();
  final _content = TextEditingController();
  Visibility _visibility = Visibility.private;
  bool _quick = false;
  String? _subjectId;
  bool _filled = false;
  bool _preview = false;

  /// Lo que había al abrir: si cambia, salir pregunta antes de descartar.
  (String, String, Visibility, bool, String?)? _initial;

  (String, String, Visibility, bool, String?) get _current =>
      (_title.text, _content.text, _visibility, _quick, _subjectId);

  bool get _dirty => _initial != null && _current != _initial;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _fill(NoteEditorState state) {
    if (_filled || state.loading) return;
    _filled = true;
    setState(() {
      final note = state.note;
      _title.text = note?.title ?? '';
      _content.text = note?.content ?? '';
      _visibility = note?.visibility ?? Visibility.private;
      _quick = state.initialQuickNote;
      _subjectId = state.initialSubjectId;
      _initial = _current;
    });
  }

  /// Volver con cambios sin guardar pregunta antes (antes se perdía todo).
  Future<void> _leave() async {
    final l10n = context.localizations;
    final ok = await confirmDestructive(
      context,
      title: l10n.academicNoteDiscardTitle,
      message: l10n.academicNoteDiscardMessage,
      confirmLabel: l10n.academicNoteDiscard,
    );
    if (ok && mounted) {
      _initial = _current;
      context.pop();
    }
  }

  void _save() {
    // Sin título se pone uno con la fecha: una nota rápida no debe exigirlo.
    final title = _title.text.trim().isEmpty
        ? context.localizations.academicNoteDefaultTitle(
            shortDate(DateTime.now()),
          )
        : _title.text.trim();
    context.read<NoteEditorBloc>().add(
      NoteEditorEvent.submitted(
        title: title,
        content: _content.text,
        visibility: _visibility,
        quickNote: _quick,
        subjectId: _subjectId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<NoteEditorBloc, NoteEditorState>(
      listener: (context, state) {
        _fill(state);
        if (state.savedNoteId != null) {
          context.showSnack(l10n.academicNoteSaved);
          if (widget.isNew) {
            context.pushReplacement(AcademicPaths.note(state.savedNoteId!));
          } else {
            context.pop(true);
          }
        } else if (state.saveError != null) {
          context.showSnack(errorMessage(context, state.saveError!));
        }
      },
      builder: (context, state) {
        return PopScope(
          // Los campos no reconstruyen la página al escribir: se decide al salir.
          canPop: state.savedNoteId != null,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _dirty ? _leave() : context.pop();
          },
          child: Scaffold(
            appBar: AppPageBar(
              title: Text(
                widget.isNew ? l10n.academicNoteNew : l10n.academicNoteEdit,
              ),
              actions: [
                IconButton(
                  tooltip: _preview
                      ? l10n.academicNoteEditMode
                      : l10n.academicNotePreview,
                  icon: Icon(
                    _preview ? Icons.edit_outlined : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _preview = !_preview),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: TokensSpacing.s),
                  // Mientras guarda anuncia «Guardar, Cargando».
                  child: AppPrimaryButton(
                    label: l10n.commonSave,
                    loading: state.saving,
                    onPressed: state.loading ? null : _save,
                  ),
                ),
              ],
            ),
            body: switch (state) {
              NoteEditorState(loading: true) => const AppLoadingView(),
              NoteEditorState(:final loadError?) => AppErrorView(
                error: loadError,
                onRetry: () => context.pop(),
              ),
              _ => AcademicBody(
                child: ListView(
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  children: [
                    TextField(
                      controller: _title,
                      style: context.textStyles.titleLarge,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.academicNoteTitleLabel,
                        helperText: l10n.academicNoteTitleHelper(
                          l10n.academicNoteDefaultTitle(
                            shortDate(DateTime.now()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    _MetaRow(
                      subjects: [
                        for (final s in state.subjects) (s.id, s.name),
                      ],
                      subjectId: _subjectId,
                      visibility: _visibility,
                      quick: _quick,
                      onSubject: (v) => setState(() => _subjectId = v),
                      onVisibility: (v) => setState(() => _visibility = v),
                      onQuick: (v) => setState(() => _quick = v),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    if (_preview)
                      AppCard(
                        child: _content.text.trim().isEmpty
                            ? Text(l10n.academicNoteEmptyContent)
                            : AcademicMarkdown(data: _content.text),
                      )
                    else ...[
                      // Formato sin saber Markdown: la barra lo escribe por ti.
                      MarkdownToolbar(controller: _content),
                      const SizedBox(height: TokensSpacing.s),
                      MarkdownShortcuts(
                        controller: _content,
                        child: TextField(
                          controller: _content,
                          minLines: 14,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            labelText: l10n.academicNoteContentHint,
                            hintText: l10n.academicNoteContentPlaceholder,
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            },
          ),
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.subjects,
    required this.subjectId,
    required this.visibility,
    required this.quick,
    required this.onSubject,
    required this.onVisibility,
    required this.onQuick,
  });

  final List<(String, String)> subjects;
  final String? subjectId;
  final Visibility visibility;
  final bool quick;
  final ValueChanged<String?> onSubject;
  final ValueChanged<Visibility> onVisibility;
  final ValueChanged<bool> onQuick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final known = subjects.any((s) => s.$1 == subjectId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: known ? subjectId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.academicNoteSubject,
            prefixIcon: const Icon(Icons.school_outlined),
          ),
          items: [
            DropdownMenuItem(child: Text(l10n.academicNoteNoSubject)),
            for (final (id, name) in subjects)
              DropdownMenuItem(
                value: id,
                child: Text(name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onSubject,
        ),
        const SizedBox(height: TokensSpacing.m),
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<Visibility>(
              showSelectedIcon: false,
              segments: [
                for (final v in Visibility.values)
                  ButtonSegment(
                    value: v,
                    icon: Icon(context.visibilityIcon(v)),
                    label: Text(context.visibilityLabel(v)),
                  ),
              ],
              selected: {visibility},
              onSelectionChanged: (s) => onVisibility(s.first),
            ),
            FilterChip(
              avatar: const Icon(
                Icons.sticky_note_2_outlined,
                size: TokensSize.iconXs,
              ),
              label: Text(l10n.academicQuickNote),
              selected: quick,
              onSelected: onQuick,
            ),
          ],
        ),
      ],
    );
  }
}
