package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ExerciseAlternativesTest {

    private static final CatalogItem CHEST = new CatalogItem(1, "Pectoral mayor", null);
    private static final CatalogItem BACK = new CatalogItem(2, "Dorsal ancho", null);
    private static final CatalogItem DUMBBELL = new CatalogItem(10, "Mancuerna", null);
    private static final CatalogItem BARBELL = new CatalogItem(11, "Barra", null);

    private static Exercise exercise(String name, CatalogItem target, CatalogItem equipment, ExerciseCategory category,
                                     boolean active, String video) {
        return new Exercise(UUID.randomUUID(), name, null, List.of(), Difficulty.INTERMEDIATE, List.of(),
                Modality.STRENGTH, List.of(MeasurementType.REPETITIONS), false, active, 3.5, video, null, List.of(),
                List.of(target), List.of(), List.of(equipment), Instant.EPOCH, Instant.EPOCH, category);
    }

    @Test
    void alternativesShareTheMainMuscleAndPreferTheSameKindOfExercise() {
        Exercise bench = exercise("Press de banca", CHEST, BARBELL, ExerciseCategory.STRENGTH, true, "v.mp4");
        Exercise dumbbellPress = exercise("Press con mancuernas", CHEST, DUMBBELL, ExerciseCategory.STRENGTH, true,
                "v.mp4");
        Exercise pushUp = exercise("Flexión", CHEST, DUMBBELL, ExerciseCategory.CALISTHENICS, true, null);
        Exercise barbellBench = exercise("Press inclinado con barra", CHEST, BARBELL, ExerciseCategory.STRENGTH, true,
                null);
        Exercise row = exercise("Remo", BACK, BARBELL, ExerciseCategory.STRENGTH, true, "v.mp4");
        Exercise retired = exercise("Press retirado", CHEST, BARBELL, ExerciseCategory.STRENGTH, false, "v.mp4");

        List<Exercise> ranked = ExerciseAlternatives.rank(bench,
                List.of(pushUp, row, retired, bench, dumbbellPress, barbellBench), 8);

        assertThat(ranked).extracting(Exercise::name)
                .containsExactly("Press inclinado con barra", "Press con mancuernas", "Flexión");
    }

    @Test
    void categoryFallsBackToTheModality() {
        assertThat(ExerciseCategory.of(Modality.AEROBIC)).isEqualTo(ExerciseCategory.CARDIO);
        assertThat(ExerciseCategory.of(Modality.MOBILITY).isWarmUpOrCoolDown()).isTrue();
        assertThat(exercise("Sin categoría", CHEST, BARBELL, null, true, null).category())
                .isEqualTo(ExerciseCategory.STRENGTH);
    }
}
