package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** «Necesita repaso» de la asignatura usa la misma definición que la cola de repasos ({@link StudyMaterial#isDue}). */
class RetentionMetricsTest {

    private static final Instant NOW = Instant.parse("2026-11-14T10:00:00Z");

    private static StudyMaterial material(MasteryState state, Instant nextReviewAt) {
        return StudyMaterial.builder().id(UUID.randomUUID()).userId(UUID.randomUUID()).subjectId(UUID.randomUUID())
                .originType(StudySourceType.NOTE).originId(UUID.randomUUID()).title("Tema")
                .masteryState(state).nextReviewAt(nextReviewAt).createdAt(NOW.minus(Duration.ofDays(60))).build();
    }

    @Test
    void anOverdueMaterialNeedsReviewWhateverItsMastery() {
        List<StudyMaterial> materials = List.of(
                material(MasteryState.MASTERED, NOW.minus(Duration.ofDays(20))),
                material(MasteryState.IN_PROGRESS, NOW),
                material(MasteryState.MASTERED, NOW.plus(Duration.ofDays(5))),
                material(MasteryState.NEEDS_REVIEW, NOW.plus(Duration.ofHours(12))),
                material(MasteryState.NOT_EVALUATED, null),
                material(MasteryState.ABANDONED, null),
                // Abandonado con una fecha antigua: sigue fuera de la cola, como en findDue.
                material(MasteryState.ABANDONED, NOW.minus(Duration.ofDays(3))));

        RetentionMetrics metrics = RetentionMetrics.of(materials, NOW);

        assertThat(metrics.needsReview()).isEqualTo(2);
        assertThat(metrics.mastered()).isEqualTo(1);
        assertThat(metrics.inProgress()).isEqualTo(1);
        assertThat(metrics.notEvaluated()).isEqualTo(1);
        assertThat(metrics.abandoned()).isEqualTo(2);
        assertThat(metrics.total()).isEqualTo(7);
    }
}
