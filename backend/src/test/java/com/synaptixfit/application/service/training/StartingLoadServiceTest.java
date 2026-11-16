package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.HealthConsent;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import com.synaptixfit.domain.model.training.generation.PhysiologicalContext;
import com.synaptixfit.domain.model.training.generation.TrainingProfile;
import com.synaptixfit.domain.model.training.load.LoadProfile;
import com.synaptixfit.domain.model.training.load.LoadType;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * El peso del perfil solo se usa con el consentimiento de salud vigente (ADR 0054); sin él, el peso por defecto. Las
 * máquinas no llevan kilos y el historial manda.
 */
class StartingLoadServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-11-16T10:00:00Z");
    private static final UUID SQUAT = UUID.randomUUID();
    private static final UUID LEG_PRESS = UUID.randomUUID();
    private static final UUID CURL = UUID.randomUUID();

    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final TrainingFakes.HealthConsents consents = new TrainingFakes.HealthConsents();
    private final StartingLoadService service = new StartingLoadService(ids -> Map.of(
            SQUAT, new LoadProfile(LoadType.BARBELL, 0.35, 20.0, 60.0, true),
            LEG_PRESS, new LoadProfile(LoadType.MACHINE, null, null, null, true),
            CURL, new LoadProfile(LoadType.DUMBBELL_PAIR, 0.04, 2.0, 16.0, false)),
            sessions, context(80.0), consents, Clock.fixed(NOW, ZoneOffset.UTC));

    @Test
    void withHealthConsentTheBodyWeightFractionIsUsed() {
        consents.save(HealthConsent.give(USER, NOW.minus(Duration.ofDays(1))));

        assertThat(service.startingLoads(USER, List.of(SQUAT, LEG_PRESS, CURL), TemplateLevel.BEGINNER))
                .containsExactlyInAnyOrderEntriesOf(Map.of(SQUAT, 27.5, CURL, 2.0));
    }

    @Test
    void withoutConsentOrWithItWithdrawnOnlyTheDefaultsAreUsed() {
        assertThat(service.startingLoads(USER, List.of(SQUAT, CURL), TemplateLevel.BEGINNER))
                .containsExactlyInAnyOrderEntriesOf(Map.of(SQUAT, 20.0, CURL, 2.0));

        consents.save(HealthConsent.give(USER, NOW.minus(Duration.ofDays(9))).withdraw(NOW.minus(Duration.ofDays(1))));
        assertThat(service.startingLoads(USER, List.of(SQUAT), TemplateLevel.BEGINNER)).containsEntry(SQUAT, 20.0);
    }

    @Test
    void aConsentGivenWithTheOldTextDoesNotCoverTheBodyWeight() {
        consents.save(new HealthConsent(USER, NOW.minus(Duration.ofDays(30)), null));

        assertThat(service.startingLoads(USER, List.of(SQUAT), TemplateLevel.BEGINNER)).containsEntry(SQUAT, 20.0);
    }

    @Test
    void historyWinsAndIntermediatesWithoutHistoryGetNothing() {
        sessions.recent.add(new CompletedSessionSummary(UUID.randomUUID(), NOW.minus(Duration.ofDays(3)), 7, 40,
                List.of(new PerformedSet(SQUAT, "Sentadilla", new SessionSet(UUID.randomUUID(), UUID.randomUUID(), 1,
                        8, 62.5, true, 0, null, null, SQUAT)))));

        assertThat(service.startingLoads(USER, List.of(SQUAT, CURL), TemplateLevel.INTERMEDIATE))
                .containsExactlyEntriesOf(Map.of(SQUAT, 62.5));
    }

    private static TrainingContextPort context(Double bodyWeight) {
        return new TrainingContextPort() {
            @Override
            public Optional<Double> bodyWeightKg(UUID userId) {
                return Optional.ofNullable(bodyWeight);
            }

            @Override
            public Optional<TrainingProfile> profile(UUID userId) {
                return Optional.empty();
            }

            @Override
            public AcademicContext academicContext(UUID userId, LocalDate today) {
                return null;
            }

            @Override
            public PhysiologicalContext physiologicalContext(UUID userId, LocalDate today) {
                return null;
            }

            @Override
            public Optional<GoalChange> latestGoalChange(UUID userId) {
                return Optional.empty();
            }
        };
    }
}
