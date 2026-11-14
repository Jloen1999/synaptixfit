import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/device_permission.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/device_permissions_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_device_permission_status_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/is_permissions_intro_pending_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/mark_permissions_intro_seen_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/open_permission_settings_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/request_device_permission_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/mark_reminders_offered_use_case.dart';
import 'package:synaptixfit/domain/use_cases/reminders/set_device_reminders_enabled_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/profile/permissions/bloc/permissions_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/permissions/page/permission_request_sheet.dart';
import 'package:synaptixfit/presentation/screens/profile/permissions/page/permissions_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Teléfono de mentira: cada permiso tiene un estado y pedirlo aplica
/// [onRequest]; abrir los ajustes deja que el test cambie el estado «a mano».
class _FakePhone implements DevicePermissionsRepositoryContract {
  final statuses = <DevicePermission, DevicePermissionStatus>{
    for (final p in DevicePermission.values) p: DevicePermissionStatus.denied,
  };
  DevicePermissionStatus Function(DevicePermission)? onRequest;
  bool seen = false;
  final settingsOpened = <DevicePermission>[];

  @override
  Future<AppResult<DevicePermissionStatus>> status(DevicePermission p) async =>
      Success(statuses[p]!);

  @override
  Future<AppResult<DevicePermissionStatus>> request(DevicePermission p) async {
    statuses[p] = onRequest?.call(p) ?? statuses[p]!;
    return Success(statuses[p]!);
  }

  @override
  Future<AppResult<Unit>> openSettings(DevicePermission p) async {
    settingsOpened.add(p);
    return const Success(unit);
  }

  @override
  Future<AppResult<bool>> introSeen() async => Success(seen);

  @override
  Future<AppResult<Unit>> markIntroSeen() async {
    seen = true;
    return const Success(unit);
  }
}

/// Activar los recordatorios pide el permiso de notificaciones al teléfono.
class _FakeReminders implements SetDeviceRemindersEnabledUseCaseContract {
  _FakeReminders(this.phone);

  final _FakePhone phone;
  bool? enabled;

  @override
  Future<AppResult<bool>> call(bool enabled) async {
    final status = await phone.request(DevicePermission.notifications);
    this.enabled = status.valueOrNull == DevicePermissionStatus.granted;
    return Success(this.enabled!);
  }
}

class _FakeOffered implements MarkRemindersOfferedUseCaseContract {
  bool marked = false;

  @override
  Future<AppResult<Unit>> call() async {
    marked = true;
    return const Success(unit);
  }
}

void main() {
  late _FakePhone phone;
  late _FakeReminders reminders;
  late _FakeOffered offered;

  PermissionsBloc build() => PermissionsBloc(
    getStatus: GetDevicePermissionStatusUseCase(phone),
    request: RequestDevicePermissionUseCase(phone),
    openSettings: OpenPermissionSettingsUseCase(phone),
    markIntroSeen: MarkPermissionsIntroSeenUseCase(phone),
    setRemindersEnabled: reminders,
    markRemindersOffered: offered,
  );

  setUp(() {
    phone = _FakePhone();
    reminders = _FakeReminders(phone);
    offered = _FakeOffered();
  });

  group('PermissionsBloc', () {
    blocTest<PermissionsBloc, PermissionsState>(
      'concedido: «Permitir» la cámara la deja permitida',
      setUp: () => phone.onRequest = (_) => DevicePermissionStatus.granted,
      build: build,
      act: (bloc) async {
        bloc.add(
          const PermissionsEvent.started(
            permissions: [DevicePermission.camera],
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PermissionsEvent.requested(DevicePermission.camera));
      },
      verify: (bloc) => expect(
        bloc.state.statusOf(DevicePermission.camera),
        DevicePermissionStatus.granted,
      ),
    );

    blocTest<PermissionsBloc, PermissionsState>(
      'denegado del todo: queda bloqueado y al volver de los ajustes se '
      'comprueba de nuevo',
      setUp: () =>
          phone.onRequest = (_) => DevicePermissionStatus.permanentlyDenied,
      build: build,
      act: (bloc) async {
        bloc.add(
          const PermissionsEvent.started(
            permissions: [DevicePermission.camera],
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PermissionsEvent.requested(DevicePermission.camera));
        await Future<void>.delayed(Duration.zero);
        expect(
          bloc.state.statusOf(DevicePermission.camera),
          DevicePermissionStatus.permanentlyDenied,
        );
        bloc.add(
          const PermissionsEvent.settingsOpened(DevicePermission.camera),
        );
        await Future<void>.delayed(Duration.zero);
        // La persona lo activa en los ajustes del sistema y vuelve a la app.
        phone.statuses[DevicePermission.camera] =
            DevicePermissionStatus.granted;
        bloc.add(const PermissionsEvent.resumed());
      },
      verify: (bloc) {
        expect(phone.settingsOpened, [DevicePermission.camera]);
        expect(
          bloc.state.statusOf(DevicePermission.camera),
          DevicePermissionStatus.granted,
        );
      },
    );

    blocTest<PermissionsBloc, PermissionsState>(
      'las notificaciones se conceden activando los recordatorios, que ya no '
      'se vuelven a ofrecer',
      setUp: () => phone.onRequest = (_) => DevicePermissionStatus.granted,
      build: build,
      act: (bloc) async {
        bloc.add(const PermissionsEvent.started());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const PermissionsEvent.requested(DevicePermission.notifications),
        );
      },
      verify: (bloc) {
        expect(reminders.enabled, isTrue);
        expect(offered.marked, isTrue);
        expect(
          bloc.state.statusOf(DevicePermission.notifications),
          DevicePermissionStatus.granted,
        );
      },
    );

    blocTest<PermissionsBloc, PermissionsState>(
      '«Ahora no» y «Continuar»: no se vuelve a enseñar el paso',
      build: build,
      act: (bloc) async {
        bloc.add(const PermissionsEvent.started());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const PermissionsEvent.skipped(DevicePermission.camera))
          ..add(const PermissionsEvent.introFinished());
      },
      verify: (bloc) {
        expect(bloc.state.skipped, {DevicePermission.camera});
        expect(bloc.state.introFinished, isTrue);
        expect(phone.seen, isTrue);
      },
    );
  });

  group('IsPermissionsIntroPendingUseCase', () {
    test('pendiente solo si no se vio y falta algún permiso', () async {
      final useCase = IsPermissionsIntroPendingUseCase(phone);
      expect((await useCase()).valueOrNull, isTrue);

      for (final p in DevicePermission.values) {
        phone.statuses[p] = DevicePermissionStatus.granted;
      }
      expect((await useCase()).valueOrNull, isFalse);

      phone.statuses[DevicePermission.camera] = DevicePermissionStatus.denied;
      phone.seen = true;
      expect((await useCase()).valueOrNull, isFalse);
    });

    test('en web o escritorio (sin permisos) no hace falta', () async {
      for (final p in DevicePermission.values) {
        phone.statuses[p] = DevicePermissionStatus.notApplicable;
      }
      expect(
        (await IsPermissionsIntroPendingUseCase(phone)()).valueOrNull,
        isFalse,
      );
    });
  });

  group('Hoja justo antes de usar la cámara', () {
    late PermissionRequestResult? result;

    setUp(() {
      result = null;
      getIt.registerFactory<PermissionsBloc>(build);
    });

    tearDown(() => getIt.unregister<PermissionsBloc>());

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await ensureDevicePermission(
                  context,
                  DevicePermission.camera,
                  alternativeLabel: 'Elegir de la galería',
                ),
                child: const Text('Hacer foto'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('ya permitida: no enseña nada y sigue', (tester) async {
      phone.statuses[DevicePermission.camera] = DevicePermissionStatus.granted;
      await pump(tester);
      await tester.tap(find.text('Hacer foto'));
      await tester.pumpAndSettle();
      expect(find.text('¿Permitir la cámara?'), findsNothing);
      expect(result, PermissionRequestResult.granted);
    });

    testWidgets('explica para qué es y «Permitir» la concede', (tester) async {
      phone.onRequest = (_) => DevicePermissionStatus.granted;
      await pump(tester);
      await tester.tap(find.text('Hacer foto'));
      await tester.pumpAndSettle();
      expect(find.text('¿Permitir la cámara?'), findsOneWidget);
      expect(find.textContaining('La foto no se guarda'), findsOneWidget);
      await tester.tap(find.text('Permitir'));
      await tester.pumpAndSettle();
      expect(result, PermissionRequestResult.granted);
      expect(find.text('¿Permitir la cámara?'), findsNothing);
    });

    testWidgets('denegada: se puede elegir la alternativa (galería)', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Hacer foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      expect(result, PermissionRequestResult.alternative);
    });

    testWidgets('bloqueada: «Abrir ajustes» y al volver a la app se sigue', (
      tester,
    ) async {
      phone.statuses[DevicePermission.camera] =
          DevicePermissionStatus.permanentlyDenied;
      await pump(tester);
      await tester.tap(find.text('Hacer foto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ya no pregunta'), findsOneWidget);
      await tester.tap(find.text('Abrir ajustes del móvil'));
      await tester.pumpAndSettle();
      expect(phone.settingsOpened, [DevicePermission.camera]);
      expect(result, isNull);

      // La activa en los ajustes del sistema y vuelve a la app.
      phone.statuses[DevicePermission.camera] = DevicePermissionStatus.granted;
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(result, PermissionRequestResult.granted);
    });

    testWidgets('«Ahora no» no hace nada', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Hacer foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(result, PermissionRequestResult.notNow);
    });
  });

  group('Ajustes › Permisos del móvil', () {
    setUp(() => getIt.registerFactory<PermissionsBloc>(build));
    tearDown(() => getIt.unregister<PermissionsBloc>());

    Future<void> pump(WidgetTester tester, {ThemeData? theme}) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme ?? AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const PermissionsPage(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tras decir que no, la fila lo explica', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Permitir').first);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No se ha permitido. Puedes volver a intentarlo cuando quieras.',
        ),
        findsWidgets,
      );
    });

    testWidgets(
      'ya permitido: deja abrir los ajustes del móvil para quitarlo',
      (tester) async {
        phone.statuses[DevicePermission.camera] =
            DevicePermissionStatus.granted;
        await pump(tester);
        expect(find.text('Abrir ajustes del móvil'), findsWidgets);
      },
    );

    for (final (name, theme) in [
      ('claro', AppTheme.light),
      ('oscuro', AppTheme.dark),
    ]) {
      testWidgets('accesibilidad, tema $name', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // La guía de contraste de Flutter mide píxeles con la fuente de test y en
        // el tema claro da falsos fallos con colores del tema que cumplen AA
        // (7,5:1); el contraste real de los tokens lo prueba contrast_test.
        if (theme == AppTheme.dark) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        semantics.dispose();
      });
    }
  });
}
