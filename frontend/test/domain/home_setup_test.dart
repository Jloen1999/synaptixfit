import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/home/home_setup.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/home_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/setup_reminder_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/home/get_home_setup_use_case.dart';
import 'package:synaptixfit/domain/use_cases/home/snooze_home_setup_use_case.dart';

class _Home extends Mock implements HomeRepositoryContract {}

class _Reminders extends Mock implements SetupReminderRepositoryContract {}

void main() {
  final now = DateTime(2026, 10, 24, 10);
  const pending = HomeSetup(pending: [HomeSetupTask.subjects], total: 3);

  test('se ve si falta algo y no se pospuso o ya pasó el plazo', () {
    expect(pending.visibleAt(now), isTrue);
    expect(pending.done, 2);
    expect(
      pending
          .copyWith(snoozedUntil: now.add(const Duration(days: 1)))
          .visibleAt(now),
      isFalse,
    );
    expect(
      pending
          .copyWith(snoozedUntil: now.subtract(const Duration(days: 1)))
          .visibleAt(now),
      isTrue,
    );
    expect(const HomeSetup(total: 3).visibleAt(now), isFalse);
  });

  test(
    'junta lo pendiente del servidor con el «Ahora no» del dispositivo',
    () async {
      final home = _Home();
      final reminders = _Reminders();
      when(
        () => home.getSetup(),
      ).thenAnswer((_) async => const Success(pending));
      when(
        () => reminders.snoozedUntil('u1'),
      ).thenAnswer((_) async => Success(now));
      final result = await GetHomeSetupUseCase(home, reminders)(userId: 'u1');
      expect(result.valueOrNull, pending.copyWith(snoozedUntil: now));
    },
  );

  test('si no se puede leer el «Ahora no», el aviso se muestra', () async {
    final home = _Home();
    final reminders = _Reminders();
    when(() => home.getSetup()).thenAnswer((_) async => const Success(pending));
    when(
      () => reminders.snoozedUntil('u1'),
    ).thenAnswer((_) async => const Failure(AppError.unknown()));
    final result = await GetHomeSetupUseCase(home, reminders)(userId: 'u1');
    expect(result.valueOrNull?.visibleAt(now), isTrue);
  });

  test('«Ahora no» lo pospone una semana', () async {
    final reminders = _Reminders();
    // Mismo reloj de pared una semana después (sin desfase por el cambio de hora).
    final until = DateTime(2026, 10, 31, 10);
    when(
      () => reminders.snoozeUntil('u1', until),
    ).thenAnswer((_) async => const Success(unit));
    final result = await SnoozeHomeSetupUseCase(reminders)(now, userId: 'u1');
    expect(result.valueOrNull, until);
  });
}
