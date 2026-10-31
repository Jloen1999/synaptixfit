package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import com.synaptixfit.domain.port.output.training.ExerciseNameTranslationsRepositoryPort;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ExerciseNameTranslationServiceTest {

    private final TrainingFakes.Exercises exercises = new TrainingFakes.Exercises();
    private final List<String> asked = new ArrayList<>();
    private final ExerciseNameTranslationsRepositoryPort names = new ExerciseNameTranslationsRepositoryPort() {
        @Override
        public ExerciseNameTranslations findByExercise(UUID exerciseId) {
            return new ExerciseNameTranslations("Front plank", null, null);
        }

        @Override
        public void replace(UUID exerciseId, ExerciseNameTranslations translations) {
            throw new AssertionError("no guarda nada");
        }
    };
    private final ExerciseNameTranslationService service = new ExerciseNameTranslationService(exercises, names,
            spanish -> {
                asked.add(spanish);
                return new ExerciseNameTranslations("Front plank", "Gainage", "Prancha");
            });

    @Test
    void suggestsFromTheTrimmedSpanishName() {
        assertThat(service.suggest("  Plancha frontal ").fr()).isEqualTo("Gainage");
        assertThat(asked).containsExactly("Plancha frontal");
        assertThatThrownBy(() -> service.suggest(" ")).isInstanceOf(FieldValidationException.class);
        assertThat(asked).hasSize(1);
    }

    @Test
    void namesOfAnUnknownExerciseAreNotFound() {
        assertThatThrownBy(() -> service.names(UUID.randomUUID())).isInstanceOf(ExerciseNotFoundException.class);
    }
}
