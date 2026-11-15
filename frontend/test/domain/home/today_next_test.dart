import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/home_day_state.dart';
import 'package:synaptixfit/domain/enums/home_event_kind.dart';
import 'package:synaptixfit/domain/enums/home_event_type.dart';
import 'package:synaptixfit/domain/enums/item_time_status.dart';
import 'package:synaptixfit/domain/models/home/home_dashboard.dart';
import 'package:synaptixfit/domain/models/home/today_next.dart';

/// El botón de «Tu día» para el evento que destaca el servidor (ADR 0050).
void main() {
  HomeTodayEvent event(
    HomeEventType type, {
    ItemTimeStatus status = ItemTimeStatus.upcoming,
    HomeEventKind kind = HomeEventKind.block,
    bool routine = false,
    bool completed = false,
  }) => HomeTodayEvent(
    id: 'e',
    kind: kind,
    type: type,
    title: 'Evento',
    completed: completed,
    status: status,
    routineId: routine ? 'r' : null,
    routineDayId: routine ? 'd' : null,
  );

  const pending = HomeTodaySummary(
    total: 1,
    nextEventId: 'e',
    state: HomeDayState.pending,
  );
  const missedLeft = HomeTodaySummary(
    total: 1,
    missed: 1,
    nextEventId: 'e',
    state: HomeDayState.missedLeft,
  );

  test('con algo por hacer, el botón según el tipo', () {
    expect(
      TodayAction.of(pending, event(HomeEventType.study)),
      TodayAction.focus,
    );
    expect(
      TodayAction.of(pending, event(HomeEventType.review)),
      TodayAction.focus,
    );
    expect(
      TodayAction.of(pending, event(HomeEventType.sport, routine: true)),
      TodayAction.train,
    );
    // Un partido suelto no arranca otra rutina; una clase se ve en la agenda.
    expect(TodayAction.of(pending, event(HomeEventType.sport)), isNull);
    expect(TodayAction.of(pending, event(HomeEventType.classSession)), isNull);
    // Lo personal se marca cuando está en curso.
    expect(TodayAction.of(pending, event(HomeEventType.personal)), isNull);
    expect(
      TodayAction.of(
        pending,
        event(HomeEventType.personal, status: ItemTimeStatus.inProgress),
      ),
      TodayAction.markDone,
    );
    // Una entrega de hoy se puede adelantar.
    expect(
      TodayAction.of(
        pending,
        event(HomeEventType.delivery, kind: HomeEventKind.deadline),
      ),
      TodayAction.markDone,
    );
  });

  test('lo que quedó sin hacer se marca; un día de rutina se empieza', () {
    for (final type in [
      HomeEventType.study,
      HomeEventType.sport,
      HomeEventType.personal,
    ]) {
      expect(
        TodayAction.of(missedLeft, event(type, status: ItemTimeStatus.missed)),
        TodayAction.markDone,
        reason: '$type',
      );
    }
    expect(
      TodayAction.of(
        missedLeft,
        event(
          HomeEventType.sport,
          status: ItemTimeStatus.missed,
          routine: true,
        ),
      ),
      TodayAction.train,
    );
  });

  test('sin nada pendiente, añadir; ya marcado, sin botón', () {
    expect(
      TodayAction.of(const HomeTodaySummary(), null),
      TodayAction.addEvent,
    );
    expect(
      TodayAction.of(
        const HomeTodaySummary(done: 1, total: 1, state: HomeDayState.allDone),
        null,
      ),
      TodayAction.addEvent,
    );
    expect(
      TodayAction.of(pending, event(HomeEventType.study, completed: true)),
      isNull,
    );
    // El evento del resumen aún no ha llegado: sin botón.
    expect(TodayAction.of(pending, null), isNull);
  });
}
