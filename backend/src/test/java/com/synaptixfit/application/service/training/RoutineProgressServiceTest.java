package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.event.training.RoutineCompleted;
import com.synaptixfit.domain.event.training.RoutineDaysSkipped;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.PendingDay;
import com.synaptixfit.domain.model.training.ProgressStatus;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineStatus;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.TrainingSession;
import com.synaptixfit.domain.model.training.WeekType;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Próximo día, saltar, recuperar y repetir ciclo de la rutina en curso. */
class RoutineProgressServiceTest {

    private static final UUID USER = UUID.randomUUID();
    /** Lunes 5 de octubre de 2026. */
    private static final Instant NOW = Instant.parse("2026-10-05T10:00:00Z");

    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final Map<UUID, List<Instant>> calendar = new HashMap<>();
    private final List<DomainEvent> events = new ArrayList<>();
    private RoutineProgressService service;
    private Routine routine;
    private RoutineDay monday;
    private RoutineDay thursday;

    @BeforeEach
    void setUp() {
        service = new RoutineProgressService(routines, sessions, (userId, routineId) -> calendar, events::add,
                Clock.fixed(NOW, ZoneOffset.UTC), ZoneOffset.UTC);
        var bench = TrainingFakes.strength("Press de banca", "Pectoral mayor").toRef();
        ExerciseParameters p = new ExerciseParameters(3, 10, 90, 50.0, null, null, null, null);
        monday = RoutineDay.create(1, "Empuje");
        monday.addExercise(bench, p);
        thursday = RoutineDay.create(4, null);
        thursday.addExercise(bench, p);
        routine = routines.save(Routine.create(USER, "Mi rutina", null, Visibility.PRIVATE, TrainingGoal.HYPERTROPHY,
                null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD, List.of(monday, thursday))), NOW));
    }

    @Test
    void pendingDayUsesTheCalendarAndTheOpenSessions() {
        PendingDay first = service.pendingDay(USER).orElseThrow();
        assertThat(first.day().id()).isEqualTo(monday.id());
        assertThat(first.scheduledDate()).isEqualTo(LocalDate.of(2026, 10, 5));

        calendar.put(monday.id(), List.of(Instant.parse("2026-10-06T18:00:00Z")));
        assertThat(service.pendingDay(USER).orElseThrow().scheduledDate()).isEqualTo(LocalDate.of(2026, 10, 6));

        TrainingSession open = sessions.save(TrainingSession.start(USER, routine.id(), thursday.id(),
                NOW.minus(Duration.ofMinutes(20))));
        PendingDay active = service.pendingDay(USER).orElseThrow();
        assertThat(active.day().id()).isEqualTo(thursday.id());
        assertThat(active.status()).isEqualTo(ProgressStatus.IN_PROGRESS);
        assertThat(open.isStale(NOW)).isFalse();
        assertThat(service.pendingDay(UUID.randomUUID())).isEmpty();
    }

    @Test
    void skippingTheLastDaysClosesTheCycleAndUnskipReopensIt() {
        service.skip(USER, routine.id(), monday.id());
        assertThat(events).filteredOn(e -> e instanceof RoutineDaysSkipped).hasSize(1);
        assertThat(service.pendingDay(USER).orElseThrow().day().id()).isEqualTo(thursday.id());

        service.skip(USER, routine.id(), thursday.id());
        assertThat(routine.status()).isEqualTo(RoutineStatus.COMPLETED);
        assertThat(events).filteredOn(e -> e instanceof RoutineCompleted).hasSize(1);
        assertThat(service.pendingDay(USER)).isEmpty();

        service.unskip(USER, routine.id(), thursday.id());
        assertThat(routine.status()).isEqualTo(RoutineStatus.ACTIVE);
        assertThat(routine.day(thursday.id()).status()).isEqualTo(ProgressStatus.PENDING);
    }

    @Test
    void restartStartsANewCycleAndPausesTheOtherActiveRoutine() {
        service.skip(USER, routine.id(), monday.id());
        service.skip(USER, routine.id(), thursday.id());
        Routine other = routines.save(Routine.create(USER, "Otra", null, Visibility.PRIVATE,
                TrainingGoal.HYPERTROPHY, null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD,
                        List.of(RoutineDay.create(1, null)))), NOW));

        Routine restarted = service.restart(USER, routine.id());

        assertThat(restarted.status()).isEqualTo(RoutineStatus.ACTIVE);
        assertThat(restarted.startDate()).isEqualTo(LocalDate.of(2026, 10, 5));
        assertThat(restarted.completedDays() + restarted.skippedDays()).isZero();
        assertThat(other.status()).isEqualTo(RoutineStatus.PAUSED);
        assertThatThrownBy(() -> service.restart(UUID.randomUUID(), routine.id()))
                .isInstanceOf(RoutineNotFoundException.class);
    }
}
