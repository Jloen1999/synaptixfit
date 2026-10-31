package com.synaptixfit.domain.model.analytics;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Analítica por asignatura: minutos por semana, porcentaje de repasos superados y veredicto. */
class StudyBySubjectTest {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");
    private static final LocalDate FIRST = LocalDate.of(2026, 10, 12);
    private final UUID algebra = UUID.randomUUID();
    private final UUID fisica = UUID.randomUUID();

    private static StudyBySubject.StudyBlock block(UUID subject, String start, int minutes) {
        Instant s = Instant.parse(start);
        return new StudyBySubject.StudyBlock(subject, s, s.plusSeconds(minutes * 60L));
    }

    @Test
    void minutesGoToTheirWeekAndWeakReviewsAreFlagged() {
        Map<UUID, String> names = new LinkedHashMap<>();
        names.put(algebra, "Álgebra");
        names.put(fisica, "Física");

        StudyBySubject report = StudyBySubject.of(FIRST, 3, names,
                List.of(block(algebra, "2026-10-13T10:00:00Z", 60), block(algebra, "2026-10-27T10:00:00Z", 90),
                        block(null, "2026-10-20T10:00:00Z", 30)),
                List.of(new StudyBySubject.Review(fisica, 2), new StudyBySubject.Review(fisica, 1),
                        new StudyBySubject.Review(fisica, 4), new StudyBySubject.Review(algebra, 5)),
                MADRID);

        StudyBySubject.Subject first = report.subjects().getFirst();
        assertThat(first.name()).isEqualTo("Álgebra");
        assertThat(first.minutesByWeek()).containsExactly(60, 0, 90);
        assertThat(first.weak()).isFalse();
        StudyBySubject.Subject physics = report.subjects().get(1);
        assertThat(physics.recallRate()).isEqualTo(1.0 / 3);
        assertThat(physics.weak()).isTrue();
        assertThat(report.subjects().getLast().subjectId()).isNull();
        assertThat(report.subjects().getLast().totalMinutes()).isEqualTo(30);
    }

    @Test
    void withFewReviewsThereIsNoVerdict() {
        StudyBySubject report = StudyBySubject.of(FIRST, 1, Map.of(algebra, "Álgebra"), List.of(),
                List.of(new StudyBySubject.Review(algebra, 0)), MADRID);

        assertThat(report.subjects().getFirst().recallRate()).isZero();
        assertThat(report.subjects().getFirst().weak()).isFalse();
    }
}
