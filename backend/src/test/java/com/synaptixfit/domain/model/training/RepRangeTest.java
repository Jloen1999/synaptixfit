package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.generation.ActivityLevel;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Rango de repeticiones (ADR 0054): se conserva al editar sin él, se lee tolerante y da el RPE pedido. */
class RepRangeTest {

    private static final ExerciseRef BENCH = new ExerciseRef(UUID.randomUUID(), "Press de banca", null, null,
            Modality.STRENGTH, List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT), false, 6.0, true);

    @Test
    void editingWithoutARangeKeepsTheOneTheSlotHad() {
        RepRange range = new RepRange(8, 12, 2);
        PlannedExercise p = new PlannedExercise(UUID.randomUUID(), BENCH,
                new ExerciseParameters(3, 8, 90, 40.0, null, null, null, null, null, null, range), 1, null);

        p.changeParameters(new ExerciseParameters(4, 9, 120, 42.5, null, null, null, null));

        assertThat(p.parameters().repRange()).isEqualTo(range);
        assertThat(p.parameters().sets()).isEqualTo(4);
        assertThat(p.parameters().weightKg()).isEqualTo(42.5);

        p.changeParameters(new ExerciseParameters(4, 6, 120, 50.0, null, null, null, null, null, null,
                new RepRange(5, 8, 1)));
        assertThat(p.parameters().repRange()).isEqualTo(new RepRange(5, 8, 1));
    }

    @Test
    void storedValuesNeverBreakReadingAndEffortFollowsTheReserve() {
        assertThat(RepRange.ofStored(12, 8, 2)).isNull();
        assertThat(RepRange.ofStored(8, null, 2)).isNull();
        assertThat(RepRange.ofStored(8, 12, 9)).isNull();
        assertThat(RepRange.ofStored(8, 12, null)).isEqualTo(new RepRange(8, 12, null));
        assertThat(new RepRange(8, 12, 3).targetRpe()).isEqualTo(7.0);
        assertThat(new RepRange(8, 12, null).targetRpe()).isEqualTo(8.0);
        assertThat(new RepRange(8, 12, 2).clamp(14)).isEqualTo(12);
    }

    @Test
    void activeProfilesCountAsIntermediateForStartingWeights() {
        assertThat(TemplateLevel.forActivity(ActivityLevel.LIGHT)).isEqualTo(TemplateLevel.BEGINNER);
        assertThat(TemplateLevel.forActivity(ActivityLevel.MODERATE)).isEqualTo(TemplateLevel.INTERMEDIATE);
        assertThat(TemplateLevel.forActivity(null)).isEqualTo(TemplateLevel.BEGINNER);
    }
}
