import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/sport_labels.dart';
import '../../widgets/training_section_bar.dart';

/// «Otro deporte» (`/training/sports/other`, ADR 0068): buscador con unos
/// cuantos deportes frecuentes y «Añadir «x»» para el que se escriba. Elegir
/// uno abre el mismo formulario de apuntar, con su nombre. El nombre lo
/// normaliza y lo guarda el servidor.
class OtherSportPage extends StatefulWidget {
  const OtherSportPage({super.key});

  @override
  State<OtherSportPage> createState() => _OtherSportPageState();
}

class _OtherSportPageState extends State<OtherSportPage> {
  String _query = '';

  String get _back => TrainingPaths.section(TrainingSection.run);

  /// Al guardar se vuelve a «Deportes», donde queda la actividad.
  Future<void> _open(Sport sport, {String? name}) async {
    final saved = await context.push<Object?>(
      TrainingPaths.logActivity(
        from: TrainingSection.run,
        sport: sport,
        name: name,
      ),
    );
    if (saved == true && mounted) context.popOrGo(_back, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // El vóley está en el catálogo del servidor; el resto son nombres libres.
    final options = <(String, Sport)>[
      (l10n.sportVolleyball, Sport.volleyball),
      for (final name in [
        l10n.sportSuggestYoga,
        l10n.sportSuggestClimbing,
        l10n.sportSuggestDance,
        l10n.sportSuggestMartial,
        l10n.sportSuggestHiking,
        l10n.sportSuggestSkating,
      ])
        (name, Sport.other),
    ];
    final typed = _query.trim().replaceAll(RegExp(r'\s+'), ' ');
    final needle = typed.toLowerCase();
    final shown = [
      for (final o in options)
        if (o.$1.toLowerCase().contains(needle)) o,
    ];
    final exact = options.any((o) => o.$1.toLowerCase() == needle);
    return Scaffold(
      appBar: AppPageBar.reading(
        leading: AppBackButton(fallback: _back),
        title: Text(l10n.sportOther),
      ),
      body: AppContentWidth.reading(
        child: ListView(
          padding: const EdgeInsets.all(TokensSpacing.m),
          children: [
            const SportPhotoHeader(sport: Sport.other),
            const SizedBox(height: TokensSpacing.m),
            AppSearchField(
              label: l10n.sportOtherSearch,
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) {
                if (typed.isNotEmpty && !exact) _open(Sport.other, name: typed);
              },
            ),
            const SizedBox(height: TokensSpacing.s),
            if (typed.isNotEmpty && !exact) ...[
              FilledButton.tonalIcon(
                key: const ValueKey('sport-add-typed'),
                onPressed: () => _open(Sport.other, name: typed),
                icon: const Icon(AppIcons.add),
                label: Text(l10n.sportOtherAdd(typed)),
              ),
              const SizedBox(height: TokensSpacing.s),
            ],
            for (final (name, sport) in shown)
              AppFocusOutline(
                child: ListTile(
                  title: AppHighlightedText(text: name, query: typed),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => _open(
                    sport,
                    name: sport == Sport.other ? name : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
