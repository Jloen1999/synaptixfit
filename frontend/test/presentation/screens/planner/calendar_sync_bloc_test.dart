import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/planner_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/planner/calendar_feed.dart';
import 'package:synaptixfit/domain/models/planner/planner_ai.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/planner/create_calendar_feed_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/get_calendar_feed_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/import_general_calendar_use_case.dart';
import 'package:synaptixfit/domain/use_cases/planner/revoke_calendar_feed_use_case.dart';
import 'package:synaptixfit/presentation/screens/planner/calendar_sync/bloc/calendar_sync_bloc.dart';

class _GetFeed extends Mock implements GetCalendarFeedUseCaseContract {}

class _CreateFeed extends Mock implements CreateCalendarFeedUseCaseContract {}

class _RevokeFeed extends Mock implements RevokeCalendarFeedUseCaseContract {}

class _ImportGeneral extends Mock
    implements ImportGeneralCalendarUseCaseContract {}

void main() {
  late _GetFeed getFeed;
  late _CreateFeed createFeed;
  late _RevokeFeed revokeFeed;
  late _ImportGeneral importGeneral;
  final created = DateTime(2026, 10, 30, 10);
  final link = CalendarFeedLink(
    url: 'https://api.example/api/v1/planner/calendar-feed/abc.ics',
    createdAt: created,
  );

  setUp(() {
    getFeed = _GetFeed();
    createFeed = _CreateFeed();
    revokeFeed = _RevokeFeed();
    importGeneral = _ImportGeneral();
    when(
      () => getFeed(),
    ).thenAnswer((_) async => const Success(CalendarFeedStatus()));
    when(() => createFeed()).thenAnswer((_) async => Success(link));
    when(() => revokeFeed()).thenAnswer((_) async => const Success(unit));
  });

  CalendarSyncBloc build() => CalendarSyncBloc(
    getFeed: getFeed,
    createFeed: createFeed,
    revokeFeed: revokeFeed,
    importGeneral: importGeneral,
  );

  test('el enlace webcal abre la app de calendario con la misma dirección', () {
    expect(
      link.webcalUrl,
      'webcal://api.example/api/v1/planner/calendar-feed/abc.ics',
    );
  });

  blocTest<CalendarSyncBloc, CalendarSyncState>(
    'crear muestra el enlace una vez y desactivar lo quita y lo cuenta',
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarSyncEvent.started());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const CalendarSyncEvent.feedCreated());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.link, link);
      expect(bloc.state.feed.active, isTrue);
      bloc.add(const CalendarSyncEvent.feedRevoked());
      await Future<void>.delayed(Duration.zero);
    },
    verify: (bloc) {
      expect(bloc.state.link, isNull);
      expect(bloc.state.feed.active, isFalse);
      expect(bloc.state.feedAction, isNull);
      expect(bloc.state.revokedCount, 1);
    },
  );

  blocTest<CalendarSyncBloc, CalendarSyncState>(
    'desactivar un enlace que ya no existe deja la pantalla sin enlace',
    setUp: () => when(() => revokeFeed()).thenAnswer(
      (_) async =>
          const Failure(AppError.business('PLANNER_CALENDAR_FEED_NOT_FOUND')),
    ),
    build: build,
    seed: () => const CalendarSyncState(
      status: CalendarSyncStatus.ready,
      feed: CalendarFeedStatus(active: true),
    ),
    act: (bloc) => bloc.add(const CalendarSyncEvent.feedRevoked()),
    verify: (bloc) {
      expect(bloc.state.feed.active, isFalse);
      expect(
        bloc.state.actionError,
        const AppError.business('PLANNER_CALENDAR_FEED_NOT_FOUND'),
      );
    },
  );

  blocTest<CalendarSyncBloc, CalendarSyncState>(
    'importar el Campus Virtual va sin asignatura y guarda el resultado',
    setUp: () =>
        when(
          () => importGeneral(url: 'https://campus.example/cal.ics'),
        ).thenAnswer(
          (_) async => const Success(
            IcsImportResult(
              match: IcsMatch.full,
              totalEvents: 5,
              matchingEvents: 2,
              classes: 0,
              exams: 1,
              deliveries: 2,
              created: 3,
              updated: 0,
              imported: true,
            ),
          ),
        ),
    build: build,
    seed: () => const CalendarSyncState(status: CalendarSyncStatus.ready),
    act: (bloc) => bloc.add(
      const CalendarSyncEvent.importRequested(
        '  https://campus.example/cal.ics ',
      ),
    ),
    verify: (bloc) {
      expect(bloc.state.importing, isFalse);
      expect(bloc.state.importResult!.deliveries, 2);
    },
  );

  blocTest<CalendarSyncBloc, CalendarSyncState>(
    'con el campo vacío lo señala sin llamar al servidor',
    build: build,
    seed: () => const CalendarSyncState(status: CalendarSyncStatus.ready),
    act: (bloc) => bloc.add(const CalendarSyncEvent.importRequested('  ')),
    verify: (bloc) {
      expect(bloc.state.urlMissing, isTrue);
      verifyNever(() => importGeneral(url: any(named: 'url')));
    },
  );

  blocTest<CalendarSyncBloc, CalendarSyncState>(
    'un fallo al importar queda junto al campo sin perder la pantalla',
    setUp: () => when(
      () => importGeneral(url: any(named: 'url')),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    seed: () => const CalendarSyncState(status: CalendarSyncStatus.ready),
    act: (bloc) =>
        bloc.add(const CalendarSyncEvent.importRequested('https://x.ics')),
    verify: (bloc) {
      expect(bloc.state.status, CalendarSyncStatus.ready);
      expect(bloc.state.importError, const AppError.network());
      expect(bloc.state.actionError, isNull);
    },
  );
}
