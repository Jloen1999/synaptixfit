import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations_en.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations_es.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations_fr.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations_pt.dart';

/// Cifras de la revisión del 25 nov: ninguna fracción con barra («2/3»,
/// «15 / 200 XP»), siempre «2 de 3 días», y el plural concuerda con el
/// total («0 de 1 hecho», «2 de 5 hechos»).
void main() {
  // «{a}/{b}», «{a} / 10», «3/{b}»: una cifra con barra. No cuentan las
  // listas que arma el código («12/10/8 reps») ni «km/h» o «min/km».
  final fraction = RegExp(r'(\}|\d)\s*/\s*(\{|\d)');

  for (final language in ['es', 'en', 'fr', 'pt']) {
    test('$language: ningún texto pinta una cifra con barra', () {
      final file = File('lib/presentation/l10n/app_$language.arb');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final offenders = [
        for (final MapEntry(:key, :value) in data.entries)
          if (!key.startsWith('@') &&
              value is String &&
              fraction.hasMatch(value))
            key,
      ];
      expect(offenders, isEmpty);
    });
  }

  test('es: el plural concuerda con el total', () {
    final es = AppLocalizationsEs();
    expect(es.homeTodayDoneCount(0, 1), '0 de 1 hecho');
    expect(es.homeTodayDoneCount(2, 5), '2 de 5 hechos');
    expect(es.homeWeekDoneOf(0, 1), '0 de 1 cosa hecha');
    expect(es.homeWeekDoneOf(0, 3), '0 de 3 cosas hechas');
    expect(es.challengesMilestonesProgress(1, 2), '1 de 2 tareas');
    expect(es.challengesMilestonesProgress(0, 1), '0 de 1 tarea');
    expect(es.trainingSetsDone(1, 1), '1 de 1 serie');
    expect(es.trainingDaysProgress(0, 24), '0 de 24 días');
    expect(es.homeSetupProgress(4, 5), '4 de 5 listos');
  });

  test('la XP dice para qué nivel es («15 de 200 XP para el nivel 3»)', () {
    expect(
      AppLocalizationsEs().commonXpProgress(15, 200, 3),
      '15 de 200 XP para el nivel 3',
    );
    expect(
      AppLocalizationsEn().commonXpProgress(15, 200, 3),
      '15 of 200 XP to level 3',
    );
  });

  test('fr y pt: con 1 en singular y con 0 nunca «de 1»', () {
    final fr = AppLocalizationsFr();
    final pt = AppLocalizationsPt();
    expect(fr.trainingSetsDone(0, 1), '0 sur 1 série');
    expect(fr.trainingSetsDone(2, 3), '2 sur 3 séries');
    expect(pt.homeTodayDoneCount(0, 1), '0 de 1 feito');
    expect(pt.homeTodayDoneCount(1, 4), '1 de 4 feitos');
    // El 0 cae en «one» en fr y pt: la rama de 1 lleva el número real.
    expect(fr.homeTodayDoneCount(0, 0), '0 sur 0 fait');
  });
}
