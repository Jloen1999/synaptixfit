package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.SessionAdaptation.Reason;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Regulación cruzada aplicada a la sesión (estudio → entrenamiento). */
class SessionAdaptationTest {

    private static final Instant NOW = Instant.parse("2026-10-25T10:00:00Z");

    private static DailyCheckIn checkIn(int sleep, int stress, int energy, int soreness) {
        return DailyCheckIn.create(UUID.randomUUID(), LocalDate.of(2026, 10, 25),
                new DailyCheckIn.Values(sleep, stress, energy, soreness, List.of(), true, null), NOW);
    }

    @Test
    void withoutReasonsTheSessionIsUnchanged() {
        SessionAdaptation none = SessionAdaptation.of(1.0, false, checkIn(5, 1, 5, 1));
        assertThat(none.adapted()).isFalse();
        assertThat(none.sets(4)).isEqualTo(4);
        // Un recorte menor del 5 % no merece cambiar la sesión.
        assertThat(SessionAdaptation.of(0.97, false, null).adapted()).isFalse();
    }

    @Test
    void theMostRestrictiveReasonWinsAndEveryExerciseKeepsASet() {
        SessionAdaptation exam = SessionAdaptation.of(0.75, false, null);
        assertThat(exam.reasons()).containsExactly(Reason.EXAM_SOON);
        assertThat(exam.sets(4)).isEqualTo(3);

        // Examen, sobreentrenamiento y fatiga a la vez: se aplica el menor factor, no el producto.
        SessionAdaptation all = SessionAdaptation.of(0.75, true, checkIn(1, 5, 1, 5));
        assertThat(all.reasons()).containsExactly(Reason.EXAM_SOON, Reason.OVERTRAINING, Reason.HIGH_FATIGUE);
        assertThat(all.volumeFactor()).isEqualTo(SessionAdaptation.OVERTRAINING_FACTOR);
        assertThat(all.sets(4)).isEqualTo(3);
        assertThat(all.sets(1)).isEqualTo(1);

        SessionAdaptation tired = SessionAdaptation.of(1.0, false, checkIn(1, 5, 1, 5));
        assertThat(tired.reasons()).containsExactly(Reason.HIGH_FATIGUE);
        assertThat(tired.sets(5)).isEqualTo(4);
    }
}
