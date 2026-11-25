import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/home/widgets/home_header.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Cabecera de Inicio (revisión del 25 nov): el saludo cabe en una línea al
/// lado de los iconos y la fecha se ve entera debajo, también a 320 dp y con
/// el texto al 200 %.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    Intl.defaultLocale = 'es';
  });
  tearDownAll(() => Intl.defaultLocale = null);

  // Miércoles 25 de noviembre, por la tarde: «Buenas tardes, Ana».
  final now = DateTime(2026, 11, 25, 17);

  Future<void> pump(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    String name = 'Ana Romero',
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
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
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: HomeHeader(
              greeting: HomeGreeting(
                fullName: name,
                level: 1,
                levelXp: 0,
                levelThreshold: 100,
                streak: 0,
              ),
              unreadNotifications: 1,
              pendingFriendRequests: 2,
              isAdmin: false,
              onProfile: () {},
              onNotifications: () {},
              onCommunity: () {},
              onAdmin: () {},
              onProgress: () {},
              now: now,
            ),
          ),
        ),
      ),
    );
  }

  RenderParagraph paragraph(WidgetTester tester, Finder finder) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(of: finder, matching: find.byType(RichText)),
      );

  final date = find.byKey(const ValueKey('home-header-date'));

  for (final (width, scale) in [(390.0, 1.0), (320.0, 1.0), (320.0, 2.0)]) {
    testWidgets(
      'la fecha se ve entera (${width.toInt()} dp, ${(scale * 100).toInt()} %)',
      (tester) async {
        await pump(tester, width: width, scale: scale);
        expect(tester.takeException(), isNull);
        expect(find.text('Miércoles, 25 de noviembre'), findsOneWidget);
        expect(paragraph(tester, date).didExceedMaxLines, isFalse);
        // El saludo, de una línea a 100 % y sin partirse a 200 %.
        final greeting = find.textContaining('Ana');
        expect(greeting, findsOneWidget);
        expect(paragraph(tester, greeting).didExceedMaxLines, isFalse);
      },
    );
  }

  testWidgets('a 390 dp el saludo corto cabe en una línea junto a los iconos', (
    tester,
  ) async {
    await pump(tester);
    // «Buenas tardes, Ana» no cabe al lado de racha, Comunidad y campana.
    expect(find.text('Hola, Ana'), findsOneWidget);
    final greeting = tester.getRect(find.text('Hola, Ana'));
    final bell = tester.getRect(find.byTooltip('Notificaciones, 1 sin leer'));
    expect(greeting.right, lessThanOrEqualTo(bell.left));
    // La fecha va debajo, a todo el ancho de la cabecera.
    expect(tester.getRect(date).top, greaterThanOrEqualTo(greeting.bottom));
  });

  testWidgets('con sitio, el saludo largo del momento del día', (tester) async {
    await pump(tester, width: 900);
    expect(find.text('Buenas tardes, Ana'), findsOneWidget);
  });
}
