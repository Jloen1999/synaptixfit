package com.synaptixfit.domain.model.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.planner.PastActivityOutOfRangeException;
import com.synaptixfit.domain.exception.planner.PastActivityTypeNotAllowedException;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Actividad apuntada a posteriori: deporte con esfuerzo o estudio con asignatura, de los últimos 7 días. */
class PastActivityTest {

    private static final Instant NOW = Instant.parse("2026-11-02T18:00:00Z");
    private static final Instant YESTERDAY = NOW.minus(Duration.ofDays(1));

    @Test
    void studyKeepsItsSubjectAndIgnoresEffort() {
        UUID subject = UUID.randomUUID();
        PastActivity study = new PastActivity(YESTERDAY, 90, " Temas 3 y 4 ", 7, ActivityType.STUDY, subject);

        assertThat(study.type()).isEqualTo(ActivityType.STUDY);
        assertThat(study.subjectId()).isEqualTo(subject);
        assertThat(study.effort()).isNull();
        assertThat(study.title()).isEqualTo("Temas 3 y 4");
        study.requireLoggableAt(NOW);
    }

    @Test
    void sportNeedsEffortAndHasNoSubject() {
        PastActivity sport = new PastActivity(YESTERDAY, 60, "Fútbol", 6, null, UUID.randomUUID());

        assertThat(sport.type()).isEqualTo(ActivityType.SPORT);
        assertThat(sport.subjectId()).isNull();
        assertThatThrownBy(() -> new PastActivity(YESTERDAY, 60, null, null, ActivityType.SPORT, null))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void otherTypesAreNotLoggedAfterTheFact() {
        assertThatThrownBy(() -> new PastActivity(YESTERDAY, 60, null, null, ActivityType.CLASS, null))
                .isInstanceOf(PastActivityTypeNotAllowedException.class)
                .hasFieldOrPropertyWithValue("code", "PLANNER_PAST_ACTIVITY_TYPE_NOT_ALLOWED");
    }

    @Test
    void onlyFinishedAndFromTheLastSevenDays() {
        PastActivity running = new PastActivity(NOW.minus(Duration.ofMinutes(30)), 60, null, null,
                ActivityType.STUDY, null);
        PastActivity old = new PastActivity(NOW.minus(Duration.ofDays(8)), 60, null, null, ActivityType.STUDY, null);

        assertThatThrownBy(() -> running.requireLoggableAt(NOW)).isInstanceOf(PastActivityOutOfRangeException.class);
        assertThatThrownBy(() -> old.requireLoggableAt(NOW)).isInstanceOf(PastActivityOutOfRangeException.class);
    }
}
