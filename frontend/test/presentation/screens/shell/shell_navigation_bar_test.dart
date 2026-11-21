import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/shell/widgets/shell_navigation_bar.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

/// La barra de pestañas en el peor caso pedido (ADR 0041): 360 px, texto al
/// 200 % y los cuatro idiomas. Ninguna etiqueta se desborda ni tapa a otra.
void main() {
  for (final lang in AppLocalizations.supportedLocales) {
    testWidgets('360 px y texto al 200 % en ${lang.languageCode}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: lang,
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
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return Scaffold(
                bottomNavigationBar: ShellNavigationBar(
                  selectedIndex: 4,
                  onSelected: (_) {},
                  destinations: [
                    (
                      icon: AppIcons.tabHome,
                      selected: AppIcons.tabHomeSelected,
                      label: l10n.tabHome,
                    ),
                    (
                      icon: AppIcons.tabCalendar,
                      selected: AppIcons.tabCalendarSelected,
                      label: l10n.tabCalendar,
                    ),
                    (
                      icon: AppIcons.tabAcademic,
                      selected: AppIcons.tabAcademicSelected,
                      label: l10n.tabAcademic,
                    ),
                    (
                      icon: AppIcons.tabTraining,
                      selected: AppIcons.tabTrainingSelected,
                      label: l10n.tabTraining,
                    ),
                    (
                      icon: AppIcons.tabYou,
                      selected: AppIcons.tabYouSelected,
                      label: l10n.tabYou,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final labels = [
        l10n.tabHome,
        l10n.tabCalendar,
        l10n.tabAcademic,
        l10n.tabTraining,
        l10n.tabYou,
      ];
      final boxes = [
        for (final label in labels)
          tester.getRect(find.text(label).hitTestable().first),
      ];
      for (var i = 0; i < boxes.length; i++) {
        // Dentro de la pantalla y sin pisar la etiqueta de al lado.
        expect(boxes[i].left, greaterThanOrEqualTo(0), reason: labels[i]);
        expect(boxes[i].right, lessThanOrEqualTo(360), reason: labels[i]);
        if (i > 0) {
          expect(
            boxes[i].left,
            greaterThanOrEqualTo(boxes[i - 1].right),
            reason: '${labels[i - 1]} / ${labels[i]}',
          );
        }
      }
      // Cada etiqueta en una sola línea: nada de «Calendar/io».
      for (final label in labels) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label).hitTestable().first,
        );
        final lines = paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: label.length),
            )
            .map((b) => b.top.round())
            .toSet();
        expect(lines, hasLength(1), reason: label);
      }
      // El nombre entero sigue disponible al mantener pulsado.
      expect(find.byType(Tooltip), findsAtLeastNWidgets(labels.length));
    });
  }
}
