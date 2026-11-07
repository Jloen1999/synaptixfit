import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/usage_focus.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/account/update_account_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/edit_account/bloc/edit_account_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/edit_account/page/edit_account_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'profile_fixtures.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

/// Guarda lo que recibe y devuelve la cuenta con esos cambios.
class _FakeUpdateAccount implements UpdateAccountUseCaseContract {
  final calls = <UsageFocus?>[];
  Visibility? privacy;
  String? fullName;

  @override
  Future<AppResult<Account>> call({
    String? fullName,
    String? avatarUrl,
    Visibility? privacy,
    UsageFocus? usageFocus,
    DateTime? birthDate,
    bool clearBirthDate = false,
  }) async {
    calls.add(usageFocus);
    this.privacy = privacy;
    this.fullName = fullName;
    return Result.success(
      testAccount.copyWith(
        usageFocus: usageFocus ?? testAccount.usageFocus,
        privacy: privacy ?? testAccount.privacy,
        fullName: fullName ?? testAccount.fullName,
      ),
    );
  }
}

/// Fallo 12: «cambio el modo de uso, le doy a guardar y no se guarda nada».
/// El modo de uso está al final: al bajar hasta él, la lista perezosa
/// desmontaba el formulario del nombre y «Guardar» no hacía nada.
void main() {
  late _MockSessionBloc session;
  late _FakeUpdateAccount update;

  setUp(() {
    session = _MockSessionBloc();
    update = _FakeUpdateAccount();
    when(
      () => session.state,
    ).thenReturn(const SessionState.authenticated(testAccount));
    when(() => session.account).thenReturn(testAccount);
    getIt.registerFactory<EditAccountBloc>(
      () => EditAccountBloc(updateAccount: update),
    );
  });

  tearDown(() => getIt.unregister<EditAccountBloc>());

  Future<void> pump(WidgetTester tester) async {
    // Móvil pequeño: la pantalla no cabe entera y hay que bajar.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('perfil')),
        GoRoute(
          path: '/account',
          builder: (_, _) => const EditAccountPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push<Object?>('/account').ignore();
    await tester.pumpAndSettle();
  }

  testWidgets('cambiar el modo de uso al final de la pantalla y guardar', (
    tester,
  ) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Solo estudios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solo estudios'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(update.calls, [UsageFocus.academic]);
    verify(
      () => session.add(
        SessionEvent.accountUpdated(
          testAccount.copyWith(usageFocus: UsageFocus.academic),
        ),
      ),
    ).called(1);
  });

  testWidgets('la privacidad y el nombre también se guardan', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Ana López');
    await tester.ensureVisible(find.text('Público'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Público'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(update.fullName, 'Ana López');
    expect(update.privacy, Visibility.public);
  });
}
