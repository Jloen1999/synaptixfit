import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/note_scan.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/note_photo_pick.dart';
import '../bloc/note_scan_bloc.dart';

/// Fotografiar apuntes en papel: paso 1, las fotos; paso 2, revisar el texto
/// leído y guardarlo como apunte. Nada se guarda sin revisarlo antes.
class NoteScanPage extends StatelessWidget {
  const NoteScanPage({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<NoteScanBloc>()..add(NoteScanEvent.started(subjectId: subjectId)),
    child: const _NoteScanView(),
  );
}

class _NoteScanView extends StatelessWidget with ErrorsMessageMixin {
  const _NoteScanView();

  /// Salir con fotos o texto sin guardar pierde el trabajo: se pregunta.
  Future<void> _leave(BuildContext context) async {
    final l10n = context.localizations;
    final ok = await confirmDestructive(
      context,
      title: l10n.academicScanLeaveTitle,
      message: l10n.academicScanLeaveMessage,
      confirmLabel: l10n.academicScanLeaveConfirm,
    );
    if (ok && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<NoteScanBloc, NoteScanState>(
      listenWhen: (a, b) =>
          (a.savedNoteId != b.savedNoteId && b.savedNoteId != null) ||
          (a.saveError != b.saveError && b.saveError != null),
      listener: (context, state) {
        if (state.savedNoteId != null) {
          context.showSnack(l10n.academicScanSaved);
          context.pushReplacement(AcademicPaths.note(state.savedNoteId!));
        } else {
          context.showSnack(errorMessage(context, state.saveError!));
        }
      },
      builder: (context, state) {
        final dirty = state.photos.isNotEmpty && state.savedNoteId == null;
        return PopScope(
          canPop: !dirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave(context);
          },
          child: Scaffold(
            appBar: AppPageBar(
              title: Text(
                state.draft == null
                    ? l10n.academicScanTitle
                    : l10n.academicScanReviewTitle,
              ),
            ),
            body: state.draft == null
                ? _PhotosStep(state: state)
                : _ReviewStep(
                    key: ValueKey(state.draft),
                    state: state,
                    draft: state.draft!,
                  ),
          ),
        );
      },
    );
  }
}

/// Paso 1: hacer o elegir las fotos de las páginas y mandarlas a leer.
class _PhotosStep extends StatelessWidget with ErrorsMessageMixin {
  const _PhotosStep({required this.state});

  final NoteScanState state;

  Future<void> _camera(BuildContext context) async {
    final bloc = context.read<NoteScanBloc>();
    final photo = await takeNotePhoto();
    if (photo != null) bloc.add(NoteScanEvent.photosAdded([photo]));
  }

  Future<void> _gallery(BuildContext context) async {
    final bloc = context.read<NoteScanBloc>();
    final photos = await pickNotePhotos(limit: state.room);
    if (photos.isNotEmpty) bloc.add(NoteScanEvent.photosAdded(photos));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<NoteScanBloc>();
    if (state.reading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TokensSpacing.xl),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.document_scanner_outlined,
                  size: TokensSize.iconXl,
                  color: context.colors.tertiary,
                ),
                const SizedBox(height: TokensSpacing.m),
                const SizedBox(
                  width: TokensSize.medallion * 2,
                  child: LinearProgressIndicator(),
                ),
                const SizedBox(height: TokensSpacing.m),
                Text(
                  l10n.academicScanReading(state.photos.length),
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  l10n.academicScanReadingHint,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: AcademicBody(
            child: ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                Text(
                  l10n.academicScanIntro,
                  style: context.textStyles.bodyLarge,
                ),
                const SizedBox(height: TokensSpacing.m),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (icon, tip) in [
                        (Icons.wb_sunny_outlined, l10n.academicScanTipLight),
                        (Icons.crop_free_rounded, l10n.academicScanTipWhole),
                        (
                          Icons.edit_note_rounded,
                          l10n.academicScanTipHandwriting,
                        ),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: TokensSpacing.xs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                icon,
                                size: TokensSize.iconS,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: TokensSpacing.s),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: TokensSpacing.l),
                if (state.photos.isEmpty)
                  AppEmptyState(
                    icon: Icons.photo_camera_outlined,
                    title: l10n.academicScanEmptyTitle,
                    message: l10n.academicScanEmptyMessage,
                  )
                else ...[
                  AppSectionHeader(
                    title: l10n.academicScanPhotos(
                      state.photos.length,
                      NoteScanState.maxPhotos,
                    ),
                  ),
                  Wrap(
                    spacing: TokensSpacing.s,
                    runSpacing: TokensSpacing.s,
                    children: [
                      for (final (i, photo) in state.photos.indexed)
                        _PhotoThumb(
                          photo: photo,
                          page: i + 1,
                          onRemove: () =>
                              bloc.add(NoteScanEvent.photoRemoved(i)),
                        ),
                    ],
                  ),
                ],
                if (state.readError != null) ...[
                  const SizedBox(height: TokensSpacing.m),
                  AppErrorView(
                    error: state.readError!,
                    onRetry: () =>
                        bloc.add(const NoteScanEvent.readRequested()),
                  ),
                ],
                const SizedBox(height: TokensSpacing.l),
                Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.s,
                  children: [
                    AppSecondaryButton(
                      label: l10n.academicScanCamera,
                      icon: const Icon(Icons.photo_camera_rounded),
                      onPressed: state.canAddMore
                          ? () => _camera(context)
                          : null,
                    ),
                    AppSecondaryButton(
                      label: l10n.academicScanGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: state.canAddMore
                          ? () => _gallery(context)
                          : null,
                    ),
                  ],
                ),
                if (!state.canAddMore) ...[
                  const SizedBox(height: TokensSpacing.xs),
                  Text(
                    l10n.academicScanFull(NoteScanState.maxPhotos),
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (state.photos.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(TokensSpacing.m),
              child: AppPrimaryButton(
                label: l10n.academicScanRead(state.photos.length),
                icon: Icons.document_scanner_rounded,
                onPressed: () => bloc.add(const NoteScanEvent.readRequested()),
              ),
            ),
          ),
      ],
    );
  }
}

/// Miniatura de una página con su número y «Quitar».
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.photo,
    required this.page,
    required this.onRemove,
  });

  final NotePhotoUpload photo;
  final int page;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return SizedBox(
      width: TokensSize.medallion,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensRadius.m),
            child: Image.memory(
              Uint8List.fromList(photo.bytes),
              width: TokensSize.medallion,
              height: TokensSize.medallion,
              fit: BoxFit.cover,
              semanticLabel: l10n.academicScanPage(page),
              errorBuilder: (_, _, _) => SizedBox(
                width: TokensSize.medallion,
                height: TokensSize.medallion,
                child: ColoredBox(
                  color: context.colors.surfaceContainerHigh,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
          Text(
            l10n.academicScanPage(page),
            style: context.textStyles.labelMedium,
          ),
          IconButton(
            tooltip: l10n.academicScanRemovePage(page),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Paso 2: revisar el texto leído, ponerle título y asignatura, y guardar.
class _ReviewStep extends StatefulWidget {
  const _ReviewStep({super.key, required this.state, required this.draft});

  final NoteScanState state;
  final ScannedNoteDraft draft;

  @override
  State<_ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<_ReviewStep> {
  late final TextEditingController _title;
  late final _text = TextEditingController(text: widget.draft.markdown);

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.draft.title ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_title.text.isEmpty) {
      _title.text = context.localizations.academicScanDefaultTitle;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<NoteScanBloc>();
    final state = widget.state;
    final subjects = state.subjects;
    final known = subjects.any((s) => s.id == state.subjectId);
    return Column(
      children: [
        Expanded(
          child: AcademicBody(
            child: ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: widget.draft.tidied
                      ? AppPill(
                          label: l10n.academicScanTidied,
                          color: context.palette.success,
                          icon: Icons.auto_awesome_rounded,
                        )
                      : AppPill(
                          label: l10n.academicScanRaw,
                          color: context.palette.warning,
                          icon: Icons.info_outline_rounded,
                        ),
                ),
                const SizedBox(height: TokensSpacing.s),
                Text(
                  widget.draft.tidied
                      ? l10n.academicScanTidiedHint
                      : l10n.academicScanRawHint,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
                TextField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.academicNoteTitleLabel,
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
                DropdownButtonFormField<String?>(
                  initialValue: known ? state.subjectId : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.academicNoteSubject,
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                  items: [
                    DropdownMenuItem(child: Text(l10n.academicNoteNoSubject)),
                    for (final s in subjects)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => bloc.add(NoteScanEvent.subjectChanged(v)),
                ),
                const SizedBox(height: TokensSpacing.m),
                TextField(
                  controller: _text,
                  minLines: 12,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    labelText: l10n.academicScanTextLabel,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () =>
                        bloc.add(const NoteScanEvent.backToPhotos()),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(l10n.academicScanBackToPhotos),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(TokensSpacing.m),
            child: ListenableBuilder(
              listenable: Listenable.merge([_title, _text]),
              builder: (context, _) => AppPrimaryButton(
                label: l10n.academicScanSave,
                icon: Icons.check_rounded,
                loading: state.saving,
                onPressed:
                    _title.text.trim().isEmpty || _text.text.trim().isEmpty
                    ? null
                    : () => bloc.add(
                        NoteScanEvent.saveRequested(
                          title: _title.text,
                          markdown: _text.text,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
