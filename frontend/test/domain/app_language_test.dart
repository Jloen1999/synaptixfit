import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/app_language.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';

void main() {
  test('el idioma del dispositivo solo se usa si está traducido', () {
    expect(AppLanguage.resolve(AppLanguage.system, 'fr'), 'fr');
    expect(AppLanguage.resolve(AppLanguage.system, 'de'), 'es');
    expect(AppLanguage.resolve(AppLanguage.system, null), 'es');
    expect(AppLanguage.resolve(AppLanguage.pt, 'en'), 'pt');
  });

  test('lo guardado desconocido cuenta como «el del dispositivo»', () {
    expect(AppLanguage.fromStorage('it'), AppLanguage.system);
    expect(AppLanguage.fromStorage('en'), AppLanguage.en);
  });

  test('el editor pide la hora según el tipo de bloque', () {
    expect(BlockType.delivery.timeInput, BlockTimeInput.moment);
    expect(BlockType.exam.timeInput, BlockTimeInput.duration);
    expect(BlockType.study.timeInput, BlockTimeInput.range);
    // Nunca se ofrece una duración por debajo del mínimo de un bloque (30 min).
    for (final t in BlockType.values) {
      expect(t.durationOptions.every((m) => m >= 30), isTrue, reason: t.name);
    }
    expect(BlockType.meal.usesSubject, isFalse);
    expect(BlockType.sleep.usesChallenge, isFalse);
    expect(BlockType.study.usesDeadlineLink, isTrue);
  });
}
