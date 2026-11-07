import 'dart:async';

import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/markdown_toolbar.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/models/academic/note_draft.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
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
    this.initialTitle,
  });

  final String? noteId;
  final String? subjectId;
  final bool quickNote;

  /// Título propuesto para un apunte nuevo (p. ej. lo buscado sin resultados).
  final String? initialTitle;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<NoteEditorBloc>()
      ..add(
        NoteEditorEvent.started(
          noteId: noteId,
          accountId: context.read<SessionBloc>().account?.id ?? '',
          subjectId: subjectId,
          quickNote: quickNote,
          profilePrivacy:
              context.read<SessionBloc>().account?.privacy ??
              Visibility.private,
        ),
      ),
    child: _NoteEditorView(isNew: noteId == null, initialTitle: initialTitle),
  );
}

class _NoteEditorView extends StatefulWidget {
  const _NoteEditorView({required this.isNew, this.initialTitle});

  final bool isNew;
  final String? initialTitle;

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

  /// Cada cuánto se guarda el borrador en el teléfono si hay cambios.
  static const _draftInterval = Duration(seconds: 5);
  Timer? _draftTimer;

  /// Lo último que se guardó como borrador (para no repetirlo).
  (String, String, Visibility, bool, String?)? _lastDraft;

  /// Al pasar la app a segundo plano también se guarda: el sistema puede
  /// cerrarla antes del siguiente guardado periódico.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _draftTimer = Timer.periodic(_draftInterval, (_) => _saveDraft());
    _lifecycle = AppLifecycleListener(onHide: _saveDraft, onPause: _saveDraft);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _draftTimer?.cancel();
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _saveDraft() {
    if (!mounted || !_dirty || _current == _lastDraft) return;
    _lastDraft = _current;
    context.read<NoteEditorBloc>().add(
      NoteEditorEvent.draftChanged(
        title: _title.text,
        content: _content.text,
        visibility: _visibility,
        quickNote: _quick,
        subjectId: _subjectId,
      ),
    );
  }

  /// «Recuperar»: el editor pasa a tener lo del borrador (sin guardar aún).
  void _restore(NoteDraft draft, NoteEditorState state) {
    setState(() {
      _title.text = draft.title;
      _content.text = draft.content;
      _visibility = state.allowed(draft.visibility);
      _quick = draft.quickNote;
      _subjectId = draft.subjectId;
      _lastDraft = _current;
    });
    context.read<NoteEditorBloc>().add(const NoteEditorEvent.draftRestored());
  }

  void _fill(NoteEditorState state) {
    if (_filled || state.loading) return;
    _filled = true;
    setState(() {
      final note = state.note;
      _title.text = note?.title ?? widget.initialTitle ?? '';
      _content.text = note?.content ?? '';
      _visibility = state.initialVisibility;
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
      context.read<NoteEditorBloc>().add(
        const NoteEditorEvent.draftDiscarded(),
      );
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
    // Si la privacidad del perfil cambia (p. ej., tras «Cambiar privacidad»), el
    // editor la recibe y vuelve a ofrecer o a rebajar las visibilidades.
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (a, b) =>
          _privacyOf(a) != null && _privacyOf(a) != _privacyOf(b),
      listener: (context, session) => context.read<NoteEditorBloc>().add(
        NoteEditorEvent.profilePrivacyChanged(
          _privacyOf(session) ?? Visibility.private,
        ),
      ),
      child: _editor(context, l10n),
    );
  }

  static Visibility? _privacyOf(SessionState state) => switch (state) {
    SessionAuthenticatedState(:final account) => account.privacy,
    _ => null,
  };

  Widget _editor(BuildContext context, AppLocalizations l10n) {
    return BlocConsumer<NoteEditorBloc, NoteEditorState>(
      listener: (context, state) {
        _fill(state);
        final allowed = state.allowed(_visibility);
        if (_filled && allowed != _visibility) {
          setState(() => _visibility = allowed);
        }
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
                    if (state.recoverableDraft case final draft?) ...[
                      _DraftBanner(
                        draft: draft,
                        onRestore: () => _restore(draft, state),
                        onDiscard: () => context.read<NoteEditorBloc>().add(
                          const NoteEditorEvent.draftDiscarded(),
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.m),
                    ],
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
                      profilePrivacy: state.profilePrivacy,
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
    required this.profilePrivacy,
    required this.quick,
    required this.onSubject,
    required this.onVisibility,
    required this.onQuick,
  });

  final List<(String, String)> subjects;
  final String? subjectId;
  final Visibility visibility;

  /// Privacidad del perfil: las visibilidades mayores salen deshabilitadas.
  final Visibility profilePrivacy;
  final bool quick;
  final ValueChanged<String?> onSubject;
  final ValueChanged<Visibility> onVisibility;
  final ValueChanged<bool> onQuick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final known = subjects.any((s) => s.$1 == subjectId);
    // Por qué hay opciones deshabilitadas: la privacidad del perfil manda.
    final limit = switch (profilePrivacy) {
      Visibility.private => l10n.academicVisibilityLimitPrivate,
      Visibility.friends => l10n.academicVisibilityLimitFriends,
      Visibility.public => null,
    };
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
        // Con texto grande o en francés/portugués las tres opciones no caben en
        // una fila: AppAdaptiveChoice las pasa a una lista.
        AppAdaptiveChoice<Visibility>(
          label: context.localizations.academicNoteVisibilityLabel,
          values: Visibility.values,
          selected: visibility,
          labelOf: context.visibilityLabel,
          iconOf: context.visibilityIcon,
          enabledOf: (v) => v.isAllowedBy(profilePrivacy),
          disabledHint: limit,
          onChanged: onVisibility,
        ),
        const SizedBox(height: TokensSpacing.s),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilterChip(
            avatar: const Icon(
              Icons.sticky_note_2_outlined,
              size: TokensSize.iconXs,
            ),
            label: Text(l10n.academicQuickNote),
            selected: quick,
            onSelected: onQuick,
          ),
        ),
        const SizedBox(height: TokensSpacing.xs),
        // Quién lo verá, dicho con palabras (los iconos solos no lo explican); se
        // anuncia al cambiar de opción.
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.academicVisibilityWho(switch (visibility) {
              Visibility.private => l10n.academicVisibilityWhoPrivate,
              Visibility.friends => l10n.academicVisibilityWhoFriends,
              Visibility.public => l10n.academicVisibilityWhoPublic,
            }),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        if (limit != null)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                limit,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push(AcademicExternalPaths.privacySettings),
                child: Text(l10n.academicVisibilityChangePrivacy),
              ),
            ],
          ),
      ],
    );
  }
}

/// Aviso de borrador sin guardar (la app se cerró mientras se escribía), con
/// «Recuperar» y «Descartar» como botones hermanos.
class _DraftBanner extends StatelessWidget {
  const _DraftBanner({
    required this.draft,
    required this.onRestore,
    required this.onDiscard,
  });

  final NoteDraft draft;
  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Semantics(
      container: true,
      child: AppCard(
        color: context.colors.tertiaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.restore_page_outlined,
                  color: context.colors.onTertiaryContainer,
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.academicNoteDraftFound(dateTime(draft.savedAt)),
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.s),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.s,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.onTertiaryContainer,
                  ),
                  onPressed: onDiscard,
                  child: Text(l10n.academicNoteDraftDiscard),
                ),
                AppSecondaryButton(
                  label: l10n.academicNoteDraftRestore,
                  icon: const Icon(Icons.restore_rounded),
                  onPressed: onRestore,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
