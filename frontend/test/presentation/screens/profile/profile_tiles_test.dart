import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/usage_focus.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/profile/bloc/profile_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/profile/page/profile_detail_pages.dart';
import 'package:synaptixfit/presentation/screens/profile/profile/page/profile_page.dart';
import 'package:synaptixfit/presentation/screens/profile/profile_routes.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'profile_fixtures.dart';

class _MockSession extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class _MockProfile extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

/// Perfil en tarjetitas (ADR 0061): la cuenta compacta y seis accesos; las
/// fichas «Físico» y «Académico» se abren aparte.
void main() {
  late _MockSession session;
  late _MockProfile profile;

  ProfileState ready({UsageFocus focus = UsageFocus.both, int pending = 2}) =>
      ProfileState(
        status: ProfileStatus.ready,
        account: testAccount.copyWith(usageFocus: focus),
        summary: testSummary,
        pendingRequests: pending,
      );

  setUp(() {
    session = _MockSession();
    profile = _MockProfile();
    when(() => session.state).thenReturn(const SessionState.unknown());
    when(() => session.account).thenReturn(testAccount);
    when(() => profile.state).thenReturn(ready());
    getIt.registerFactory<ProfileBloc>(() => profile);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester, {
    Widget page = const ProfilePage(),
    ThemeData? theme,
    double textScale = 1,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 1000 * textScale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => page),
              for (final path in [
                ProfilePaths.you,
                ProfilePaths.physical,
                ProfilePaths.studies,
                ProfilePaths.friendRequests,
                ProfilePaths.settings,
              ])
                GoRoute(
                  path: path,
                  builder: (_, _) => Scaffold(body: Text('Pantalla $path')),
                ),
            ],
          ),
          theme: theme ?? AppTheme.light,
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('la cuenta compacta y seis tarjetitas con su detalle', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Ana'), findsOneWidget);
    // Correo y visibilidad, cada uno en su línea (la visibilidad también es
    // el detalle de «Cómo me ven»).
    expect(find.text('ana@uni.es'), findsOneWidget);
    expect(find.text('Solo amigos'), findsNWidgets(2));
    expect(find.widgetWithText(OutlinedButton, 'Editar'), findsOneWidget);
    for (final label in [
      'Amigos',
      'Muro',
      'Cómo me ven',
      'Físico',
      'Académico',
      'Ajustes',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('2 solicitudes pendientes'), findsOneWidget);
    expect(find.text('60 kg · 165 cm'), findsOneWidget);
    expect(find.text('Grado en Informática'), findsOneWidget);
    // Ajustes es una tarjetita: ya no hay engranaje en la barra.
    expect(find.byTooltip('Ajustes'), findsNothing);
  });

  testWidgets('la racha abre Tú › Resumen', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Racha de 5 días'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla ${ProfilePaths.you}'), findsOneWidget);
  });

  testWidgets('a «Físico» sin peso ni altura le falta lo principal', (
    tester,
  ) async {
    when(() => profile.state).thenReturn(
      ProfileState(
        status: ProfileStatus.ready,
        account: testAccount,
        summary: testSummary.copyWith(
          wellness: testWellness.copyWith(weightKg: null, heightCm: null),
        ),
      ),
    );
    await pump(tester);
    expect(find.text('Sin completar'), findsOneWidget);
  });

  testWidgets('Amigos con solicitudes abre Recibidas; Físico, su ficha', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Amigos'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pantalla ${ProfilePaths.friendRequests}'),
      findsOneWidget,
    );

    await pump(tester);
    await tester.tap(find.text('Físico'));
    await tester.pumpAndSettle();
    expect(find.text('Pantalla ${ProfilePaths.physical}'), findsOneWidget);
  });

  testWidgets('quien solo estudia no ve «Físico»; quien solo entrena, no '
      '«Académico»', (tester) async {
    when(() => profile.state).thenReturn(ready(focus: UsageFocus.academic));
    await pump(tester);
    expect(find.text('Físico'), findsNothing);
    expect(find.text('Académico'), findsOneWidget);

    when(() => profile.state).thenReturn(ready(focus: UsageFocus.fitness));
    await pump(tester);
    expect(find.text('Físico'), findsOneWidget);
    expect(find.text('Académico'), findsNothing);
  });

  testWidgets('la ficha «Físico» enseña las cifras con «Editar» y la '
      'evolución', (tester) async {
    await pump(tester, page: const ProfilePhysicalPage());

    expect(find.text('Perfil físico'), findsOneWidget);
    expect(find.text('60 kg'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Editar'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);
  });

  testWidgets('la ficha «Académico» sin datos ofrece completarlos', (
    tester,
  ) async {
    when(() => profile.state).thenReturn(
      const ProfileState(
        status: ProfileStatus.ready,
        account: testAccount,
        summary: emptySummary,
      ),
    );
    await pump(tester, page: const ProfileStudiesPage());

    expect(find.text('Perfil académico'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    // Grados, asignaturas y matrícula siguen a mano.
    expect(find.byType(ListTile), findsNWidgets(3));
  });

  testWidgets('cargando y con error (con «Reintentar»)', (tester) async {
    when(() => profile.state).thenReturn(const ProfileState());
    await pump(tester);
    expect(find.text('Amigos'), findsNothing);

    when(() => profile.state).thenReturn(
      const ProfileState(
        status: ProfileStatus.failure,
        error: AppError.network(),
      ),
    );
    await pump(tester);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  group('accesibilidad', () {
    testWidgets('tamaño táctil, etiquetas y contraste (claro y oscuro)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await pump(tester, theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      // El número de solicitudes se lee, no solo se ve en el globo.
      expect(
        find.bySemanticsLabel('Amigos, 2 solicitudes pendientes'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a 320 px (1,0 · 1,2 · 2,0) el correo se ve entero', (
      tester,
    ) async {
      when(() => profile.state).thenReturn(
        ProfileState(
          status: ProfileStatus.ready,
          account: testAccount.copyWith(
            email: 'ana.romero.garcia@estudiantes.ugr.es',
          ),
          summary: testSummary,
          pendingRequests: 2,
        ),
      );
      for (final scale in [1.0, 1.2, 2.0]) {
        await pump(tester, width: 320, textScale: scale);
        expect(tester.takeException(), isNull, reason: '$scale');
        final email = tester.renderObject<RenderParagraph>(
          find.text('ana.romero.garcia@estudiantes.ugr.es'),
        );
        expect(email.didExceedMaxLines, isFalse, reason: '$scale');
        // «Editar» baja debajo de la cuenta en vez de estrecharla.
        expect(
          tester.getTopLeft(find.text('Editar')).dy,
          greaterThan(
            tester
                .getTopLeft(find.text('ana.romero.garcia@estudiantes.ugr.es'))
                .dy,
          ),
        );
      }
    });

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Ajustes'), findsOneWidget);
    });
  });
}
