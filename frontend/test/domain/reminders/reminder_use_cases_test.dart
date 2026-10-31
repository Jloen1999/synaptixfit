import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/reminders/reminder.dart';
import 'package:synaptixfit/domain/models/reminders/reminder_plan.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/reminder_plan_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/reminder_scheduler_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/reminder_settings_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/reminders/get_device_reminders_status_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/set_device_reminders_enabled_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/should_offer_reminders_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/sync_reminders_use_case.dart';

import 'reminder_test_texts.dart';

class _Scheduler extends Mock implements ReminderSchedulerRepositoryContract {}

class _Settings extends Mock implements ReminderSettingsRepositoryContract {}

class _Plan extends Mock implements ReminderPlanRepositoryContract {}

void main() {
  late _Scheduler scheduler;
  late _Settings settings;
  late _Plan plan;
  final now = DateTime.utc(2026, 10, 21, 8);
  const texts = TestReminderTexts();
  final serverPlan = [
    PlannedReminder(
      kind: ReminderKind.dueReviews,
      at: now.add(const Duration(hours: 9)),
      refId: '2026-10-21',
      count: 3,
    ),
    PlannedReminder(
      kind: ReminderKind.sportBlock,
      at: now.add(const Duration(days: 1, hours: 2, minutes: 45)),
      refId: 'b1',
      title: 'Cuerpo completo A',
      startsAt: now.add(const Duration(days: 1, hours: 3)),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(<Reminder>[]);
  });

  setUp(() {
    scheduler = _Scheduler();
    settings = _Settings();
    plan = _Plan();
    when(() => scheduler.isSupported).thenReturn(true);
    when(
      () => scheduler.cancelAll(),
    ).thenAnswer((_) async => const Success(unit));
    when(
      () => scheduler.replaceAll(any(), channelName: any(named: 'channelName')),
    ).thenAnswer((_) async => const Success(unit));
    when(
      () => settings.isEnabled(),
    ).thenAnswer((_) async => const Success(true));
    when(
      () => plan.getPlan(days: any(named: 'days')),
    ).thenAnswer((_) async => Success(serverPlan));
    when(
      () => scheduler.hasPermission(),
    ).thenAnswer((_) async => const Success(true));
  });

  group('SyncRemindersUseCase', () {
    SyncRemindersUseCase build() => SyncRemindersUseCase(
      scheduler: scheduler,
      settings: settings,
      plan: plan,
    );

    test('en web no hace nada', () async {
      when(() => scheduler.isSupported).thenReturn(false);

      final result = await build()(texts: texts);

      expect(result.valueOrNull, 0);
      verifyNever(() => settings.isEnabled());
      verifyNever(() => scheduler.cancelAll());
    });

    test(
      'desactivado en el dispositivo: borra los avisos y no pide el plan',
      () async {
        when(
          () => settings.isEnabled(),
        ).thenAnswer((_) async => const Success(false));

        final result = await build()(texts: texts);

        expect(result.valueOrNull, 0);
        verify(() => scheduler.cancelAll()).called(1);
        verifyNever(() => plan.getPlan(days: any(named: 'days')));
      },
    );

    test('programa el plan del servidor de los próximos 7 días', () async {
      final result = await build()(texts: texts);

      expect(result.valueOrNull, 2);
      verify(() => plan.getPlan(days: 7)).called(1);
      final scheduled =
          verify(
                () =>
                    scheduler.replaceAll(captureAny(), channelName: 'channel'),
              ).captured.single
              as List<Reminder>;
      expect(scheduled.map((r) => r.kind), [
        ReminderKind.dueReviews,
        ReminderKind.sportBlock,
      ]);
      expect(scheduled.first.body, 'reviews:3');
      expect(scheduled.map((r) => r.at), serverPlan.map((p) => p.at));
    });

    test('un plan vacío deja la lista vacía', () async {
      when(
        () => plan.getPlan(days: any(named: 'days')),
      ).thenAnswer((_) async => const Success([]));

      final result = await build()(texts: texts);

      expect(result.valueOrNull, 0);
      verify(
        () => scheduler.replaceAll(const [], channelName: 'channel'),
      ).called(1);
    });

    test('si falla el plan no toca lo ya programado', () async {
      when(
        () => plan.getPlan(days: any(named: 'days')),
      ).thenAnswer((_) async => const Failure(AppError.network()));

      final result = await build()(texts: texts);

      expect(result.errorOrNull, const AppError.network());
      verifyNever(
        () =>
            scheduler.replaceAll(any(), channelName: any(named: 'channelName')),
      );
      verifyNever(() => scheduler.cancelAll());
    });
  });

  group('SetDeviceRemindersEnabledUseCase', () {
    SetDeviceRemindersEnabledUseCase build() =>
        SetDeviceRemindersEnabledUseCase(
          scheduler: scheduler,
          settings: settings,
        );

    setUp(() {
      when(
        () => settings.setEnabled(any()),
      ).thenAnswer((_) async => const Success(unit));
    });

    test('al activar pide permiso y guarda si se concede', () async {
      when(
        () => scheduler.requestPermission(),
      ).thenAnswer((_) async => const Success(true));

      final result = await build()(true);

      expect(result.valueOrNull, isTrue);
      verify(() => settings.setEnabled(true)).called(1);
    });

    test('si se niega el permiso queda desactivado', () async {
      when(
        () => scheduler.requestPermission(),
      ).thenAnswer((_) async => const Success(false));

      final result = await build()(true);

      expect(result.valueOrNull, isFalse);
      verify(() => settings.setEnabled(false)).called(1);
    });

    test('al desactivar borra los avisos sin pedir permiso', () async {
      final result = await build()(false);

      expect(result.valueOrNull, isFalse);
      verify(() => settings.setEnabled(false)).called(1);
      verify(() => scheduler.cancelAll()).called(1);
      verifyNever(() => scheduler.requestPermission());
    });
  });

  group('GetDeviceRemindersStatusUseCase', () {
    test('en web no está soportado', () async {
      when(() => scheduler.isSupported).thenReturn(false);

      final result = await GetDeviceRemindersStatusUseCase(
        scheduler: scheduler,
        settings: settings,
      )();

      expect(
        result.valueOrNull,
        const DeviceRemindersStatus(supported: false, enabled: false),
      );
    });

    test('detecta el permiso retirado en el sistema', () async {
      when(
        () => scheduler.hasPermission(),
      ).thenAnswer((_) async => const Success(false));

      final result = await GetDeviceRemindersStatusUseCase(
        scheduler: scheduler,
        settings: settings,
      )();

      expect(
        result.valueOrNull,
        const DeviceRemindersStatus(
          supported: true,
          enabled: true,
          permissionGranted: false,
        ),
      );
    });

    test('en móvil devuelve la preferencia guardada', () async {
      final result = await GetDeviceRemindersStatusUseCase(
        scheduler: scheduler,
        settings: settings,
      )();

      expect(
        result.valueOrNull,
        const DeviceRemindersStatus(supported: true, enabled: true),
      );
    });
  });

  group('ShouldOfferRemindersUseCase', () {
    ShouldOfferRemindersUseCase offer() =>
        ShouldOfferRemindersUseCase(scheduler: scheduler, settings: settings);

    test(
      'se ofrece una sola vez y solo si se admiten y no están activados',
      () async {
        when(
          () => settings.isEnabled(),
        ).thenAnswer((_) async => const Success(false));
        when(
          () => settings.wasOffered(),
        ).thenAnswer((_) async => const Success(false));
        expect((await offer()()).valueOrNull, isTrue);

        when(
          () => settings.wasOffered(),
        ).thenAnswer((_) async => const Success(true));
        expect((await offer()()).valueOrNull, isFalse);

        when(
          () => settings.isEnabled(),
        ).thenAnswer((_) async => const Success(true));
        when(
          () => settings.wasOffered(),
        ).thenAnswer((_) async => const Success(false));
        expect((await offer()()).valueOrNull, isFalse);

        when(() => scheduler.isSupported).thenReturn(false);
        expect((await offer()()).valueOrNull, isFalse);
      },
    );
  });
}
