import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/guide_id.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/guides/mark_guide_seen_use_case.dart';
import 'package:synaptixfit/domain/use_cases/guides/should_show_guide_use_case.dart';
import 'package:synaptixfit/presentation/l10n/gen_l10n/app_localizations.dart';
import 'package:synaptixfit/presentation/screens/auth/session/bloc/session_bloc.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/guide_tour_bloc.dart';
import 'package:synaptixfit/presentation/screens/shell/widgets/first_time_guide.dart';
import 'package:synaptixfit/presentation/theme/app_theme.dart';
import 'package:synaptixfit/presentation/widgets/widgets.dart';

import '../profile/profile_fixtures.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

/// Guías vistas en memoria (lo que haría el teléfono).
class _Seen {
  final guides = <GuideId>{};
  bool failing = false;
}

class _ShouldShow implements ShouldShowGuideUseCaseContract {
  _ShouldShow(this.seen);

  final _Seen seen;

  @override
  Future<AppResult<bool>> call({
    required String accountId,
    required GuideId guide,
  }) async => seen.failing
      ? const Failure(AppError.unknown())
      : Success(!seen.guides.contains(guide));
}

class _MarkSeen implements MarkGuideSeenUseCaseContract {
  _MarkSeen(this.seen);

  final _Seen seen;

  @override
  Future<AppResult<Unit>> call({
    required String accountId,
    required GuideId guide,
  }) async {
    seen.guides.add(guide);
    return const Success(unit);
  }
}

/// Pantalla de prueba con una parte que señalar.
class _Screen extends StatefulWidget {
  const _Screen({required this.ready});

  final ValueNotifier<bool> ready;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  final _target = GlobalKey();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.ready,
    builder: (context, ready, _) => FirstTimeGuide(
      guide: GuideId.home,
      ready: ready,
      steps: (_) => [
        AppGuideStep(target: _target, title: 'Tu día', body: 'Lo que toca.'),
      ],
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(key: _target, height: 48, child: const Text('Hoy')),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const AlertDialog(content: Text('Insignia')),
                  ),
                  child: const Text('Diálogo'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// `FirstTimeGuide` (ADR 0049): sale una vez, con la pantalla cargada y nada
/// encima, y no cuando se llega desde un aviso.
void main() {
  late _Seen seen;
  late _MockSessionBloc session;
  late DateTime now;

  setUp(() {
    seen = _Seen();
    session = _MockSessionBloc();
    now = DateTime(2026, 11, 16, 10);
    when(
      () => session.state,
    ).thenReturn(const SessionState.authenticated(testAccount));
    when(() => session.account).thenReturn(testAccount);
  });

  GuideCoordinator coordinator() => GuideCoordinator(
    createBloc: () =>
        GuideTourBloc(shouldShow: _ShouldShow(seen), markSeen: _MarkSeen(seen)),
    clock: () => now,
  );

  Future<void> pump(
    WidgetTester tester, {
    required ValueNotifier<bool> ready,
    GuideCoordinator? guides,
    bool scoped = true,
  }) async {
    final c = guides ?? coordinator();
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
        navigatorObservers: [c.observer],
        builder: (context, child) =>
            scoped ? GuideScope(coordinator: c, child: child!) : child!,
        home: BlocProvider<SessionBloc>.value(
          value: session,
          child: _Screen(ready: ready),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('espera a que la pantalla cargue y sale una sola vez', (
    tester,
  ) async {
    final ready = ValueNotifier(false);
    await pump(tester, ready: ready);
    expect(find.text('Tu día'), findsNothing, reason: 'aún cargando');
    ready.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Tu día'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(seen.guides, {GuideId.home});
    // Otra visita: ya no sale.
    await tester.pumpWidget(const SizedBox());
    await pump(tester, ready: ValueNotifier(true));
    expect(find.text('Tu día'), findsNothing);
  });

  testWidgets('cerrarla con «atrás» también cuenta como vista', (tester) async {
    await pump(tester, ready: ValueNotifier(true));
    expect(find.text('Tu día'), findsOneWidget);
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Tu día'), findsNothing);
    expect(seen.guides, contains(GuideId.home));
  });

  testWidgets('si se llega desde un aviso, espera a la próxima vez', (
    tester,
  ) async {
    final guides = coordinator()..markExternalArrival();
    await pump(tester, ready: ValueNotifier(true), guides: guides);
    expect(find.text('Tu día'), findsNothing);
    expect(seen.guides, isEmpty, reason: 'no se apunta como vista');
    // Pasado el rato del aviso, al volver a entrar sí sale.
    now = now.add(GuideCoordinator.externalWindow);
    await tester.pumpWidget(const SizedBox());
    await pump(tester, ready: ValueNotifier(true), guides: guides);
    expect(find.text('Tu día'), findsOneWidget);
  });

  testWidgets('con un diálogo encima espera a que se cierre', (tester) async {
    final ready = ValueNotifier(false);
    await pump(tester, ready: ready);
    await tester.tap(find.text('Diálogo'));
    await tester.pumpAndSettle();
    ready.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Tu día'), findsNothing);
    Navigator.of(tester.element(find.text('Insignia'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Tu día'), findsOneWidget);
  });

  testWidgets('si no se puede leer lo visto, no molesta', (tester) async {
    seen.failing = true;
    await pump(tester, ready: ValueNotifier(true));
    expect(find.text('Tu día'), findsNothing);
  });

  testWidgets('sin GuideScope (p. ej. un test de pantalla) no hace nada', (
    tester,
  ) async {
    await pump(tester, ready: ValueNotifier(true), scoped: false);
    expect(find.text('Tu día'), findsNothing);
    expect(find.text('Hoy'), findsOneWidget);
  });

  group('GuideTourBloc', () {
    blocTest<GuideTourBloc, GuideTourState>(
      'pregunta una vez y, al cerrarla, la apunta como vista',
      build: () => GuideTourBloc(
        shouldShow: _ShouldShow(seen),
        markSeen: _MarkSeen(seen),
      ),
      act: (bloc) async {
        bloc
          ..add(
            const GuideTourEvent.requested(
              guide: GuideId.calendar,
              accountId: 'u1',
            ),
          )
          ..add(
            const GuideTourEvent.requested(
              guide: GuideId.calendar,
              accountId: 'u1',
            ),
          );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GuideTourEvent.closed());
      },
      expect: () => const [
        GuideTourState(
          status: GuideTourStatus.checking,
          guide: GuideId.calendar,
          accountId: 'u1',
        ),
        GuideTourState(
          status: GuideTourStatus.showing,
          guide: GuideId.calendar,
          accountId: 'u1',
        ),
        GuideTourState(
          status: GuideTourStatus.saving,
          guide: GuideId.calendar,
          accountId: 'u1',
        ),
        GuideTourState(
          status: GuideTourStatus.done,
          guide: GuideId.calendar,
          accountId: 'u1',
        ),
      ],
      verify: (_) => expect(seen.guides, {GuideId.calendar}),
    );

    blocTest<GuideTourBloc, GuideTourState>(
      'ya vista: queda hecha sin enseñarse',
      setUp: () => seen.guides.add(GuideId.gym),
      build: () => GuideTourBloc(
        shouldShow: _ShouldShow(seen),
        markSeen: _MarkSeen(seen),
      ),
      act: (bloc) => bloc.add(
        const GuideTourEvent.requested(guide: GuideId.gym, accountId: 'u1'),
      ),
      expect: () => const [
        GuideTourState(
          status: GuideTourStatus.checking,
          guide: GuideId.gym,
          accountId: 'u1',
        ),
        GuideTourState(
          status: GuideTourStatus.done,
          guide: GuideId.gym,
          accountId: 'u1',
        ),
      ],
    );

    blocTest<GuideTourBloc, GuideTourState>(
      'sin nada que señalar no se apunta como vista',
      build: () => GuideTourBloc(
        shouldShow: _ShouldShow(seen),
        markSeen: _MarkSeen(seen),
      ),
      act: (bloc) async {
        bloc.add(
          const GuideTourEvent.requested(guide: GuideId.focus, accountId: 'u1'),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const GuideTourEvent.abandoned());
      },
      skip: 2,
      expect: () => const [
        GuideTourState(
          status: GuideTourStatus.done,
          guide: GuideId.focus,
          accountId: 'u1',
        ),
      ],
      verify: (_) => expect(seen.guides, isEmpty),
    );
  });
}
