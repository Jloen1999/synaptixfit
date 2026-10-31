import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/models/profile/enrollment_proposal.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/profile/enrollment_import/bloc/enrollment_import_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/enrollment_import/page/enrollment_import_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

class _MockBloc extends MockBloc<EnrollmentImportEvent, EnrollmentImportState>
    implements EnrollmentImportBloc {}

/// Datos inventados: nunca se usan documentos reales en los tests.
void main() {
  late _MockBloc bloc;

  setUp(() {
    bloc = _MockBloc();
    getIt.registerFactory<EnrollmentImportBloc>(() => bloc);
  });

  tearDown(() => getIt.unregister<EnrollmentImportBloc>());

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = Size(360, 2400 * textScale);
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
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const EnrollmentImportPage(),
      ),
    );
    await tester.pump();
  }

  testWidgets('sin permiso no se puede elegir el PDF', (tester) async {
    when(() => bloc.state).thenReturn(const EnrollmentImportState());
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Tus datos, protegidos'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Elegir PDF'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('la revisión se ve bien con texto al 200 %', (tester) async {
    when(() => bloc.state).thenReturn(
      const EnrollmentImportState(
        consent: true,
        step: EnrollmentStep.review,
        selected: {0},
        proposal: EnrollmentProposal(
          degreeName: 'Grado en Ingeniería de Ejemplo',
          universityName: 'Universidad de Ejemplo',
          academicYear: '2024-25',
          subjects: [
            EnrollmentSubject(
              name: 'Metodología y desarrollo de aplicaciones',
              course: 4,
              credits: 6,
              timesEnrolled: 2,
            ),
            EnrollmentSubject(name: 'Redes', alreadyAdded: true),
          ],
        ),
      ),
    );
    await pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Ya la tienes', skipOffstage: false), findsOneWidget);
  });
}
