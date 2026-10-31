import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/reminder_kind.dart';
import 'package:synaptixfit/domain/enums/usage_focus.dart';
import 'package:synaptixfit/domain/models/reminders/reminder.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/reminders/mark_reminders_offered_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/should_offer_reminders_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/clear_reminders_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/get_device_reminders_status_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/set_device_reminders_enabled_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/sync_reminders_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/watch_device_reminders_enabled_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/watch_opened_reminders_use_case.dart';
import 'package:synaptixfit/domain/use_cases/sync/watch_data_changes_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/notification_settings/bloc/device_reminders_bloc.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/reminders_bloc.dart';

import '../../../domain/reminders/reminder_test_texts.dart';

class _Sync extends Mock implements SyncRemindersUseCaseContract {}

class _Clear extends Mock implements ClearRemindersUseCaseContract {}

class _Changes extends Mock implements WatchDataChangesUseCaseContract {}

class _Enabled extends Mock
    implements WatchDeviceRemindersEnabledUseCaseContract {}

class _Opened extends Mock implements WatchOpenedRemindersUseCaseContract {}

class _ShouldOffer extends Mock
    implements ShouldOfferRemindersUseCaseContract {}

class _MarkOffered extends Mock
    implements MarkRemindersOfferedUseCaseContract {}

class _Status extends Mock implements GetDeviceRemindersStatusUseCaseContract {}

class _SetEnabled extends Mock
    implements SetDeviceRemindersEnabledUseCaseContract {}

void main() {
  const texts = TestReminderTexts();

  group('RemindersBloc', () {
    late _Sync sync;
    late _Clear clear;
    late _Changes changes;
    late _Enabled enabled;
    late _Opened opened;
    late _ShouldOffer shouldOffer;
    late _MarkOffered markOffered;
    late _SetEnabled setEnabled;
    late StreamController<Set<DataTopic>> changesController;
    late StreamController<ReminderKind> openedController;

    setUpAll(() {
      registerFallbackValue(const TestReminderTexts());
    });

    setUp(() {
      sync = _Sync();
      clear = _Clear();
      changes = _Changes();
      enabled = _Enabled();
      opened = _Opened();
      shouldOffer = _ShouldOffer();
      markOffered = _MarkOffered();
      setEnabled = _SetEnabled();
      // Por defecto no toca ofrecer (ya se ofreció o no se admite).
      when(() => shouldOffer()).thenAnswer((_) async => const Success(false));
      when(() => markOffered()).thenAnswer((_) async => const Success(unit));
      when(
        () => setEnabled(any()),
      ).thenAnswer((_) async => const Success(true));
      changesController = StreamController.broadcast();
      openedController = StreamController.broadcast();
      when(
        () => sync(texts: any(named: 'texts')),
      ).thenAnswer((_) async => const Success(2));
      when(() => clear()).thenAnswer((_) async => const Success(unit));
      when(
        () => changes(topics: any(named: 'topics')),
      ).thenAnswer((_) => changesController.stream);
      when(() => enabled()).thenAnswer((_) => const Stream.empty());
      when(() => opened()).thenAnswer((_) => openedController.stream);
    });

    RemindersBloc build() => RemindersBloc(
      sync: sync,
      clear: clear,
      watchChanges: changes,
      watchEnabled: enabled,
      watchOpened: opened,
      shouldOffer: shouldOffer,
      markOffered: markOffered,
      setEnabled: setEnabled,
      debounce: Duration.zero,
    );

    blocTest<RemindersBloc, RemindersState>(
      'al guardar algo del planificador ofrece los avisos una vez y, si se aceptan, los activa',
      setUp: () => when(
        () => shouldOffer(),
      ).thenAnswer((_) async => const Success(true)),
      build: build,
      act: (bloc) async {
        bloc.add(
          const RemindersEvent.started(focus: UsageFocus.both, texts: texts),
        );
        await Future<void>.delayed(Duration.zero);
        changesController
          ..add({DataTopic.planner})
          ..add({DataTopic.academic});
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(bloc.state.offerReminders, isTrue);
        bloc.add(const RemindersEvent.offerAnswered(accepted: true));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state.offerReminders, isFalse);
        verify(() => shouldOffer()).called(1);
        verify(() => markOffered()).called(1);
        verify(() => setEnabled(true)).called(1);
      },
    );

    blocTest<RemindersBloc, RemindersState>(
      'sincroniza al entrar y cuando cambian los datos',
      build: build,
      act: (bloc) async {
        bloc.add(
          const RemindersEvent.started(focus: UsageFocus.both, texts: texts),
        );
        await Future<void>.delayed(Duration.zero);
        changesController.add({DataTopic.planner});
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      expect: () => const [RemindersState(scheduled: 2)],
      verify: (_) => verify(() => sync(texts: texts)).called(2),
    );

    blocTest<RemindersBloc, RemindersState>(
      'al cambiar el enfoque vuelve a pedir el plan',
      build: build,
      act: (bloc) => bloc
        ..add(
          const RemindersEvent.started(focus: UsageFocus.both, texts: texts),
        )
        ..add(const RemindersEvent.focusChanged(UsageFocus.fitness)),
      verify: (_) => verify(() => sync(texts: texts)).called(2),
    );

    blocTest<RemindersBloc, RemindersState>(
      'al cerrar sesión borra los avisos y deja de sincronizar',
      build: build,
      act: (bloc) async {
        bloc.add(const RemindersEvent.signedOut());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const RemindersEvent.started(focus: UsageFocus.both, texts: texts),
        );
      },
      verify: (_) {
        verify(() => clear()).called(1);
        verifyNever(() => sync(texts: any(named: 'texts')));
      },
    );

    blocTest<RemindersBloc, RemindersState>(
      'un aviso tocado queda pendiente hasta navegar',
      build: build,
      act: (bloc) async {
        bloc.add(
          const RemindersEvent.started(focus: UsageFocus.both, texts: texts),
        );
        await Future<void>.delayed(Duration.zero);
        openedController.add(ReminderKind.dueReviews);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RemindersEvent.openHandled());
      },
      expect: () => const [
        RemindersState(scheduled: 2),
        RemindersState(scheduled: 2, openRequest: ReminderKind.dueReviews),
        RemindersState(scheduled: 2),
      ],
    );
  });

  group('DeviceRemindersBloc', () {
    late _Status status;
    late _SetEnabled setEnabled;

    setUp(() {
      status = _Status();
      setEnabled = _SetEnabled();
      when(() => status()).thenAnswer(
        (_) async => const Success(
          DeviceRemindersStatus(supported: true, enabled: false),
        ),
      );
    });

    DeviceRemindersBloc build() =>
        DeviceRemindersBloc(getStatus: status, setEnabled: setEnabled);

    blocTest<DeviceRemindersBloc, DeviceRemindersState>(
      'carga si el dispositivo los admite',
      build: build,
      act: (bloc) => bloc.add(const DeviceRemindersEvent.started()),
      expect: () => const [DeviceRemindersState(loaded: true, supported: true)],
    );

    blocTest<DeviceRemindersBloc, DeviceRemindersState>(
      'muestra el permiso retirado en el sistema al cargar',
      setUp: () => when(() => status()).thenAnswer(
        (_) async => const Success(
          DeviceRemindersStatus(
            supported: true,
            enabled: true,
            permissionGranted: false,
          ),
        ),
      ),
      build: build,
      act: (bloc) => bloc.add(const DeviceRemindersEvent.started()),
      expect: () => const [
        DeviceRemindersState(
          loaded: true,
          supported: true,
          enabled: true,
          permissionDenied: true,
        ),
      ],
    );

    blocTest<DeviceRemindersBloc, DeviceRemindersState>(
      'al volver a la app mantiene la fila si el permiso sigue negado',
      setUp: () => when(() => status()).thenAnswer(
        (_) async => const Success(
          DeviceRemindersStatus(
            supported: true,
            enabled: false,
            permissionGranted: false,
          ),
        ),
      ),
      build: build,
      seed: () => const DeviceRemindersState(
        loaded: true,
        supported: true,
        permissionDenied: true,
      ),
      act: (bloc) => bloc.add(const DeviceRemindersEvent.started()),
      expect: () => const <DeviceRemindersState>[],
    );

    blocTest<DeviceRemindersBloc, DeviceRemindersState>(
      'avisa si el sistema niega el permiso',
      setUp: () => when(
        () => setEnabled(true),
      ).thenAnswer((_) async => const Success(false)),
      build: build,
      seed: () => const DeviceRemindersState(loaded: true, supported: true),
      act: (bloc) => bloc.add(const DeviceRemindersEvent.toggled(true)),
      expect: () => const [
        DeviceRemindersState(loaded: true, supported: true, busy: true),
        DeviceRemindersState(
          loaded: true,
          supported: true,
          permissionDenied: true,
        ),
      ],
    );

    blocTest<DeviceRemindersBloc, DeviceRemindersState>(
      'queda activado si se concede',
      setUp: () => when(
        () => setEnabled(true),
      ).thenAnswer((_) async => const Success(true)),
      build: build,
      seed: () => const DeviceRemindersState(loaded: true, supported: true),
      act: (bloc) => bloc.add(const DeviceRemindersEvent.toggled(true)),
      expect: () => const [
        DeviceRemindersState(loaded: true, supported: true, busy: true),
        DeviceRemindersState(loaded: true, supported: true, enabled: true),
      ],
    );
  });
}
