import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/enums/legal_document_kind.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/profile/legal_document.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/repositories/legal_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/auth/register_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/accept_legal_terms_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_legal_acceptance_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_legal_document_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/register/bloc/register_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/legal/bloc/legal_acceptance_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/legal/bloc/legal_document_bloc.dart';
import 'package:synaptixfit/presentation/screens/profile/legal/page/legal_document_page.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';

/// Servidor de mentira: la versión vigente y la última aceptada.
class _FakeLegal implements LegalRepositoryContract {
  String current = '2026-11-04';
  String? accepted;
  final acceptedCalls = <String>[];
  int acceptanceReads = 0;
  bool failAccept = false;
  bool outdated = false;
  bool failDocument = false;

  @override
  Future<AppResult<LegalAcceptance>> acceptance() async {
    acceptanceReads++;
    return Success(
      LegalAcceptance(
        currentVersion: current,
        acceptedVersion: accepted,
        mustAccept: accepted != current,
      ),
    );
  }

  @override
  Future<AppResult<Unit>> accept(String version) async {
    if (failAccept) return const Failure(AppError.network());
    if (outdated) {
      return const Failure(AppError.business('LEGAL_VERSION_OUTDATED'));
    }
    acceptedCalls.add(version);
    accepted = version;
    return const Success(unit);
  }

  @override
  Future<AppResult<LegalDocument>> document(
    LegalDocumentKind kind, {
    required String language,
  }) async => failDocument
      ? const Failure(AppError.network())
      : Success(
          LegalDocument(
            kind: kind,
            language: language,
            version: current,
            title: 'Política',
            blocks: const [],
          ),
        );
}

class _MockRegister extends Mock implements RegisterUseCaseContract {}

class _MockDocumentBloc extends MockBloc<LegalDocumentEvent, LegalDocumentState>
    implements LegalDocumentBloc {}

void main() {
  late _FakeLegal legal;

  setUp(() => legal = _FakeLegal());

  LegalAcceptanceBloc acceptanceBloc() => LegalAcceptanceBloc(
    getAcceptance: GetLegalAcceptanceUseCase(legal),
    accept: AcceptLegalTermsUseCase(legal),
  );

  group('Aceptar la política al entrar', () {
    blocTest<LegalAcceptanceBloc, LegalAcceptanceState>(
      'quien nunca la aceptó (entró con Google) debe aceptarla',
      build: acceptanceBloc,
      act: (bloc) => bloc.add(const LegalAcceptanceEvent.checked()),
      expect: () => [
        const LegalAcceptanceState(
          status: LegalGateStatus.required,
          currentVersion: '2026-11-04',
        ),
      ],
    );

    blocTest<LegalAcceptanceBloc, LegalAcceptanceState>(
      'si cambió la versión, se le dice que se ha actualizado',
      setUp: () => legal.accepted = '2026-01-01',
      build: acceptanceBloc,
      act: (bloc) => bloc.add(const LegalAcceptanceEvent.checked()),
      expect: () => [
        const LegalAcceptanceState(
          status: LegalGateStatus.required,
          currentVersion: '2026-11-04',
          updated: true,
        ),
      ],
    );

    blocTest<LegalAcceptanceBloc, LegalAcceptanceState>(
      'con la vigente aceptada deja pasar',
      setUp: () => legal.accepted = legal.current,
      build: acceptanceBloc,
      act: (bloc) => bloc.add(const LegalAcceptanceEvent.checked()),
      expect: () => [
        const LegalAcceptanceState(status: LegalGateStatus.accepted),
      ],
    );

    blocTest<LegalAcceptanceBloc, LegalAcceptanceState>(
      '«Aceptar y seguir» acepta la versión que se enseñó, sin volver a preguntar',
      setUp: () => legal.current = '2026-12-01',
      seed: () => const LegalAcceptanceState(
        status: LegalGateStatus.required,
        currentVersion: '2026-11-04',
      ),
      build: acceptanceBloc,
      act: (bloc) => bloc.add(const LegalAcceptanceEvent.accepted()),
      expect: () => [
        const LegalAcceptanceState(
          status: LegalGateStatus.required,
          currentVersion: '2026-11-04',
          accepting: true,
        ),
        const LegalAcceptanceState(
          status: LegalGateStatus.accepted,
          currentVersion: '2026-11-04',
        ),
      ],
      verify: (_) => expect(legal.acceptedCalls, ['2026-11-04']),
    );

    blocTest<LegalAcceptanceBloc, LegalAcceptanceState>(
      'si la política cambió mientras se leía, explica el error y enseña la nueva',
      setUp: () {
        legal.outdated = true;
        legal.current = '2026-12-01';
      },
      seed: () => const LegalAcceptanceState(
        status: LegalGateStatus.required,
        currentVersion: '2026-11-04',
      ),
      build: acceptanceBloc,
      act: (bloc) => bloc.add(const LegalAcceptanceEvent.accepted()),
      skip: 1,
      expect: () => [
        const LegalAcceptanceState(
          status: LegalGateStatus.required,
          currentVersion: '2026-11-04',
          error: AppError.business('LEGAL_VERSION_OUTDATED'),
        ),
        const LegalAcceptanceState(
          status: LegalGateStatus.required,
          currentVersion: '2026-12-01',
          error: AppError.business('LEGAL_VERSION_OUTDATED'),
        ),
      ],
    );

    blocTest<LegalAcceptanceBloc, LegalAcceptanceState>(
      'sin conexión sigue pidiéndola y explica el error',
      setUp: () => legal.failAccept = true,
      seed: () => const LegalAcceptanceState(
        status: LegalGateStatus.required,
        currentVersion: '2026-11-04',
      ),
      build: acceptanceBloc,
      act: (bloc) => bloc.add(const LegalAcceptanceEvent.accepted()),
      expect: () => [
        const LegalAcceptanceState(
          status: LegalGateStatus.required,
          currentVersion: '2026-11-04',
          accepting: true,
        ),
        const LegalAcceptanceState(
          status: LegalGateStatus.required,
          currentVersion: '2026-11-04',
          error: AppError.network(),
        ),
      ],
    );

    blocTest<LegalAcceptanceBloc, LegalAcceptanceState>(
      'al cerrar sesión se olvida: la siguiente cuenta se comprueba de nuevo',
      seed: () => const LegalAcceptanceState(status: LegalGateStatus.accepted),
      build: acceptanceBloc,
      act: (bloc) => bloc.add(const LegalAcceptanceEvent.reset()),
      expect: () => [const LegalAcceptanceState()],
    );

    test('aceptar solo envía la versión recibida: no consulta la vigente', () async {
      await AcceptLegalTermsUseCase(legal)('2026-11-04');
      expect(legal.acceptedCalls, ['2026-11-04']);
      expect(legal.acceptanceReads, 0);
    });
  });

  group('Registro con correo', () {
    const account = Account(
      id: '1',
      email: 'a@b.co',
      fullName: 'Ana',
      level: 1,
      levelXp: 0,
      levelThreshold: 100,
      streak: 0,
      privacy: Visibility.private,
      role: UserRole.user,
      hasPassword: true,
      googleLinked: false,
    );
    late _MockRegister register;

    setUp(() => register = _MockRegister());

    RegisterBloc build() => RegisterBloc(
      register: register,
      getDocument: GetLegalDocumentUseCase(legal),
    );

    void answer(AppResult<Account> result) => when(
      () => register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        fullName: any(named: 'fullName'),
        acceptedLegalVersion: any(named: 'acceptedLegalVersion'),
      ),
    ).thenAnswer((_) async => result);

    blocTest<RegisterBloc, RegisterState>(
      'el alta lleva la versión de la política que se aceptó en la casilla',
      setUp: () => answer(const Success(account)),
      build: build,
      act: (bloc) => bloc.add(
        const RegisterEvent.submitted(
          fullName: 'Ana',
          email: 'a@b.co',
          password: 'secret123',
        ),
      ),
      expect: () => [
        const RegisterState.submitting(),
        const RegisterState.success(account),
      ],
      verify: (_) => verify(
        () => register(
          email: 'a@b.co',
          password: 'secret123',
          fullName: 'Ana',
          acceptedLegalVersion: '2026-11-04',
        ),
      ).called(1),
    );

    blocTest<RegisterBloc, RegisterState>(
      'sin poder leer la política, crea la cuenta igual (se pedirá al entrar)',
      setUp: () {
        legal.failDocument = true;
        answer(const Success(account));
      },
      build: build,
      act: (bloc) => bloc.add(
        const RegisterEvent.submitted(
          fullName: 'Ana',
          email: 'a@b.co',
          password: 'secret123',
        ),
      ),
      expect: () => [
        const RegisterState.submitting(),
        const RegisterState.success(account),
      ],
      verify: (_) => verify(
        () => register(
          email: 'a@b.co',
          password: 'secret123',
          fullName: 'Ana',
          acceptedLegalVersion: null,
        ),
      ).called(1),
    );

    blocTest<RegisterBloc, RegisterState>(
      'si el registro falla, lo explica',
      setUp: () => answer(const Failure(AppError.network())),
      build: build,
      act: (bloc) => bloc.add(
        const RegisterEvent.submitted(
          fullName: 'Ana',
          email: 'a@b.co',
          password: 'secret123',
        ),
      ),
      expect: () => [
        const RegisterState.submitting(),
        const RegisterState.failure(AppError.network()),
      ],
    );
  });

  group('Página de un texto legal', () {
    late _MockDocumentBloc bloc;

    setUp(() {
      bloc = _MockDocumentBloc();
      getIt.registerFactory<LegalDocumentBloc>(() => bloc);
    });

    tearDown(() => getIt.unregister<LegalDocumentBloc>());

    testWidgets('pinta títulos de sección como encabezados y la versión', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        const LegalDocumentState(
          loading: false,
          document: LegalDocument(
            kind: LegalDocumentKind.privacy,
            language: 'es',
            version: '2026-11-04',
            title: 'Política de privacidad',
            blocks: [
              LegalBlock(type: LegalBlockType.paragraph, text: 'Intro.'),
              LegalBlock(type: LegalBlockType.heading, text: 'Tus derechos'),
              LegalBlock(type: LegalBlockType.bullet, text: 'Exportar.'),
            ],
          ),
        ),
      );
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
          home: const LegalDocumentPage(kind: LegalDocumentKind.privacy),
        ),
      );
      await tester.pump();
      expect(find.text('Política de privacidad'), findsOneWidget);
      expect(find.textContaining('Versión del'), findsOneWidget);
      expect(find.text('Exportar.'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Tus derechos')),
        matchesSemantics(label: 'Tus derechos', isHeader: true),
      );
    });
    for (final (name, theme) in [
      ('claro', AppTheme.light),
      ('oscuro', AppTheme.dark),
    ]) {
      testWidgets('accesibilidad del texto legal, tema $name', (tester) async {
        when(() => bloc.state).thenReturn(
          const LegalDocumentState(
            loading: false,
            document: LegalDocument(
              kind: LegalDocumentKind.privacy,
              language: 'pt',
              version: '2026-11-04',
              title: 'Política de privacidad',
              blocks: [
                LegalBlock(
                  type: LegalBlockType.paragraph,
                  text: 'Escribe a privacidad@example.com o entra en https://synaptixfit.jloenit.dev.',
                ),
                LegalBlock(type: LegalBlockType.bullet, text: 'Exportar.'),
              ],
            ),
          ),
        );
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const LegalDocumentPage(kind: LegalDocumentKind.privacy),
          ),
        );
        await tester.pumpAndSettle();
        // Llega en otro idioma que el de la app: se avisa.
        expect(
          find.text('Este texto aún no está traducido a tu idioma.'),
          findsOneWidget,
        );
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
