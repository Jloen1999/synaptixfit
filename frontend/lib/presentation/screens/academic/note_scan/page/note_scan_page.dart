import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/device_permission.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/note_scan.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../profile/permissions/page/permission_request_sheet.dart';
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
    if (ok && context.mounted) {
      context.popOrGo(
        AcademicPaths.subjectOrHome(
          context.read<NoteScanBloc>().state.subjectId,
          notes: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<NoteScanBloc, NoteScanState>(
      listenWhen: (a, b) =>
          a.savedNoteId != b.savedNoteId && b.savedNoteId != null,
      listener: (context, state) {
        context.showSnack(l10n.academicScanSaved);
        context.pushReplacement(AcademicPaths.note(state.savedNoteId!));
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
              leading: AppBackButton(
                fallback: AcademicPaths.subjectOrHome(
                  state.subjectId,
                  notes: true,
                ),
              ),
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
class _PhotosStep extends StatefulWidget {
  const _PhotosStep({required this.state});

  final NoteScanState state;

  @override
  State<_PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<_PhotosStep> with ErrorsMessageMixin {
  final _readFocus = FocusNode();
  final _firstPhotoFocus = FocusNode();

  NoteScanState get state => widget.state;

  @override
  void didUpdateWidget(_PhotosStep old) {
    super.didUpdateWidget(old);
    // El botón «Leer» desaparece mientras se lee: al terminar se le devuelve
    // el foco para que el teclado y el lector no se queden perdidos.
    if (old.state.reading && !state.reading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _readFocus.canRequestFocus) _readFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _readFocus.dispose();
    _firstPhotoFocus.dispose();
    super.dispose();
  }

  Future<void> _camera() async {
    final bloc = context.read<NoteScanBloc>();
    // Antes de abrir la cámara se explica para qué es; sin ella, la galería.
    final permission = await ensureDevicePermission(
      context,
      DevicePermission.camera,
      alternativeLabel: context.localizations.academicScanGallery,
    );
    if (!mounted) return;
    if (permission == PermissionRequestResult.granted) {
      bloc.add(const NoteScanEvent.cameraRetried());
    }
    switch (permission) {
      case PermissionRequestResult.notNow:
        return;
      case PermissionRequestResult.alternative:
        await _gallery();
        return;
      case PermissionRequestResult.granted:
        break;
    }
    try {
      final photo = await takeNotePhoto();
      if (photo != null) bloc.add(NoteScanEvent.photosAdded([photo]));
    } on PhotoCameraUnavailable catch (e) {
      bloc.add(NoteScanEvent.cameraUnavailable(denied: e.denied));
    }
  }

  Future<void> _gallery() async {
    final bloc = context.read<NoteScanBloc>();
    final photos = await pickNotePhotos(limit: state.room);
    if (photos.isNotEmpty) bloc.add(NoteScanEvent.photosAdded(photos));
  }

  void _remove(int index) {
    final bloc = context.read<NoteScanBloc>();
    final photo = state.photos[index];
    bloc.add(NoteScanEvent.photoRemoved(index));
    context.showUndoSnack(
      context.localizations.academicScanPageRemoved(index + 1),
      onUndo: () => bloc.add(NoteScanEvent.photoRestored(index, photo)),
      onCommit: () {},
    );
    // El foco pasa a la primera página que queda.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _firstPhotoFocus.canRequestFocus) {
        _firstPhotoFocus.requestFocus();
      }
    });
  }

  /// Un fallo de red o el lector ocupado se arreglan reintentando; con una
  /// foto ilegible, rara o muy grande, reintentar fallaría igual.
  static bool _retryHelps(AppError error) =>
      error is NetworkError ||
      (error is BusinessError && error.code == 'NOTE_SCAN_UNAVAILABLE');

  void _changePhotos() {
    if (!_firstPhotoFocus.canRequestFocus) return;
    _firstPhotoFocus.requestFocus();
    final focusContext = _firstPhotoFocus.context;
    if (focusContext != null) Scrollable.ensureVisible(focusContext);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<NoteScanBloc>();
    if (state.reading) {
      return AppWorkingView(
        icon: Icons.document_scanner_outlined,
        title: l10n.academicScanReading(state.photos.length),
        hint: l10n.academicScanReadingHint,
      );
    }
    final readError = state.readError;
    final camera = state.cameraProblem;
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
                                color: context.palette.study,
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
                    icon: AppIcons.camera,
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
                          focusNode: i == 0 ? _firstPhotoFocus : null,
                          onRemove: () => _remove(i),
                        ),
                    ],
                  ),
                ],
                if (readError != null) ...[
                  const SizedBox(height: TokensSpacing.m),
                  AppInlineMessage(message: errorMessage(context, readError)),
                  const SizedBox(height: TokensSpacing.xs),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _retryHelps(readError)
                        ? TextButton.icon(
                            onPressed: () =>
                                bloc.add(const NoteScanEvent.readRequested()),
                            icon: const Icon(AppIcons.refresh),
                            label: Text(l10n.commonRetry),
                          )
                        : TextButton.icon(
                            onPressed: _changePhotos,
                            icon: const Icon(AppIcons.gallery),
                            label: Text(l10n.academicScanChangePhotos),
                          ),
                  ),
                ],
                if (camera != null) ...[
                  const SizedBox(height: TokensSpacing.m),
                  AppInlineMessage(
                    tone: AppMessageTone.warning,
                    message: camera == NoteScanCameraProblem.denied
                        ? l10n.academicScanCameraDenied
                        : l10n.academicScanCameraMissing,
                  ),
                  // Sin callejón: la hoja del permiso ofrece «Abrir ajustes del
                  // móvil» y, al volver con el permiso, se sigue con la cámara.
                  if (camera == NoteScanCameraProblem.denied)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: state.canAddMore ? _camera : null,
                        icon: const Icon(AppIcons.settings),
                        label: Text(l10n.profilePermissionOpenSettings),
                      ),
                    ),
                ],
                const SizedBox(height: TokensSpacing.l),
                Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.s,
                  children: [
                    AppSecondaryButton(
                      label: l10n.academicScanCamera,
                      icon: const Icon(AppIcons.camera),
                      // Solo se desactiva si el móvil no tiene cámara: si se
                      // negó el permiso, pulsarla explica cómo darlo.
                      onPressed:
                          state.canAddMore &&
                              camera != NoteScanCameraProblem.missing
                          ? _camera
                          : null,
                    ),
                    AppSecondaryButton(
                      label: l10n.academicScanGallery,
                      icon: const Icon(AppIcons.gallery),
                      onPressed: state.canAddMore ? _gallery : null,
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
                focusNode: _readFocus,
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
    this.focusNode,
  });

  final NotePhotoUpload photo;
  final int page;
  final VoidCallback onRemove;
  final FocusNode? focusNode;

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
              // El número de página ya va debajo, en texto.
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => SizedBox(
                width: TokensSize.medallion,
                height: TokensSize.medallion,
                child: ColoredBox(
                  color: context.colors.surfaceContainerHigh,
                  child: Icon(
                    AppIcons.imageUnavailable,
                    semanticLabel: l10n.academicScanPageUnreadable,
                  ),
                ),
              ),
            ),
          ),
          Text(
            l10n.academicScanPage(page),
            style: context.textStyles.labelMedium,
          ),
          IconButton(
            focusNode: focusNode,
            tooltip: l10n.academicScanRemovePage(page),
            icon: const Icon(AppIcons.remove),
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

class _ReviewStepState extends State<_ReviewStep> with ErrorsMessageMixin {
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

  /// Volver a las fotos descarta el texto: si ya se corrigió, se pregunta.
  Future<void> _backToPhotos() async {
    final bloc = context.read<NoteScanBloc>();
    final l10n = context.localizations;
    final edited =
        _text.text != widget.draft.markdown ||
        (widget.draft.title != null && _title.text != widget.draft.title);
    if (edited) {
      final ok = await confirmDestructive(
        context,
        title: l10n.academicScanBackTitle,
        message: l10n.academicScanBackMessage,
        confirmLabel: l10n.academicScanBackToPhotos,
      );
      if (!ok) return;
    }
    bloc.add(const NoteScanEvent.backToPhotos());
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
                  // Con una lectura dudosa no se dice «Ordenado para ti»: chocaría
                  // con el aviso de abajo.
                  child: widget.draft.tidied && !widget.draft.unclear
                      ? AppPill(
                          label: l10n.academicScanTidied,
                          color: context.palette.success,
                          icon: AppIcons.proposal,
                        )
                      : AppPill(
                          label: l10n.academicScanRaw,
                          color: context.palette.warning,
                          icon: Icons.info_outline_rounded,
                        ),
                ),
                const SizedBox(height: TokensSpacing.s),
                // Con una lectura dudosa, el aviso sustituye a la pista: dice
                // qué hacer (comparar con la foto y completar).
                if (widget.draft.unclear)
                  AppInlineMessage(
                    tone: AppMessageTone.warning,
                    message: l10n.academicScanUnclear,
                  )
                else
                  Text(
                    widget.draft.tidied
                        ? l10n.academicScanTidiedHint
                        : l10n.academicScanRawHint,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                if (state.photos.isNotEmpty) ...[
                  const SizedBox(height: TokensSpacing.m),
                  _ReviewPhotos(photos: state.photos),
                ],
                const SizedBox(height: TokensSpacing.m),
                AppTextField(
                  controller: _title,
                  label: l10n.academicNoteTitleLabel,
                  textInputAction: TextInputAction.next,
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
                    onPressed: _backToPhotos,
                    icon: const Icon(AppIcons.back),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.saveError != null) ...[
                  AppInlineMessage(
                    message: errorMessage(context, state.saveError!),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                ],
                ListenableBuilder(
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Las fotos junto al texto para comparar (ADR 0051): miniaturas que se abren
/// en grande con zoom. Es lo que el servidor leyó, así se ve qué falta.
class _ReviewPhotos extends StatelessWidget {
  const _ReviewPhotos({required this.photos});

  final List<NotePhotoUpload> photos;

  Future<void> _open(BuildContext context, int index) => showDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      child: _PhotoViewer(photos: photos, initial: index),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.academicScanYourPhotos, style: context.textStyles.titleSmall),
        const SizedBox(height: TokensSpacing.xs),
        // Wrap y no una lista horizontal de alto fijo: con el texto grande
        // el número de página no se corta.
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.s,
          children: [
            for (var i = 0; i < photos.length; i++)
              // Un solo botón para el lector (con su acción de tocar) y foco
              // visible con teclado; la tinta se pinta encima de la foto.
              Semantics(
                container: true,
                button: true,
                label: l10n.academicScanZoomPage(i + 1),
                child: AppFocusOutline(
                  borderRadius: BorderRadius.circular(TokensRadius.m),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TokensRadius.m),
                    onTap: () => _open(context, i),
                    child: ExcludeSemantics(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            type: MaterialType.transparency,
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(TokensRadius.m),
                            child: Ink.image(
                              // Miniatura: se descodifica pequeña para no
                              // gastar memoria con fotos de 2400 px.
                              image: ResizeImage(
                                MemoryImage(
                                  Uint8List.fromList(photos[i].bytes),
                                ),
                                width: (TokensSize.medallion * 3).round(),
                              ),
                              width: TokensSize.medallion,
                              height: TokensSize.medallion,
                              fit: BoxFit.cover,
                              onImageError: (_, _) {},
                              child: const SizedBox.shrink(),
                            ),
                          ),
                          Text(
                            l10n.academicScanPage(i + 1),
                            style: context.textStyles.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Las fotos en grande para comparar con el texto: se amplía pellizcando o con
/// «Acercar»/«Alejar» (sin gesto de dos dedos, WCAG 2.5.1) y se pasa de página
/// sin cerrar.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.initial});

  final List<NotePhotoUpload> photos;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  static const _minScale = 1.0;
  static const _maxScale = 5.0;
  static const _step = 1.5;

  late final PageController _pages = PageController(
    initialPage: widget.initial,
  );
  final _zoom = TransformationController();
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    _zoom.dispose();
    super.dispose();
  }

  double get _scale => _zoom.value.getMaxScaleOnAxis();

  /// Acerca o aleja respecto al centro de lo que se ve.
  void _zoomBy(double factor) {
    final target = (_scale * factor).clamp(_minScale, _maxScale);
    final size = context.size ?? Size.zero;
    final cx = size.width / 2;
    final cy = size.height / 2;
    setState(() {
      _zoom.value = Matrix4.translationValues(cx, cy, 0)
        ..multiply(Matrix4.diagonal3Values(target, target, 1))
        ..multiply(Matrix4.translationValues(-cx, -cy, 0));
    });
  }

  void _goTo(int page) => _pages.animateToPage(
    page,
    duration: context.reduceMotion ? Duration.zero : TokensDuration.normal,
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final count = widget.photos.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.academicScanPage(_index + 1)),
        leading: IconButton(
          tooltip: l10n.commonClose,
          icon: const Icon(AppIcons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: l10n.academicScanZoomOut,
            icon: const Icon(AppIcons.zoomOut),
            onPressed: _scale <= _minScale ? null : () => _zoomBy(1 / _step),
          ),
          IconButton(
            tooltip: l10n.academicScanZoomIn,
            icon: const Icon(AppIcons.zoomIn),
            onPressed: _scale >= _maxScale ? null : () => _zoomBy(_step),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: count,
        // Con la foto ampliada, deslizar mueve la foto, no la página.
        physics: _scale > _minScale
            ? const NeverScrollableScrollPhysics()
            : null,
        onPageChanged: (i) => setState(() {
          _index = i;
          _zoom.value = Matrix4.identity();
        }),
        itemBuilder: (context, i) => InteractiveViewer(
          transformationController: i == _index ? _zoom : null,
          minScale: _minScale,
          maxScale: _maxScale,
          onInteractionEnd: (_) => setState(() {}),
          child: Center(
            child: Image.memory(
              Uint8List.fromList(widget.photos[i].bytes),
              fit: BoxFit.contain,
              semanticLabel: l10n.academicScanPage(i + 1),
              errorBuilder: (_, _, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.imageUnavailable,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  Text(
                    l10n.academicScanPageUnreadable,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: count < 2
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(TokensSpacing.s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: l10n.academicScanPrevPage,
                      icon: const Icon(AppIcons.previous),
                      onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                    ),
                    Text(
                      l10n.academicScanPageOf(_index + 1, count),
                      style: context.textStyles.labelLarge,
                    ),
                    IconButton(
                      tooltip: l10n.academicScanNextPage,
                      icon: const Icon(AppIcons.next),
                      onPressed: _index == count - 1
                          ? null
                          : () => _goTo(_index + 1),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
