import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/subject_material.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../social/together/widgets/together_widgets.dart';
import '../../academic_routes.dart';
import '../bloc/material_share_bloc.dart';

/// Hoja «Compartir» de un material (ADR 0064): con un amigo, para todos, en el
/// muro y fuera de la app, y «Descargar» aparte al final. Lo de dentro de la
/// app solo existe para los apuntes; un archivo lo dice en vez de esconderlo.
/// Publicar («Para todos», «En el muro») pide antes una confirmación que dice
/// el alcance real según [profilePrivacy] (la del perfil, si se conoce).
/// Usa el [MaterialShareBloc] de la página: el aviso lo pinta
/// [MaterialShareFeedback] cuando la hoja ya se ha cerrado.
Future<void> showMaterialShareSheet(
  BuildContext context,
  SubjectMaterial material, {
  Visibility? profilePrivacy,
}) {
  final bloc = context.read<MaterialShareBloc>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _MaterialShareSheet(
        material: material,
        profilePrivacy: profilePrivacy,
      ),
    ),
  );
}

class _MaterialShareSheet extends StatelessWidget {
  const _MaterialShareSheet({
    required this.material,
    required this.profilePrivacy,
  });

  final SubjectMaterial material;
  final Visibility? profilePrivacy;

  Future<void> _chooseFriend(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<MaterialShareBloc>();
    final friendId = await showFriendPickerSheet(
      context,
      title: l10n.academicShareFriendPickerTitle,
      confirmLabel: l10n.academicShareFriendPickerConfirm,
    );
    if (friendId == null || bloc.isClosed) return;
    bloc.add(
      MaterialShareEvent.friendChosen(material: material, friendId: friendId),
    );
  }

  /// «Para todos»: antes, qué verá quién según la privacidad del perfil.
  Future<void> _everyone(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<MaterialShareBloc>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.academicShareEveryoneConfirmTitle,
      message: switch (profilePrivacy) {
        Visibility.public => l10n.academicShareEveryoneConfirmPublic,
        Visibility.friends => l10n.academicShareEveryoneConfirmFriends,
        Visibility.private => l10n.academicShareEveryoneConfirmPrivate,
        null => l10n.academicShareEveryoneConfirmGeneral,
      },
      confirmLabel: l10n.academicShareEveryoneConfirmAction,
      cancelLabel: l10n.commonCancel,
      destructive: false,
    );
    if (ok && !bloc.isClosed) {
      bloc.add(MaterialShareEvent.everyoneRequested(material));
    }
  }

  /// «En el muro»: con el perfil privado no se publica (nadie lo vería) y se
  /// ofrece ir a la privacidad; si no, qué verá quién y dónde.
  Future<void> _wall(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<MaterialShareBloc>();
    if (profilePrivacy == Visibility.private) {
      final toPrivacy = await showConfirmDialog(
        context,
        title: l10n.academicShareWallPrivateTitle,
        message: l10n.academicShareWallPrivateBody,
        confirmLabel: l10n.academicSharePrivacyAction,
        cancelLabel: l10n.commonCancel,
        destructive: false,
      );
      if (toPrivacy && context.mounted) {
        await context.push<void>(AcademicExternalPaths.privacySettings);
      }
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: l10n.academicShareWallConfirmTitle,
      message: switch (profilePrivacy) {
        Visibility.public => l10n.academicShareWallConfirmPublic,
        Visibility.friends => l10n.academicShareWallConfirmFriends,
        _ => l10n.academicShareWallConfirmGeneral,
      },
      confirmLabel: l10n.academicShareWallConfirmAction,
      cancelLabel: l10n.commonCancel,
      destructive: false,
    );
    if (ok && !bloc.isClosed) {
      bloc.add(MaterialShareEvent.wallRequested(material));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final note = switch (material) {
      NoteMaterial(:final note) => note,
      FileMaterial() => null,
    };
    // Al terminar (bien o mal) se cierra: el aviso sale en la página.
    return BlocListener<MaterialShareBloc, MaterialShareState>(
      listenWhen: (a, b) => a.seq != b.seq,
      listener: (context, _) => Navigator.of(context).maybePop(),
      child: BlocBuilder<MaterialShareBloc, MaterialShareState>(
        builder: (context, state) {
          final running = state.running;
          VoidCallback? run(VoidCallback action) =>
              running != null ? null : action;
          Widget option({
            required MaterialShareAction action,
            required IconData icon,
            required String title,
            required String hint,
            required VoidCallback onTap,
          }) => _ShareOption(
            icon: icon,
            title: title,
            hint: hint,
            busy: running == action,
            onTap: run(onTap),
          );
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: TokensSpacing.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensSpacing.m,
                      0,
                      TokensSpacing.m,
                      TokensSpacing.s,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.academicShareTitle(material.title),
                        style: context.textStyles.titleLarge,
                      ),
                    ),
                  ),
                  if (note != null) ...[
                    option(
                      action: MaterialShareAction.friend,
                      icon: AppIcons.friends,
                      title: l10n.academicShareFriend,
                      hint: l10n.academicShareFriendHint,
                      onTap: () => _chooseFriend(context),
                    ),
                    option(
                      action: MaterialShareAction.everyone,
                      icon: AppIcons.sharedNotes,
                      title: l10n.academicShareEveryone,
                      hint: note.visibility == Visibility.public
                          ? l10n.academicShareEveryoneAlready
                          : l10n.academicShareEveryoneHint,
                      onTap: () => _everyone(context),
                    ),
                    option(
                      action: MaterialShareAction.wall,
                      icon: AppIcons.community,
                      title: l10n.academicShareWall,
                      hint: l10n.academicShareWallHint,
                      onTap: () => _wall(context),
                    ),
                  ],
                  option(
                    action: MaterialShareAction.outside,
                    icon: AppIcons.shareOutside,
                    title: l10n.academicShareOutside,
                    hint: note != null
                        ? l10n.academicShareOutsideNoteHint
                        : l10n.academicShareOutsideFileHint,
                    onTap: () => context.read<MaterialShareBloc>().add(
                      MaterialShareEvent.outsideRequested(material),
                    ),
                  ),
                  if (note == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TokensSpacing.m,
                        vertical: TokensSpacing.xs,
                      ),
                      child: Text(
                        l10n.academicShareFilesOutsideOnly,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const Divider(height: TokensSpacing.l),
                  option(
                    action: MaterialShareAction.download,
                    icon: AppIcons.export,
                    title: l10n.academicMaterialDownload,
                    hint: note != null
                        ? l10n.academicShareDownloadNoteHint
                        : l10n.academicShareDownloadFileHint,
                    onTap: () => context.read<MaterialShareBloc>().add(
                      MaterialShareEvent.downloadRequested(material),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Una forma de compartir: icono, nombre y qué pasa, toda la fila es el botón.
/// Mientras se hace, un indicador que el lector anuncia una vez.
class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppFocusOutline(
    child: ListTile(
      enabled: onTap != null || busy,
      onTap: onTap,
      minVerticalPadding: TokensSpacing.s,
      leading: Icon(icon, color: context.colors.tertiary),
      title: Text(title, style: context.textStyles.titleSmall),
      subtitle: Text(hint),
      trailing: busy
          ? Semantics(
              liveRegion: true,
              label: context.localizations.commonLoading,
              child: const ExcludeSemantics(
                child: SizedBox.square(
                  dimension: TokensSize.iconM,
                  child: CircularProgressIndicator(
                    strokeWidth: TokensSize.spinnerStroke,
                  ),
                ),
              ),
            )
          : null,
    ),
  );
}

/// Escucha el [MaterialShareBloc] de la página y pinta el aviso de cada
/// resultado (ADR 0064): dice dónde queda y lleva «Ver» (`showActionSnack`);
/// si el perfil es privado, lo dice y lleva a la privacidad. Un error lleva
/// «Reintentar», que repite lo mismo con el mismo material. Cerrar el menú
/// del sistema o el «Guardar como» no avisa de nada.
class MaterialShareFeedback extends StatelessWidget with ErrorsMessageMixin {
  const MaterialShareFeedback({super.key, required this.child});

  final Widget child;

  void _show(BuildContext context, MaterialShareState state) {
    final l10n = context.localizations;
    void privateProfile(String message) => context.showActionSnack(
      message,
      actionLabel: l10n.academicSharePrivacyAction,
      onAction: () => context.push<void>(AcademicExternalPaths.privacySettings),
    );
    final error = state.error;
    if (error != null) {
      if (error case BusinessError(code: 'NOTE_WALL_PROFILE_PRIVATE')) {
        privateProfile(errorMessage(context, error));
      } else {
        context.showActionSnack(
          errorMessage(context, error),
          actionLabel: l10n.commonRetry,
          onAction: () => context.read<MaterialShareBloc>().add(
            const MaterialShareEvent.retryRequested(),
          ),
        );
      }
      return;
    }
    final result = state.result;
    if (result == null || !result.completed) return;
    void view(String message, String route) => context.showActionSnack(
      message,
      actionLabel: l10n.commonView,
      onAction: () => context.push<void>(route),
    );
    final shared = AcademicPaths.sharedNote(result.materialId);
    switch (result.action) {
      case MaterialShareAction.friend:
        final name = result.friendName?.trim() ?? '';
        view(
          name.isEmpty
              ? l10n.academicShareSentToFriendUnnamed
              : l10n.academicShareSentToFriend(name),
          shared,
        );
      case MaterialShareAction.everyone:
        switch (result.visibility) {
          case Visibility.public:
            view(l10n.academicShareEveryoneDone, shared);
          case Visibility.friends:
            view(l10n.academicShareEveryoneFriends, shared);
          case Visibility.private || null:
            privateProfile(l10n.academicShareProfilePrivate);
        }
      case MaterialShareAction.wall:
        view(
          result.alreadyShared
              ? l10n.academicShareWallAlready
              : l10n.academicShareWallDone,
          AcademicExternalPaths.wall,
        );
      case MaterialShareAction.outside:
        break;
      case MaterialShareAction.download:
        context.showSnack(l10n.academicDownloadDone(result.fileName ?? ''));
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<MaterialShareBloc, MaterialShareState>(
        listenWhen: (a, b) => a.seq != b.seq,
        listener: _show,
        child: child,
      );
}
