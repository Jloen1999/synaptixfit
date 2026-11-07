import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synaptixfit/domain/models/profile/wellness_profile.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/profile/widgets/academic_profile_form.dart';
import 'package:synaptixfit/presentation/screens/profile/widgets/wellness_profile_form.dart';
import 'package:synaptixfit/presentation/theme/app_palette.dart';

import 'profile_fixtures.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(extensions: const [AppPalette.light]),
  locale: const Locale('es'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: ListView(children: [child])),
);

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('el formulario físico valida y envía el borrador', (
    tester,
  ) async {
    WellnessProfileDraft? sent;
    await tester.pumpWidget(
      _wrap(
        WellnessProfileForm(
          initial: testWellness,
          submitLabel: 'Guardar',
          saving: false,
          suggesting: false,
          suggestions: null,
          onSubmit: (d) => sent = d,
          onSuggest: (_, _, _) {},
        ),
      ),
    );
    expect(find.textContaining('IMC estimado'), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(sent, isNotNull);
    // La edad ya no se pide aquí (ADR 0036): sale de la fecha de nacimiento.
    expect(sent!.age, isNull);
    expect(sent!.availableDays, [1, 3, 5]);
    expect(sent!.minutesPerSession, 45);
  });

  testWidgets('el formulario físico vacío no envía', (tester) async {
    WellnessProfileDraft? sent;
    await tester.pumpWidget(
      _wrap(
        WellnessProfileForm(
          initial: null,
          submitLabel: 'Guardar',
          saving: false,
          suggesting: false,
          suggestions: null,
          onSubmit: (d) => sent = d,
          onSuggest: (_, _, _) {},
        ),
      ),
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(sent, isNull);
  });

  testWidgets('el formulario académico se pinta con los datos previos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AcademicProfileForm(
          initial: testAcademic,
          selectedDegree: null,
          submitLabel: 'Guardar',
          saving: false,
          onPickDegree: () {},
          onClearDegree: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    expect(find.text('Grado en Informática'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
