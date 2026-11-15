import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/together_enums.dart';
import '../../../../../domain/models/social/together.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../social_routes.dart';
import '../friend_picker/bloc/friend_picker_bloc.dart';
import '../safety/bloc/together_safety_bloc.dart';
import 'together_labels.dart';

/// Menú de otra persona en «Con amigos» (ADR 0044): ver su perfil, bloquear y
/// denunciar en un toque. [onEnd] añade «Terminar racha» al principio.
class TogetherMemberMenu extends StatelessWidget {
  const TogetherMemberMenu({
    super.key,
    required this.person,
    required this.reportContext,
    this.endLabel,
    this.onEnd,
  });

  final TogetherPerson person;
  final UserReportContext reportContext;
  final String? endLabel;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final name = togetherName(context, person.name);
    return PopupMenuButton<_MemberAction>(
      tooltip: l10n.togetherMemberMenu(name),
      onSelected: (action) async {
        final safety = context.read<TogetherSafetyBloc>();
        switch (action) {
          case _MemberAction.end:
            onEnd?.call();
          case _MemberAction.profile:
            unawaited(context.push(SocialPaths.user(person.id)));
          case _MemberAction.block:
            // Bloquear termina la racha y saca de lo compartido: no tiene
            // vuelta atrás, así que se confirma con el verbo exacto.
            final ok = await showConfirmDialog(
              context,
              title: l10n.socialBlockTitle,
              message: l10n.togetherBlockMessage(name),
              confirmLabel: l10n.socialBlock,
            );
            if (ok) safety.add(TogetherSafetyEvent.blockRequested(person.id));
          case _MemberAction.report:
            safety.add(
              TogetherSafetyEvent.reportRequested(person.id, reportContext),
            );
        }
      },
      itemBuilder: (_) => [
        if (onEnd != null && endLabel != null)
          PopupMenuItem(
            value: _MemberAction.end,
            child: ListTile(
              leading: const Icon(AppIcons.leave),
              title: Text(endLabel!),
            ),
          ),
        PopupMenuItem(
          value: _MemberAction.profile,
          child: ListTile(
            leading: const Icon(AppIcons.friends),
            title: Text(l10n.togetherViewProfile),
          ),
        ),
        PopupMenuItem(
          value: _MemberAction.block,
          child: ListTile(
            leading: const Icon(AppIcons.block),
            title: Text(l10n.socialBlock),
          ),
        ),
        PopupMenuItem(
          value: _MemberAction.report,
          child: ListTile(
            leading: const Icon(AppIcons.report),
            title: Text(l10n.togetherReport),
          ),
        ),
      ],
    );
  }
}

enum _MemberAction { end, profile, block, report }

/// Avisos de bloquear y denunciar (dicen dónde queda el bloqueo, con «Ver»).
/// [onBlocked] decide qué hace la pantalla después (volver a leer o cerrarse).
class TogetherSafetyListener extends StatelessWidget with ErrorsMessageMixin {
  const TogetherSafetyListener({
    super.key,
    required this.child,
    required this.onBlocked,
  });

  final Widget child;

  /// Qué hacer después, con el id de la persona bloqueada.
  final ValueChanged<String> onBlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocListener<TogetherSafetyBloc, TogetherSafetyState>(
      listenWhen: (p, c) => c.done != p.done || c.error != p.error,
      listener: (context, state) {
        if (state.error case final error?) {
          context.showSnack(errorMessage(context, error));
        } else if (state.done == TogetherSafetyDone.blocked) {
          final router = GoRouter.of(context);
          context.showActionSnack(
            l10n.socialMsgUserBlocked,
            actionLabel: l10n.commonView,
            onAction: () => router.push(SocialPaths.blocked),
          );
          onBlocked(state.blockedId!);
        } else if (state.done == TogetherSafetyDone.reported) {
          context.showSnack(l10n.socialMsgReported);
        }
      },
      child: child,
    );
  }
}

/// Bloc de seguridad de cada pantalla de «Con amigos».
TogetherSafetyBloc createSafetyBloc() => getIt<TogetherSafetyBloc>();

/// Lista de amigos mutuos con casillas (de `FriendPickerBloc`); al llegar al
/// máximo, las demás se desactivan. Sin amigos, lleva a buscarlos.
class FriendPickerList extends StatelessWidget {
  const FriendPickerList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<FriendPickerBloc, FriendPickerState>(
      builder: (context, state) {
        final bloc = context.read<FriendPickerBloc>();
        return switch (state.status) {
          FriendPickerStatus.loading => const AppLoadingView(),
          FriendPickerStatus.failure => AppErrorView(
            error: state.error!,
            onRetry: () => bloc.add(FriendPickerEvent.started(max: state.max)),
          ),
          FriendPickerStatus.ready when state.friends.isEmpty =>
            AppEmptyState.compact(
              icon: AppIcons.friends,
              title: l10n.togetherNoFriendsTitle,
              message: l10n.togetherNoFriendsMessage,
              action: AppSecondaryButton(
                label: l10n.togetherFindFriends,
                icon: const Icon(AppIcons.search),
                onPressed: () => context.push(SocialPaths.friends),
              ),
            ),
          FriendPickerStatus.ready => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.max > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                  child: Text(
                    l10n.togetherPickedCount(state.selected.length, state.max),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final friend in state.friends)
                CheckboxListTile(
                  value: state.selected.contains(friend.id),
                  onChanged: state.full && !state.selected.contains(friend.id)
                      ? null
                      : (_) => bloc.add(FriendPickerEvent.toggled(friend.id)),
                  secondary: AppAvatar(
                    name: friend.fullName,
                    imageUrl: friend.avatarUrl,
                  ),
                  title: Text(friend.fullName),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        };
      },
    );
  }
}

/// Hoja para elegir a un amigo (proponer una racha). Devuelve su id.
Future<String?> showFriendPickerSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
}) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => BlocProvider(
    create: (_) =>
        getIt<FriendPickerBloc>()..add(const FriendPickerEvent.started(max: 1)),
    child: _FriendPickerSheet(title: title, confirmLabel: confirmLabel),
  ),
);

class _FriendPickerSheet extends StatelessWidget {
  const _FriendPickerSheet({required this.title, required this.confirmLabel});

  final String title;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.m,
          0,
          TokensSpacing.m,
          TokensSpacing.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: context.textStyles.titleLarge),
            ),
            const SizedBox(height: TokensSpacing.s),
            const Flexible(
              child: SingleChildScrollView(child: FriendPickerList()),
            ),
            const SizedBox(height: TokensSpacing.m),
            BlocBuilder<FriendPickerBloc, FriendPickerState>(
              builder: (context, state) => AppPrimaryButton(
                label: confirmLabel,
                onPressed: state.selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(state.selected.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de avatares con el nombre de cada persona para el lector.
class TogetherAvatars extends StatelessWidget {
  const TogetherAvatars({super.key, required this.people});

  final List<TogetherPerson> people;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TokensSpacing.xs,
      runSpacing: TokensSpacing.xs,
      children: [
        for (final p in people)
          Semantics(
            label: togetherName(context, p.name),
            excludeSemantics: true,
            child: AppAvatar(
              name: togetherName(context, p.name),
              imageUrl: p.avatarUrl,
            ),
          ),
      ],
    );
  }
}

/// Barra de avance común de un reto con amigos en modo juntos.
class TogetherProgressBar extends StatelessWidget {
  const TogetherProgressBar({
    super.key,
    required this.value,
    required this.target,
    required this.label,
  });

  final int value;
  final int target;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fraction = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: context.textStyles.bodyMedium),
          const SizedBox(height: TokensSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensRadius.pill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: TokensSize.progressBar,
            ),
          ),
        ],
      ),
    );
  }
}
