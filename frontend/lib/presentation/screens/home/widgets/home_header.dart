import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Cabecera del inicio: saludo, avatar, fecha, racha, comunidad, campana y
/// admin. La racha lleva a la pestaña «Tú», donde está la barra de XP. El
/// saludo va en una línea junto a los iconos (si el largo no cabe, «Hola,
/// Ana»; si ni ese cabe, los iconos suben a su fila) y la fecha debajo, a
/// todo el ancho: nunca se corta.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.unreadNotifications,
    required this.isAdmin,
    required this.onProfile,
    required this.onNotifications,
    required this.onCommunity,
    required this.onAdmin,
    required this.onProgress,
    this.pendingFriendRequests = 0,
    this.communityKey,
    this.now,
  });

  final HomeGreeting greeting;
  final int unreadNotifications;
  final bool isAdmin;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  /// Abre Tú › Comunidad, con las solicitudes recibidas arriba (ADR 0061).
  final VoidCallback onCommunity;

  /// Solicitudes de amistad sin responder (número del icono «Comunidad»).
  final int pendingFriendRequests;

  /// Clave del icono «Comunidad» (la señala la guía la primera vez).
  final Key? communityKey;
  final VoidCallback onAdmin;

  /// Abre la pestaña Progreso (nivel, racha e insignias).
  final VoidCallback onProgress;

  /// Momento de referencia (inyectable en tests).
  final DateTime? now;

  String get _firstName => greeting.fullName.trim().split(RegExp(r'\s+')).first;

  String _salutation(BuildContext context, DateTime now) {
    final l10n = context.localizations;
    final name = _firstName;
    if (now.hour >= 6 && now.hour < 13) return l10n.homeGreetingMorning(name);
    if (now.hour >= 13 && now.hour < 21) {
      return l10n.homeGreetingAfternoon(name);
    }
    return l10n.homeGreetingEvening(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final current = now ?? DateTime.now();
    final date = DateFormat.MMMMEEEEd().format(current);
    // Con texto grande (200 %) el saludo y la fecha bajan a su propia línea a
    // todo el ancho: al lado del avatar y los botones se cortaban («Buenas
    // noch…») o partían la palabra («Bonsoir / , Lucía») (WCAG 1.4.4).
    final large = context.largeText;
    final salutation = _salutation(context, current);
    final greetingStyle = context.textStyles.titleLarge;
    Widget greetingText(String text, {int maxLines = 1}) => Semantics(
      header: true,
      child: Text(
        text,
        style: greetingStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
    // El nivel y su XP están en Progreso (ADR 0038): aquí solo la fecha, a
    // todo el ancho (al lado de los iconos se cortaba: «Miércoles, 25 de no…»).
    final dateText = Text(
      toBeginningOfSentenceCase(date),
      key: const ValueKey('home-header-date'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.textStyles.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
    final avatar = Tooltip(
      message: l10n.homeOpenProfile,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.pill),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onProfile,
          child: Padding(
            padding: const EdgeInsets.all(TokensSpacing.xxs),
            child: AppAvatar(
              name: greeting.fullName,
              imageUrl: greeting.avatarUrl,
              radius: TokensSize.thumbnailS / 2,
            ),
          ),
        ),
      ),
    );
    final actions = <Widget>[
      _StreakChip(days: greeting.streak, onTap: onProgress),
      // Comunidad también en el móvil (ADR 0059): el número dice cuántas
      // solicitudes de amistad esperan respuesta.
      IconButton(
        key: communityKey,
        tooltip: l10n.homeCommunityRequests(pendingFriendRequests),
        onPressed: onCommunity,
        // La etiqueta ya dice el número: el de la insignia no se lee otra vez.
        icon: ExcludeSemantics(
          child: Badge(
            isLabelVisible: pendingFriendRequests > 0,
            label: Text(
              pendingFriendRequests > 99
                  ? l10n.socialBadgeOverflow
                  : '$pendingFriendRequests',
            ),
            // El mismo icono que el apartado al que lleva (Tú › Comunidad).
            child: const Icon(AppIcons.communityTab),
          ),
        ),
      ),
      IconButton(
        tooltip: l10n.homeNotificationsUnread(unreadNotifications),
        onPressed: onNotifications,
        icon: Badge(
          isLabelVisible: unreadNotifications > 0,
          label: Text(
            unreadNotifications > 99
                ? l10n.socialBadgeOverflow
                : '$unreadNotifications',
          ),
          child: const Icon(AppIcons.notifications),
        ),
      ),
      if (isAdmin)
        IconButton(
          tooltip: l10n.homeAdminPanel,
          onPressed: onAdmin,
          icon: const Icon(AppIcons.admin),
        ),
    ];
    // Con los iconos en su propia fila: el saludo y la fecha a todo el ancho.
    Widget stacked() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Los botones bajan de línea si no caben (320 dp, racha larga).
        Row(
          children: [
            avatar,
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.s),
        greetingText(salutation, maxLines: 3),
        dateText,
      ],
    );
    if (large) return stacked();
    final short = l10n.homeGreetingShort(_firstName);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lo que queda para el saludo al lado del avatar y los iconos (la
        // racha mide su cifra; cada icono, un toque de 48).
        final streakWidth =
            TokensSpacing.s * 2 +
            TokensSize.iconS +
            TokensSpacing.xs +
            context.textWidth(
              '${greeting.streak}',
              context.textStyles.labelLarge,
            );
        final room =
            constraints.maxWidth -
            (TokensSize.thumbnailS + TokensSpacing.xxs * 2) -
            TokensSpacing.m -
            streakWidth -
            TokensLayout.minTouchTarget * (actions.length - 1);
        String? inline;
        if (context.textWidth(salutation, greetingStyle) <= room) {
          inline = salutation;
        } else if (context.textWidth(short, greetingStyle) <= room) {
          inline = short;
        }
        // Ni el corto cabe (320 dp, nombre largo, panel de admin): los
        // iconos suben a su fila en vez de recortar el saludo.
        if (inline == null) return stacked();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                avatar,
                const SizedBox(width: TokensSpacing.m),
                Expanded(child: greetingText(inline)),
                ...actions,
              ],
            ),
            dateText,
          ],
        );
      },
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days, required this.onTap});

  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final active = days > 0;
    // Con racha, pastilla ámbar (fondo y texto de la pareja «container» para
    // llegar a AA); sin racha, neutra.
    final color = active
        ? context.palette.onAccentContainer
        : context.colors.onSurfaceVariant;
    final background = active
        ? context.palette.accentContainer
        : context.colors.surfaceContainerHigh;
    final tooltip = l10n.homeStreakTooltip(days);
    // Se anuncia solo el texto del tooltip («Racha de N días»), no «N» además.
    // La etiqueta envuelve el InkWell y se excluye solo el contenido, para
    // que en la web conserve la acción y el foco.
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        label: tooltip,
        child: AppFocusOutline(
          borderRadius: BorderRadius.circular(TokensRadius.pill),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: TokensLayout.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensSpacing.s,
                  vertical: TokensSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(TokensRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.streak,
                      size: TokensSize.iconS,
                      color: active ? context.palette.accent : color,
                    ),
                    const SizedBox(width: TokensSpacing.xs),
                    Text(
                      '$days',
                      style: context.textStyles.labelLarge?.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
