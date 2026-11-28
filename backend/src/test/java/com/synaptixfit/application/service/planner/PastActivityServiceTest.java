package com.synaptixfit.application.service.planner;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.application.port.input.planner.LogPastActivityUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.domain.model.planner.ActivityKind;
import com.synaptixfit.domain.model.planner.ActivitySource;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ChallengeRef;
import com.synaptixfit.domain.model.planner.LoggedSportActivity;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.planner.MatchResult;
import com.synaptixfit.domain.model.planner.Sport;
import com.synaptixfit.domain.model.planner.SportDetails;
import com.synaptixfit.domain.model.planner.SportMode;
import com.synaptixfit.domain.port.output.planner.LoggedActivityRepositoryPort;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Actividad que sustituye a un entreno planificado (una carrera hecha antes de su hora, ADR 0037): hereda el reto y
 * la tarea del evento solo si cae dentro del periodo del reto, como cualquier bloque de reto.
 */
class PastActivityServiceTest {

    private PlannerFakes f;
    private PastActivityService service;
    private final Map<UUID, Integer> loggedMinutes = new HashMap<>();
    private final Map<UUID, SportDetails> loggedSport = new HashMap<>();
    private final UUID challenge = UUID.randomUUID();
    private final UUID task = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        f.directory.challenges.computeIfAbsent(f.user, u -> new HashSet<>()).addAll(Set.of(challenge, task));
        LoggedActivityRepositoryPort logged = new LoggedActivityRepositoryPort() {
            @Override
            public void save(UUID blockId, UUID userId, ActivityKind kind, SportDetails sport, int minutes,
                             Integer distanceMeters, ActivitySource source, Instant now) {
                loggedSport.put(blockId, sport);
                loggedMinutes.put(blockId, minutes);
            }

            @Override
            public PageResult<LoggedSportActivity> findSportActivities(UUID userId, PageRequest page) {
                throw new UnsupportedOperationException();
            }
        };
        SetBlockCompletionUseCase completion = new BlockCompletionService(f.blocks, f.directory, f.directory, f.xp,
                f.xp, f.publisher, f.weeklyLoadService(), PlannerFakes.ZONE, PlannerFakes.CLOCK,
                (u, b) -> java.util.Optional.ofNullable(loggedMinutes.get(b)));
        service = new PastActivityService(f.blocks, f.directory, completion, PlannerFakes.ZONE, PlannerFakes.CLOCK,
                logged, f.publisher, f.directory);
    }

    private CalendarBlock logRun() {
        Instant start = PlannerFakes.NOW.minus(Duration.ofHours(2));
        return service.logPastActivity(new LogPastActivityUseCase.Command(f.user, start, 35, "Rodaje", 6,
                ActivityType.SPORT, null, ActivityKind.RUN, 6000, ActivitySource.GPS, challenge, task)).block();
    }

    @Test
    void insideTheChallengePeriodTheActivityKeepsItsTask() {
        CalendarBlock block = logRun();

        assertThat(block.details().challengeId()).isEqualTo(challenge);
        assertThat(block.details().milestoneId()).isEqualTo(task);
    }

    @Test
    void outsideTheChallengePeriodTheActivityIsLoggedWithoutIt() {
        // El reto empieza la semana que viene: la carrera de hoy no puede contarle.
        f.directory.challengePeriods.put(challenge, new ChallengeRef(challenge,
                PlannerFakes.NOW.plus(Duration.ofDays(7)), PlannerFakes.NOW.plus(Duration.ofDays(30))));

        CalendarBlock block = logRun();

        assertThat(block.details().challengeId()).isNull();
        assertThat(block.details().milestoneId()).isNull();
        assertThat(block.completed()).isTrue();
    }

    @Test
    void aMatchIsSavedWithItsSportAndCountsLikeAnyActivity() {
        Instant start = PlannerFakes.NOW.minus(Duration.ofHours(3));
        SportDetails padel = new SportDetails(Sport.PADEL, null, SportMode.MATCH, MatchResult.WIN, "6-4 6-3");

        CalendarBlock block = service.logPastActivity(new LogPastActivityUseCase.Command(f.user, start, 90, "Pádel",
                7, ActivityType.SPORT, null, null, null, ActivitySource.MANUAL, null, null, padel)).block();

        assertThat(block.completed()).isTrue();
        assertThat(loggedSport.get(block.id())).isEqualTo(padel);
    }

    @Test
    void anOldAppWithoutSportGetsItFromItsKindAndTitle() {
        Instant start = PlannerFakes.NOW.minus(Duration.ofHours(3));

        CalendarBlock block = service.logPastActivity(new LogPastActivityUseCase.Command(f.user, start, 60, "Fútbol",
                6, ActivityType.SPORT, null, ActivityKind.MATCH, null)).block();

        assertThat(loggedSport.get(block.id()).sport()).isEqualTo(Sport.FOOTBALL);
        assertThat(loggedSport.get(block.id()).mode()).isEqualTo(SportMode.MATCH);
    }
}
