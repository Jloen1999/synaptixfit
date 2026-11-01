import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/enums/post_type.dart';
import 'package:synaptixfit/domain/models/social/post_link.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/social/widgets/post_card.dart';
import 'package:synaptixfit/presentation/screens/social/widgets/user_tile.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

import 'social_fixtures.dart';

/// Monta [child] a 360 dp de ancho y con el texto al [scale] (200 % por
/// defecto), como pide la regla de accesibilidad de las tarjetas.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double scale = 2,
  double width = 360,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: app!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('PostCard', () {
    testWidgets(
      'a 320 y 360 dp, texto al 200 % y los dos temas, sin desbordes',
      (tester) async {
        final p = post('p1', likes: 3, comments: 2).copyWith(
          type: PostType.challengeCompleted,
          link: const PostLink(
            kind: PostLinkKind.challenge,
            id: 'c1',
            name: 'Leer 10 artículos',
          ),
        );
        for (final width in [320.0, 360.0]) {
          for (final dark in [false, true]) {
            await _pump(
              tester,
              PostCard(post: p, onLike: () {}, onOpen: () {}),
              width: width,
              dark: dark,
            );
            expect(tester.takeException(), isNull, reason: '$width dp');
          }
        }
        expect(find.text('Luis Gil'), findsOneWidget);
        expect(find.text('Post p1'), findsOneWidget);
        expect(find.text('Leer 10 artículos'), findsOneWidget);
        // El tipo se dice en texto, no solo con el color del acento.
        expect(
          find.textContaining('Reto completado', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('3 me gusta'), findsOneWidget);
        expect(find.text('2 comentarios'), findsOneWidget);
      },
    );

    testWidgets('cada zona es su propio botón (sin toques anidados)', (
      tester,
    ) async {
      String? author;
      String? route;
      var opened = 0;
      var liked = 0;
      final p = post('p1').copyWith(
        link: const PostLink(
          kind: PostLinkKind.challenge,
          id: 'c1',
          name: 'Reto',
        ),
      );
      await _pump(
        tester,
        PostCard(
          post: p,
          onLike: () => liked++,
          onOpen: () => opened++,
          onAuthorTap: (id) => author = id,
          onLinkTap: (r) => route = r,
        ),
        scale: 1,
      );
      await tester.tap(find.text('Luis Gil'));
      expect(author, 'u2');
      expect(opened, 0);

      await tester.tap(find.text('Post p1'));
      expect(opened, 1);

      await tester.tap(find.text('Reto'));
      expect(route, '/challenges/c1');
      expect(opened, 1);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(liked, 1);
      expect(opened, 1);
    });

    testWidgets('el autor se anuncia como botón con quién, qué y cuándo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        PostCard(post: post('p1'), onLike: () {}, onAuthorTap: (_) {}),
        scale: 1,
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(RegExp('^Ver el perfil de Luis Gil, Logro')),
        ),
        isSemantics(isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });

  group('UserTile', () {
    testWidgets('con acciones, a 320 dp y texto al 200 %, sin desbordes', (
      tester,
    ) async {
      var opened = 0;
      var accepted = 0;
      await _pump(
        width: 320,
        tester,
        UserTile(
          name: 'Usuaria con un nombre bastante largo',
          level: 12,
          subtitle: 'Quiere ser tu amigo',
          highlight: Colors.green,
          onTap: () => opened++,
          trailing: FilledButton(
            onPressed: () => accepted++,
            child: const Text('Aceptar'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Nivel 12'), findsOneWidget);
      await tester.tap(find.text('Aceptar'));
      expect(accepted, 1);
      expect(opened, 0);
      await tester.tap(find.text('Quiere ser tu amigo'));
      expect(opened, 1);
    });
  });
}
