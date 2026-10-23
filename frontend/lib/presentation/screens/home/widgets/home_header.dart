import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Cabecera del inicio: saludo, avatar, fecha con el nivel, racha, campana y
/// admin. La racha lleva a la pestaña Progreso, donde está la barra de XP.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.unreadNotifications,
    required this.isAdmin,
    required this.onProfile,
    required this.onNotifications,
    required this.onAdmin,
    required this.onProgress,
    this.now,
  });

  final HomeGreeting greeting;
  final int unreadNotifications;
  final bool isAdmin;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final VoidCallback onAdmin;

  /// Abre la pestaña Progreso (nivel, racha e insignias).
  final VoidCallback onProgress;

  /// Momento de referencia (inyectable en tests).
  final DateTime? now;

  String _salutation(BuildContext context, DateTime now) {
    final l10n = context.localizations;
    final name = greeting.fullName.trim().split(RegExp(r'\s+')).first;
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
    final date = DateFormat.MMMMEEEEd('es').format(current);
    return Row(
      children: [
        Tooltip(
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
                  radius: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: TokensSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // El saludo hace de título de la página.
              Semantics(
                header: true,
                child: Text(
                  _salutation(context, current),
                  style: context.textStyles.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // El nivel va como texto: la barra de XP vive en Progreso.
              Text(
                '${toBeginningOfSentenceCase(date)} · '
                '${l10n.commonLevel(greeting.level)}',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _StreakChip(days: greeting.streak, onTap: onProgress),
        IconButton(
          tooltip: l10n.homeNotificationsUnread(unreadNotifications),
          onPressed: onNotifications,
          icon: Badge(
            isLabelVisible: unreadNotifications > 0,
            label: Text(
              unreadNotifications > 99 ? '99+' : '$unreadNotifications',
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        if (isAdmin)
          IconButton(
            tooltip: l10n.homeAdminPanel,
            onPressed: onAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
      ],
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
                      Icons.local_fire_department_rounded,
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
