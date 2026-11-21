import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/friendship_relation.dart';
import 'package:synaptixfit/domain/enums/together_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/progress/community/bloc/community_bloc.dart';
import 'package:synaptixfit/presentation/screens/progress/community/page/community_tab.dart';
import 'package:synaptixfit/presentation/screens/progress/progress_routes.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import '../social/social_fixtures.dart';

class _MockBloc extends MockBloc<CommunityEvent, CommunityState>
    implements CommunityBloc {}

/// Tú › Comunidad (ADR 0061): la solicitud que espera, los accesos, lo que
/// está en marcha con amigos y lo último del muro; cuatro estados y
/// accesibilidad.
void main() {
  late _MockBloc bloc;

  final ready = CommunityState(
    status: CommunityStatus.ready,
    requests: [friendship('f1', relation: FriendshipRelation.requestReceived)],
    requestsTotal: 3,
    friendsTotal: 14,
    together: const TogetherOverview(
      streaks: [
        FriendStreak(
          id: 's1',
          status: FriendStreakStatus.active,
          friend: TogetherPerson(id: 'u3', name: 'Marta'),
          days: 6,
        ),
        FriendStreak(
          id: 's2',
          status: FriendStreakStatus.pending,
          friend: TogetherPerson(id: 'u4', name: 'Pablo'),
        ),
      ],
    ),
    posts: const [],
  );

  setUp(() {
    bloc = _MockBloc();
    when(() => bloc.state).thenReturn(ready);
    getIt.registerFactory<CommunityBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<CommunityBloc>());

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 1400 * textScale);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: CommunityTab()),
            ),
            for (final path in [
              ProgressExternalPaths.friends,
              ProgressExternalPaths.friendRequests,
              ProgressExternalPaths.friendSearch,
              ProgressExternalPaths.socialWall,
              ProgressExternalPaths.together,
              ProgressExternalPaths.communityChallenges,
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
    );
    await tester.pump();
  }

  testWidgets('la solicitud que espera, arriba y con un solo «Aceptar»', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('3 solicitudes de amistad'), findsOneWidget);
    expect(find.text('Luis Gil'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Aceptar'), findsOneWidget);
    expect(find.byTooltip('Rechazar a Luis Gil'), findsOneWidget);

    await tester.tap(find.text('Aceptar'));
    verify(
      () => bloc.add(const CommunityEvent.requestAccepted('f1')),
    ).called(1);
    await tester.tap(find.byTooltip('Rechazar a Luis Gil'));
    verify(
      () => bloc.add(const CommunityEvent.requestRejected('f1')),
    ).called(1);

    // El resto de solicitudes, en Amigos › Recibidas.
    await tester.tap(find.text('Ver las 3'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pantalla ${ProgressExternalPaths.friendRequests}'),
      findsOneWidget,
    );
  });

  testWidgets('cuatro accesos que abren su pantalla de siempre', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Mis amigos'), findsOneWidget);
    expect(find.text('14 amigos'), findsOneWidget);
    expect(find.text('Muro'), findsOneWidget);
    expect(find.text('Retos de otros'), findsOneWidget);

    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pantalla ${ProgressExternalPaths.friendSearch}'),
      findsOneWidget,
    );
  });

  testWidgets(
    '«Con amigos ahora» nombra cada cosa y «Ver todo» abre el resto',
    (tester) async {
      await pump(tester);

      expect(find.text('Con amigos ahora'), findsOneWidget);
      // La racha activa se nombra; la propuesta sin contestar no es «ahora».
      expect(find.text('Racha con Marta: 6 días'), findsOneWidget);
      expect(find.textContaining('Pablo'), findsNothing);
      // El muro, sin publicaciones, lo dice.
      expect(find.text('Lo último del muro'), findsOneWidget);
      expect(find.text('Aún no hay publicaciones.'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Ver todo').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Pantalla ${ProgressExternalPaths.together}'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'sin solicitudes ni nada con amigos: sin tarjeta y con la frase',
    (tester) async {
      when(() => bloc.state).thenReturn(
        const CommunityState(
          status: CommunityStatus.ready,
          together: TogetherOverview(),
        ),
      );
      await pump(tester);

      expect(find.text('Aceptar'), findsNothing);
      expect(find.text('Aún ninguno'), findsOneWidget);
      expect(
        find.textContaining('Ahora no tienes nada en marcha'),
        findsOneWidget,
      );
      // Sin poder leer el muro, se dice en su sitio.
      expect(find.text('No se ha podido cargar esta sección.'), findsOneWidget);
    },
  );

  testWidgets('cargando, esqueleto; con error, «Reintentar»', (tester) async {
    when(() => bloc.state).thenReturn(const CommunityState());
    await pump(tester);
    expect(find.text('Mis amigos'), findsNothing);

    when(() => bloc.state).thenReturn(
      const CommunityState(
        status: CommunityStatus.failure,
        error: AppError.network(),
      ),
    );
    await pump(tester);
    // Cada montaje pide «started»: solo cuenta el del botón.
    clearInteractions(bloc);
    await tester.tap(find.text('Reintentar'));
    verify(() => bloc.add(const CommunityEvent.started())).called(1);
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
      // Cada tarjetita se lee con su nombre y su detalle.
      expect(find.bySemanticsLabel('Mis amigos, 14 amigos'), findsOneWidget);
      // «Aceptar» dice a quién, igual que «Rechazar».
      expect(find.bySemanticsLabel('Aceptar a Luis Gil'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Buscar personas, Por nombre'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a 320 px (1,0 · 1,2 · 2,0): sin desbordes ni palabras '
        'partidas', (tester) async {
      for (final scale in [1.0, 1.2, 2.0]) {
        await pump(tester, width: 320, textScale: scale);
        expect(tester.takeException(), isNull, reason: '$scale');
        for (final word in ['Publicaciones', 'Buscar', 'Muro']) {
          expectWordNotSplit(tester, find.text(word));
        }
      }
    });

    testWidgets('con el texto al 200 % no se corta ni se solapa', (
      tester,
    ) async {
      await pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Retos de otros'), findsOneWidget);
      // Las tarjetitas bajan a una columna: no se estrechan hasta cortarse.
      expect(
        tester.getTopLeft(find.text('Muro')).dy,
        greaterThan(tester.getTopLeft(find.text('Buscar')).dy),
      );
    });
  });
}

/// El texto se ve entero: cabe en su caja sin cortarse ni difuminarse.
void expectWhole(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  expect(
    paragraph.size.width + 0.5,
    greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
    reason: 'cortado: ${paragraph.text.toPlainText()}',
  );
}

/// Ninguna palabra se parte en dos líneas: una palabra sola cabe entera en
/// el ancho de su caja.
void expectWordNotSplit(WidgetTester tester, Finder text) =>
    expectWhole(tester, text);
