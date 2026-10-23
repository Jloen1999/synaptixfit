package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class SessionBookendsTest {

    private static final CatalogItem QUADS = new CatalogItem(1, "Cuádriceps", null);
    private static final CatalogItem GLUTES = new CatalogItem(2, "Glúteo mayor", null);
    private static final CatalogItem CHEST = new CatalogItem(3, "Pectoral mayor", null);

    private static Exercise exercise(String name, ExerciseCategory category, CatalogItem target) {
        return new Exercise(UUID.randomUUID(), name, null, List.of(), Difficulty.BEGINNER, List.of(),
                Modality.MOBILITY, List.of(MeasurementType.TIME), false, true, 2.5, null, null, List.of(),
                List.of(target), List.of(), List.of(), Instant.EPOCH, Instant.EPOCH, category);
    }

    @Test
    void warmUpIsMobilityAndCoolDownIsStretchingForTheMusclesOfTheSession() {
        List<Exercise> session = List.of(exercise("Sentadilla", ExerciseCategory.STRENGTH, QUADS),
                exercise("Hip thrust", ExerciseCategory.STRENGTH, GLUTES));
        Exercise quadMobility = exercise("Balanceo de pierna", ExerciseCategory.MOBILITY, QUADS);
        Exercise quadStretch = exercise("Estiramiento de cuádriceps", ExerciseCategory.STRETCHING, QUADS);
        Exercise gluteYoga = exercise("Postura de la paloma", ExerciseCategory.YOGA, GLUTES);
        Exercise chestStretch = exercise("Estiramiento de pecho", ExerciseCategory.STRETCHING, CHEST);

        SessionBookends b = SessionBookends.of(session, List.of(chestStretch, gluteYoga, quadStretch, quadMobility));

        assertThat(b.warmUp()).extracting(Exercise::name).containsExactly("Balanceo de pierna", "Postura de la paloma");
        assertThat(b.coolDown()).extracting(Exercise::name)
                .containsExactly("Estiramiento de cuádriceps", "Postura de la paloma");
    }
}
