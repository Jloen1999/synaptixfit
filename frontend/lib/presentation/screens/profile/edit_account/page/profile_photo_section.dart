import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/enums/device_permission.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/photo_pick.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../permissions/page/permission_request_sheet.dart';
import '../bloc/profile_photo_bloc.dart';

/// Lado con el que se manda la foto: el servidor la deja en 512 px (ADR 0052);
/// el doble deja margen para recortar sin perder nitidez y pesa poco.
const _maxSide = 1024.0;
const _quality = 90;

/// Radio del avatar: el del icono más grande del tema, para que destaque
/// sin ocupar media pantalla.
const _avatarRadius = TokensSize.iconXl;

/// La vista previa es mayor que el avatar para poder juzgar el recorte.
const _previewSize = TokensSize.medallion * 2;

/// Origen elegido en la hoja «Foto de perfil».
enum _PhotoAction { gallery, camera, remove }

/// Foto de perfil de «Editar cuenta»: el avatar es el botón «Cambiar foto»;
/// la foto elegida se ve antes en un círculo (el mismo cuadrado central que
/// recorta el servidor) con «Usar esta foto» y «Elegir otra». Al aparecer o
/// desaparecer la vista previa, el foco pasa al control nuevo (WCAG 2.4.3).
class ProfilePhotoSection extends StatefulWidget {
  const ProfilePhotoSection({super.key, required this.name});

  /// Nombre para las iniciales cuando no hay foto.
  final String name;

  @override
  State<ProfilePhotoSection> createState() => _ProfilePhotoSectionState();
}

class _ProfilePhotoSectionState extends State<ProfilePhotoSection>
    with ErrorsMessageMixin {
  final _avatarFocus = FocusNode();
  final _useFocus = FocusNode();

  @override
  void dispose() {
    _avatarFocus.dispose();
    _useFocus.dispose();
    super.dispose();
  }

  Future<void> _choose({required bool hasPhoto}) async {
    final l10n = context.localizations;
    // Sin cámara ni foto que quitar, la hoja tendría una sola opción.
    if (!canTakePhotos && !hasPhoto) return _gallery();
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.profilePhotoSheetTitle,
                  style: sheetContext.textStyles.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: TokensSpacing.xs),
            AppFocusOutline(
              child: ListTile(
                leading: const Icon(AppIcons.gallery),
                title: Text(l10n.profilePhotoGallery),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoAction.gallery),
              ),
            ),
            if (canTakePhotos)
              AppFocusOutline(
                child: ListTile(
                  leading: const Icon(AppIcons.camera),
                  title: Text(l10n.profilePhotoCamera),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_PhotoAction.camera),
                ),
              ),
            if (hasPhoto)
              AppFocusOutline(
                child: ListTile(
                  // El color de la acción destructiva lo pone la propia fila.
                  iconColor: context.colors.error,
                  textColor: context.colors.error,
                  leading: const Icon(AppIcons.delete),
                  title: Text(l10n.profilePhotoRemove),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_PhotoAction.remove),
                ),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _PhotoAction.gallery:
        await _gallery();
      case _PhotoAction.camera:
        await _camera();
      case _PhotoAction.remove:
        await _remove();
    }
  }

  Future<void> _gallery() async {
    final bloc = context.read<ProfilePhotoBloc>();
    final photos = await pickPhotos(
      limit: 1,
      maxSide: _maxSide,
      quality: _quality,
    );
    if (photos.isNotEmpty) bloc.add(ProfilePhotoEvent.picked(photos.first));
  }

  Future<void> _camera() async {
    final bloc = context.read<ProfilePhotoBloc>();
    final l10n = context.localizations;
    // Antes de abrir la cámara se explica para qué es; sin ella, la galería.
    final permission = await ensureDevicePermission(
      context,
      DevicePermission.camera,
      alternativeLabel: l10n.profilePhotoGallery,
    );
    if (!mounted) return;
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
      final photo = await takePhoto(
        maxSide: _maxSide,
        quality: _quality,
        frontCamera: true,
      );
      if (photo != null) bloc.add(ProfilePhotoEvent.picked(photo));
    } on PhotoCameraUnavailable {
      if (mounted) context.showSnack(l10n.profilePhotoCameraUnavailable);
    }
  }

  Future<void> _remove() async {
    final bloc = context.read<ProfilePhotoBloc>();
    final l10n = context.localizations;
    final ok = await showConfirmDialog(
      context,
      title: l10n.profilePhotoRemoveTitle,
      message: l10n.profilePhotoRemoveMessage,
      confirmLabel: l10n.profilePhotoRemove,
    );
    if (ok) bloc.add(const ProfilePhotoEvent.removeRequested());
  }

  void _onChange(BuildContext context, ProfilePhotoState state) {
    final account = state.account;
    if (account != null) {
      context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfilePhotoBloc, ProfilePhotoState>(
          listenWhen: (a, b) => a.account != b.account && b.account != null,
          listener: (context, state) {
            _onChange(context, state);
            context.showSnack(
              state.outcome == ProfilePhotoOutcome.removed
                  ? l10n.profilePhotoRemoved
                  : l10n.profilePhotoSaved,
            );
          },
        ),
        // El control pulsado desaparece al cambiar de vista: el foco va al
        // que aparece (vista previa → «Usar esta foto»; vuelta → el avatar).
        BlocListener<ProfilePhotoBloc, ProfilePhotoState>(
          listenWhen: (a, b) => (a.preview == null) != (b.preview == null),
          listener: (context, state) => AppFocusAnchor.focusSoon(
            state.preview != null ? _useFocus : _avatarFocus,
          ),
        ),
      ],
      child: BlocBuilder<ProfilePhotoBloc, ProfilePhotoState>(
        builder: (context, state) {
          final preview = state.preview;
          // Tras un cambio guardado manda la cuenta nueva (también al quitar).
          final avatarUrl = state.account != null
              ? state.account!.avatarUrl
              : context.read<SessionBloc>().account?.avatarUrl;
          final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
          final error = state.error;
          return Column(
            children: [
              if (preview != null)
                _Preview(
                  photo: preview,
                  saving: state.saving,
                  focusNode: _useFocus,
                )
              else
                _AvatarButton(
                  name: widget.name,
                  avatarUrl: avatarUrl,
                  label: hasPhoto
                      ? l10n.profilePhotoChange
                      : l10n.profilePhotoAdd,
                  busy: state.saving,
                  focusNode: _avatarFocus,
                  onTap: () => _choose(hasPhoto: hasPhoto),
                ),
              if (error != null) ...[
                const SizedBox(height: TokensSpacing.s),
                AppInlineMessage(message: errorMessage(context, error)),
              ],
              if (preview != null)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.s,
                  children: [
                    TextButton.icon(
                      onPressed: state.saving
                          ? null
                          : () => _choose(hasPhoto: false),
                      icon: const Icon(AppIcons.gallery),
                      label: Text(l10n.profilePhotoPickAnother),
                    ),
                    TextButton(
                      onPressed: state.saving
                          ? null
                          : () => context.read<ProfilePhotoBloc>().add(
                              const ProfilePhotoEvent.discarded(),
                            ),
                      child: Text(l10n.commonCancel),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// El avatar actual con su texto debajo: un solo botón para el lector. La
/// etiqueta envuelve el `InkWell` y solo se excluye el contenido, para que en
/// la web conserve la acción y el foco (regla 5 de `accessibility.md`).
class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.name,
    required this.avatarUrl,
    required this.label,
    required this.busy,
    required this.focusNode,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final String label;
  final bool busy;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: !busy,
      label: label,
      value: busy ? context.localizations.commonLoading : null,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InkWell(
          focusNode: focusNode,
          borderRadius: BorderRadius.circular(TokensRadius.m),
          onTap: busy ? null : onTap,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(TokensSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AppAvatar(
                        name: name.isEmpty ? '?' : name,
                        imageUrl: avatarUrl,
                        radius: _avatarRadius,
                      ),
                      // Fondo liso bajo el aro: sobre una foto no se
                      // garantizaría el contraste (WCAG 1.4.11).
                      if (busy)
                        CircleAvatar(
                          radius: _avatarRadius / 2,
                          backgroundColor: context.colors.surface,
                          child: const CircularProgressIndicator(),
                        ),
                      PositionedDirectional(
                        end: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: TokensSize.iconM / 2 + TokensSpacing.xs,
                          backgroundColor: context.colors.primary,
                          child: Icon(
                            AppIcons.camera,
                            size: TokensSize.iconS,
                            color: context.colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  Text(
                    label,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista previa en círculo: `BoxFit.cover` centra y recorta el mismo cuadrado
/// que guardará el servidor, así lo que se ve es lo que queda.
class _Preview extends StatefulWidget {
  const _Preview({
    required this.photo,
    required this.saving,
    required this.focusNode,
  });

  final PickedPhoto photo;
  final bool saving;
  final FocusNode focusNode;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  /// Los bytes se copian una vez: con una lista nueva en cada repintado la
  /// imagen se volvería a descodificar y parpadearía.
  late Uint8List _bytes = Uint8List.fromList(widget.photo.bytes);

  @override
  void didUpdateWidget(_Preview old) {
    super.didUpdateWidget(old);
    if (!identical(old.photo.bytes, widget.photo.bytes)) {
      _bytes = Uint8List.fromList(widget.photo.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      children: [
        ClipOval(
          child: Image.memory(
            _bytes,
            width: _previewSize,
            height: _previewSize,
            fit: BoxFit.cover,
            cacheWidth: (_previewSize * 3).round(),
            semanticLabel: l10n.profilePhotoPreviewLabel,
            errorBuilder: (_, _, _) => SizedBox.square(
              dimension: _previewSize,
              child: ColoredBox(
                color: context.colors.surfaceContainerHigh,
                child: const Icon(AppIcons.imageUnavailable),
              ),
            ),
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        // La imagen ya se anuncia; esta línea es para la vista.
        ExcludeSemantics(
          child: Text(
            l10n.profilePhotoPreviewHint,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppPrimaryButton(
          focusNode: widget.focusNode,
          label: l10n.profilePhotoUse,
          icon: Icons.check_rounded,
          loading: widget.saving,
          onPressed: () => context.read<ProfilePhotoBloc>().add(
            const ProfilePhotoEvent.uploadRequested(),
          ),
        ),
      ],
    );
  }
}
