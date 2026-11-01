package com.synaptixfit.application.service.planner;

import static com.synaptixfit.application.service.planner.PlannerFakes.at;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.planner.DistributeRoutineUseCase;
import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.application.port.input.planner.SuggestWeekPlanUseCase;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.FocusStats;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.model.planner.SuggestedBlock;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.model.planner.WeekPlanSuggestions;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class RoutineSuggestionFocusServiceTest {

    private PlannerFakes f;
    private RoutineRef routine;

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        UUID week1 = UUID.randomUUID();
        UUID week2 = UUID.randomUUID();
        routine = new RoutineRef(UUID.randomUUID(), "Fuerza", "Fuerza Máxima", 2, 8, List.of(
                new RoutineRef.Day(UUID.randomUUID(), week1, 1, 1, "Empuje"),
                new RoutineRef.Day(UUID.randomUUID(), week1, 1, 2, "Tirón"),
                new RoutineRef.Day(UUID.randomUUID(), week2, 2, 1, ""),
                new RoutineRef.Day(UUID.randomUUID(), week2, 2, 2, "Pierna")));
        f.directory.routines.put(f.user, Map.of(routine.id(), routine));
    }

    @Test
    void distributesRoutineDaysOnChosenWeekdaysSkippingBusySlotsAndThePast() {
        RoutineDistributionService service = distribution();
        // Miércoles a las 18:00 ocupado: la sesión pasa al primer hueco libre (19:00).
        f.blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                .range(new TimeRange(at(2, 18, 0), at(2, 19, 0))).type(ActivityType.CLASS).build());

        List<CalendarBlock> created = service.distribute(new DistributeRoutineUseCase.Command(f.user, routine.id(),
                Set.of(1, 3, 5), PlannerFakes.MONDAY.minusDays(7), LocalTime.of(18, 0), 60));

        assertThat(created).hasSize(4);
        assertThat(created).extracting(CalendarBlock::start)
                .containsExactly(at(0, 18, 0), at(2, 19, 0), at(4, 18, 0), at(7, 18, 0));
        assertThat(created.get(0).details().routineDayId()).isEqualTo(routine.days().get(0).id());
        assertThat(created.get(2).details().routineWeekId()).isEqualTo(routine.days().get(2).weekId());
        assertThat(created.get(0).details().topics()).isEqualTo("Semana 1 · Empuje");
        assertThat(created.get(2).details().topics()).isEqualTo("Semana 2 · Fuerza");
        assertThat(created).allSatisfy(b -> {
            assertThat(b.type()).isEqualTo(ActivityType.SPORT);
            assertThat(b.details().routineId()).isEqualTo(routine.id());
        });
    }

    @Test
    void withoutChosenWeekdaysEachDayGoesToItsPreferredWeekdayAndOnlyPendingDaysArePlaced() {
        UUID week1 = UUID.randomUUID();
        UUID week2 = UUID.randomUUID();
        RoutineRef partly = new RoutineRef(UUID.randomUUID(), "Tres días", "Fuerza Máxima", 2, 6, List.of(
                new RoutineRef.Day(UUID.randomUUID(), week1, 1, 1, "Empuje", false),
                new RoutineRef.Day(UUID.randomUUID(), week1, 1, 3, "Tirón", true),
                new RoutineRef.Day(UUID.randomUUID(), week1, 1, 5, "Pierna", true),
                new RoutineRef.Day(UUID.randomUUID(), week2, 2, 1, "Empuje", true)));
        f.directory.routines.put(f.user, Map.of(partly.id(), partly));

        List<CalendarBlock> created = distribution().distribute(new DistributeRoutineUseCase.Command(f.user,
                partly.id(), Set.of(), PlannerFakes.MONDAY, LocalTime.of(18, 0), 60));

        // Miércoles, viernes y el lunes siguiente: el lunes de la semana 1 ya está hecho.
        assertThat(created).extracting(CalendarBlock::start)
                .containsExactly(at(2, 18, 0), at(4, 18, 0), at(7, 18, 0));
        assertThat(created).extracting(b -> b.details().topics())
                .containsExactly("Semana 1 · Tirón", "Semana 1 · Pierna", "Semana 2 · Empuje");
    }

    @Test
    void distributingAgainReplacesTheFuturePendingBlocksOfTheRoutine() {
        RoutineDistributionService service = distribution();
        service.distribute(new DistributeRoutineUseCase.Command(f.user, routine.id(), Set.of(1, 3, 5),
                PlannerFakes.MONDAY, LocalTime.of(18, 0), 60));
        service.distribute(new DistributeRoutineUseCase.Command(f.user, routine.id(), Set.of(2, 4),
                PlannerFakes.MONDAY, LocalTime.of(18, 0), 60));
        assertThat(f.blocks.store.values()).hasSize(4)
                .allSatisfy(b -> assertThat(b.dayOfWeek()).isIn(2, 4));
    }

    @Test
    void sportSuggestionsAreLinkedToTheNextRoutineDaysInOrder() {
        PlanningSuggestionService service = new PlanningSuggestionService((inbox, zone) -> {
            throw new AiUnavailableException("down");
        }, f.directory, f.deadlines, f.directory, f.blocks, f.crossRegulation, PlannerFakes.ZONE, PlannerFakes.CLOCK);

        WeekPlanSuggestions.Suggestion s = service.suggest(new SuggestWeekPlanUseCase.Command(f.user,
                PlannerFakes.MONDAY, 0, 3, 60, 90));

        List<SuggestedBlock> sport = s.blocks().stream().filter(b -> b.type() == ActivityType.SPORT).toList();
        // Un solo objetivo: los 2 días que le quedan a la semana 1 de la rutina, en orden.
        assertThat(sport).hasSize(2);
        assertThat(sport).extracting(SuggestedBlock::routineDayId)
                .containsExactly(routine.days().get(0).id(), routine.days().get(1).id());
        assertThat(sport.get(0).title()).isEqualTo("Semana 1 · Empuje");
    }

    private RoutineDistributionService distribution() {
        // Retira como el planificador: los bloques futuros pendientes de la rutina.
        return new RoutineDistributionService(f.blocks, f.directory, f.weeklyLoadService(),
                c -> f.blocks.store.values().removeIf(b -> c.routineId().equals(b.details().routineId())
                        && !b.completed() && b.start().isAfter(PlannerFakes.NOW)),
                PlannerFakes.ZONE, PlannerFakes.CLOCK);
    }

    @Test
    void distributionRequiresAnOwnedRoutine() {
        RoutineDistributionService service = distribution();
        assertThatThrownBy(() -> service.distribute(new DistributeRoutineUseCase.Command(f.otherUser, routine.id(),
                Set.of(1), null, null, 60)))
                .extracting("code").isEqualTo("PLANNER_ROUTINE_NOT_FOUND");
    }

    @Test
    void suggestionsFallBackToHeuristicWhenAiFails() {
        f.directory.addSubject(f.user, "Álgebra", "ALG", 4);
        PlanningSuggestionService service = new PlanningSuggestionService((inbox, zone) -> {
            throw new AiUnavailableException("down");
        }, f.directory, f.deadlines, f.directory, f.blocks, f.crossRegulation, PlannerFakes.ZONE, PlannerFakes.CLOCK);

        WeekPlanSuggestions.Suggestion s = service.suggest(new SuggestWeekPlanUseCase.Command(f.user,
                PlannerFakes.MONDAY, 10, 3, 60, 90));

        assertThat(s.source()).isEqualTo(WeekPlanSuggestions.Source.HEURISTIC);
        // Con rutina en curso, las sesiones que le quedan a su semana (2), no las 3 pedidas.
        assertThat(s.sportSessions()).isEqualTo(2);
        assertThat(s.studyHours()).isEqualTo(10.0);
        assertThat(s.blocks()).allSatisfy(b -> assertThat(b.start()).isAfterOrEqualTo(PlannerFakes.NOW));
    }

    @Test
    void validAiSuggestionsAreKeptAndInvalidOnesDropped() {
        SubjectRef algebra = f.directory.addSubject(f.user, "Álgebra", "ALG", 4);
        List<SuggestedBlock> proposed = List.of(
                new SuggestedBlock(ActivityType.STUDY, at(1, 16, 0), at(1, 17, 30), algebra.id(), null, null, null, "Matrices"),
                new SuggestedBlock(ActivityType.STUDY, at(1, 17, 0), at(1, 18, 0), null, "x", null, null, null),
                new SuggestedBlock(ActivityType.STUDY, at(0, 8, 0), at(0, 9, 0), null, "pasado", null, null, null),
                new SuggestedBlock(ActivityType.SPORT, at(9, 18, 0), at(9, 19, 0), null, null, null, null, null));
        PlanningSuggestionService service = new PlanningSuggestionService((inbox, zone) -> proposed, f.directory,
                f.deadlines, f.directory, f.blocks, f.crossRegulation, PlannerFakes.ZONE, PlannerFakes.CLOCK);

        WeekPlanSuggestions.Suggestion s = service.suggest(new SuggestWeekPlanUseCase.Command(f.user,
                PlannerFakes.MONDAY, 10, 3, 60, 90));

        assertThat(s.source()).isEqualTo(WeekPlanSuggestions.Source.AI);
        assertThat(s.blocks()).singleElement().satisfies(b -> {
            assertThat(b.subjectName()).isEqualTo("Álgebra");
            assertThat(b.topic()).isEqualTo("Matrices");
        });
    }

    @Test
    void focusSessionsAreAggregatedPerDayAndWeek() {
        FocusService service = focusService();
        service.record(new RecordFocusSessionUseCase.Command(f.user, FocusSession.FocusPhase.FOCUS, 25, 1, true, null,
                null, null));
        service.record(new RecordFocusSessionUseCase.Command(f.user, FocusSession.FocusPhase.SHORT_BREAK, 5, 1, true,
                null, null, null));
        service.record(new RecordFocusSessionUseCase.Command(f.user, FocusSession.FocusPhase.FOCUS, 50, 2, true,
                PlannerFakes.MONDAY.minusDays(1), null, null));
        service.record(new RecordFocusSessionUseCase.Command(f.user, FocusSession.FocusPhase.FOCUS, 25, 1, false, null,
                null, null));

        FocusStats stats = service.getStats(f.user, null);
        assertThat(stats.today().focusMinutes()).isEqualTo(25);
        assertThat(stats.today().breakMinutes()).isEqualTo(5);
        assertThat(stats.today().sessions()).isEqualTo(2);
        assertThat(stats.week().focusCycles()).isEqualTo(1);
        assertThat(stats.days()).hasSize(7);
        assertThat(service.getStats(f.user, PlannerFakes.MONDAY.minusDays(1)).week().focusCycles()).isEqualTo(2);
        assertThatThrownBy(() -> service.record(new RecordFocusSessionUseCase.Command(f.user,
                FocusSession.FocusPhase.FOCUS, 0, 1, true, null, null, null)))
                .extracting("code").isEqualTo("VALIDATION_ERROR");
    }

    private FocusService focusService() {
        return new FocusService(f.focus, f.blocks, f.directory, f.xp, f.publisher, f.weeklyLoadService(),
                PlannerFakes.ZONE,
                PlannerFakes.CLOCK);
    }
}
