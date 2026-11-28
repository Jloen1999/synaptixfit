import 'package:flutter/material.dart';

import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/sport_labels.dart';

/// Rejilla de «Deportes» (ADR 0068): una tarjeta ancha «Correr, andar o bici»
/// y una por deporte, con su foto. Elegir el deporte es la acción: no hay
/// botón relleno. Con texto grande o poco ancho pasa a una sola columna para
/// que ningún nombre se parta.
class SportGrid extends StatelessWidget {
  const SportGrid({
    super.key,
    required this.onEndurance,
    required this.onSport,
  });

  /// «Correr, andar o bici».
  final VoidCallback onEndurance;

  /// Fútbol, pádel, natación, baloncesto, tenis u «Otro deporte».
  final ValueChanged<Sport> onSport;

  /// Deportes con tarjeta propia, en el orden de la rejilla.
  static const sports = [
    Sport.football,
    Sport.padel,
    Sport.swim,
    Sport.basketball,
    Sport.tennis,
    Sport.other,
  ];

  /// Ancho mínimo de una tarjeta para ir de dos en dos (o de tres en tres).
  static const _minCard = TokensLayout.cardSideBySideMin / 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = context.largeText || width < _minCard * 2
            ? 1
            : width >= TokensLayout.statsFourColumns
            ? 3
            : 2;
        final rows = <Widget>[];
        for (var i = 0; i < sports.length; i += columns) {
          final row = sports.skip(i).take(columns).toList();
          rows
            ..add(const SizedBox(height: TokensSpacing.s))
            ..add(
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: TokensSpacing.s),
                      Expanded(
                        child: c < row.length
                            ? _SportCard(
                                key: ValueKey('sport-${row[c].api}'),
                                title: SportLabels.name(l10n, row[c]),
                                subtitle: SportLabels.subtitle(l10n, row[c]),
                                photo: SportLabels.photo(row[c]),
                                onTap: () => onSport(row[c]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SportCard(
              key: const ValueKey('sport-endurance'),
              title: l10n.sportEnduranceTitle,
              subtitle: l10n.sportEnduranceSubtitle,
              photo: SportLabels.photo(Sport.run),
              onTap: onEndurance,
              // Los tres dibujos solo acompañan al nombre, que ya los dice.
              trailing: const ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_run_rounded, size: TokensSize.iconM),
                    SizedBox(width: TokensSpacing.xs),
                    Icon(Icons.directions_walk_rounded, size: TokensSize.iconS),
                    SizedBox(width: TokensSpacing.xs),
                    Icon(Icons.directions_bike_rounded, size: TokensSize.iconS),
                  ],
                ),
              ),
            ),
            ...rows,
          ],
        );
      },
    );
  }
}

/// Tarjeta de un deporte: su foto arriba (patrón [AppCoverCard], que funde la
/// foto con la superficie) y debajo el nombre y una línea corta sobre la
/// superficie lisa, así el texto cumple AA con cualquier foto. Toda la
/// tarjeta es el botón.
class _SportCard extends StatelessWidget {
  const _SportCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final ImageProvider photo;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.titleMedium),
        Text(
          subtitle,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    final trailing = this.trailing;
    return MergeSemantics(
      child: AppCoverCard(
        layout: AppCoverLayout.bottom,
        image: photo,
        onTap: onTap,
        padding: const EdgeInsets.all(TokensSpacing.m),
        child: trailing == null
            ? text
            : Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: TokensSpacing.s),
                  IconTheme.merge(
                    data: IconThemeData(color: context.colors.onSurfaceVariant),
                    child: trailing,
                  ),
                ],
              ),
      ),
    );
  }
}
