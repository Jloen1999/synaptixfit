import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';
import 'app_pill.dart';

/// Bloque de fecha a la izquierda de una tarjeta con la forma del chip de día
/// de la agenda de Inicio: una etiqueta arriba («Vence», «lun»), la cifra en
/// grande («3», «Hoy») y el mes debajo, todo tintado de [color]. Dice de un
/// vistazo cuándo toca algo. Con [compact] (texto grande o poco ancho) es una
/// franja de una línea que va encima del contenido. Es decorativo: la tarjeta
/// lee la misma información en una frase. Lo usan retos, entregas e Inicio.
class AppDateBlock extends StatelessWidget {
  const AppDateBlock({
    super.key,
    required this.caption,
    required this.color,
    this.headline,
    this.footer,
    this.icon = Icons.event_available_rounded,
    this.compact = false,
  });

  /// Bloque de una fecha límite: «Hoy · 3 · nov», «Mañana · 4 · nov»,
  /// «lun · 10 · nov» o «Venció · 2 · nov», en [color]. La cifra es siempre
  /// el día (una palabra larga como «Aujourd'hui» no cabría en grande).
  /// [overdue] fuerza la forma de vencida aunque la fecha sea de hoy.
  factory AppDateBlock.due(
    BuildContext context, {
    Key? key,
    required DateTime due,
    required DateTime now,
    required Color color,
    bool overdue = false,
    bool compact = false,
  }) {
    final l10n = context.localizations;
    final days = AppDueDates.daysUntil(due, now);
    // [overdue] lo decide el servidor (p. ej. venció hoy a las 9 y son las 15):
    // manda sobre la cuenta de días.
    final caption = overdue || days < 0
        ? l10n.commonDateOverdue
        : days == 0
        ? l10n.commonDateToday
        : days == 1
        ? l10n.commonDateTomorrow
        : DateFormat.E().format(due);
    return AppDateBlock(
      key: key,
      caption: caption,
      headline: DateFormat.d().format(due),
      footer: DateFormat.MMM().format(due),
      color: color,
      compact: compact,
    );
  }

  final String caption;

  /// La cifra del día (o «Hoy»); sin ella se pinta [icon].
  final String? headline;
  final String? footer;
  final Color color;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final background = Color.alphaBlend(
      color.withValues(alpha: AppPill.tintAlpha),
      context.colors.surface,
    );
    final caps = context.textStyles.labelSmall;
    if (compact) {
      return ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensSpacing.s,
            vertical: TokensSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(TokensRadius.m),
          ),
          child: Text(
            [caption, ?headline, ?footer].join(' · '),
            style: context.textStyles.labelLarge?.copyWith(color: color),
          ),
        ),
      );
    }
    final big = headline;
    final small = footer;
    return ExcludeSemantics(
      child: Container(
        width: context.scaled(TokensSize.dayChipWidth),
        padding: const EdgeInsets.symmetric(
          horizontal: TokensSpacing.xxs,
          vertical: TokensSpacing.s,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(TokensRadius.m),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Una etiqueta larga («Aujourd'hui», «Empieza») se reduce, no se parte.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                caption,
                maxLines: 1,
                style: caps?.copyWith(color: color),
              ),
            ),
            if (big == null)
              Icon(icon, color: color, size: TokensSize.iconM)
            else
              // La misma cifra que el chip de día de Inicio.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  big,
                  maxLines: 1,
                  style: context.textStyles.titleMedium,
                ),
              ),
            if (small != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  small,
                  maxLines: 1,
                  style: caps?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Si el bloque cabe al lado del contenido: con el texto grande o poco
  /// ancho ([maxWidth] de la tarjeta), va encima en su forma compacta.
  static bool sideBySide(BuildContext context, double maxWidth) =>
      !context.largeText &&
      maxWidth >= context.scaled(TokensLayout.cardSideBySideMin);
}

/// Cuentas y frases de fechas límite compartidas por las tarjetas (entregas,
/// retos de Inicio): días naturales hasta la fecha y «Vence en 3 días».
abstract final class AppDueDates {
  /// Lo que vence hoy o mañana se destaca con el color de aviso.
  static const urgentDays = 1;

  /// Días naturales de [now] a [date] (negativo si ya pasó).
  static int daysUntil(DateTime date, DateTime now) {
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(date.year, date.month, date.day);
    return b.difference(a).inDays;
  }

  /// Vence hoy o mañana (no lo ya vencido: eso ya no urge igual).
  static bool isSoon(DateTime date, DateTime now) {
    final days = daysUntil(date, now);
    return days >= 0 && days <= urgentDays;
  }

  /// «Vence hoy», «Vence mañana», «Vence en 3 días», «Vence el lun, 3 nov»
  /// o «Venció el 2 nov». [overdue] (lo decide el servidor) fuerza la última.
  static String text(
    BuildContext context,
    DateTime due,
    DateTime now, {
    bool overdue = false,
  }) {
    final l10n = context.localizations;
    final days = daysUntil(due, now);
    if (overdue || days < 0) {
      return l10n.commonOverdueOn(DateFormat.MMMd().format(due));
    }
    if (days == 0) return l10n.commonDueToday;
    if (days == 1) return l10n.commonDueTomorrow;
    if (days <= 6) return l10n.commonDueIn(days);
    return l10n.commonDueOn(DateFormat.MMMEd().format(due));
  }
}
