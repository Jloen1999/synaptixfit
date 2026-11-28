import 'package:flutter/material.dart';

import '../../../../domain/models/training/sport_activity.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Nombre, línea corta y foto de cada deporte del apartado «Deportes» (ADR
/// 0068). Las fotos son recursos de la app (`assets/images/sports/`, con su
/// autor y licencia en `CREDITS.md`).
abstract final class SportLabels {
  static String name(AppLocalizations l10n, Sport sport) => switch (sport) {
    Sport.run => l10n.trainingActivityKindRun,
    Sport.walk => l10n.trainingActivityKindWalk,
    Sport.bike => l10n.trainingActivityKindBike,
    Sport.swim => l10n.sportSwim,
    Sport.football => l10n.sportFootball,
    Sport.padel => l10n.sportPadel,
    Sport.basketball => l10n.sportBasketball,
    Sport.volleyball => l10n.sportVolleyball,
    Sport.tennis => l10n.sportTennis,
    Sport.other => l10n.sportOther,
  };

  /// Dos o tres palabras bajo el nombre, en la rejilla.
  static String subtitle(AppLocalizations l10n, Sport sport) =>
      switch (sport.category) {
        SportCategory.match => l10n.sportMatchSubtitle,
        SportCategory.other => l10n.sportOtherSubtitle,
        SportCategory.endurance =>
          sport == Sport.swim
              ? l10n.sportSwimSubtitle
              : l10n.sportEnduranceSubtitle,
      };

  static String mode(AppLocalizations l10n, SportMode mode) => switch (mode) {
    SportMode.match => l10n.sportModeMatch,
    SportMode.training => l10n.sportModeTraining,
  };

  static String result(AppLocalizations l10n, MatchResult result) =>
      switch (result) {
        MatchResult.win => l10n.sportResultWin,
        MatchResult.draw => l10n.sportResultDraw,
        MatchResult.loss => l10n.sportResultLoss,
      };

  /// Foto del deporte; correr, andar y bici comparten la suya, y el vóley va
  /// con «otro deporte» (no tiene tarjeta propia).
  static ImageProvider photo(Sport sport) => AssetImage(
    'assets/images/sports/${switch (sport) {
      Sport.run || Sport.walk || Sport.bike => 'run',
      Sport.swim => 'swim',
      Sport.football => 'football',
      Sport.padel => 'padel',
      Sport.basketball => 'basketball',
      Sport.tennis => 'tennis',
      Sport.volleyball || Sport.other => 'other',
    }}.webp',
  );
}

/// Foto de cabecera de la pantalla de un deporte: una franja decorativa (el
/// lector no la anuncia) sin texto encima, así no hay contraste que cuidar.
/// Si la foto no carga queda el degradado de [AppCoverCard].
class SportPhotoHeader extends StatelessWidget {
  const SportPhotoHeader({super.key, required this.sport});

  final Sport sport;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppCoverCard.tint(context), context.colors.surface],
        ),
      ),
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokensRadius.l),
        child: SizedBox(
          height: TokensSize.coverBanner,
          width: double.infinity,
          child: Image(
            image: SportLabels.photo(sport),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          ),
        ),
      ),
    );
  }
}
