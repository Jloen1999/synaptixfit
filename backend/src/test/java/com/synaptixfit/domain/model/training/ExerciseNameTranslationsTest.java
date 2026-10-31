package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import java.util.Map;
import org.junit.jupiter.api.Test;

class ExerciseNameTranslationsTest {

    @Test
    void blankLanguagesAreEmptyAndKeepTheirOrder() {
        ExerciseNameTranslations names = new ExerciseNameTranslations("  Front plank ", " ", "Prancha");
        assertThat(names.en()).isEqualTo("Front plank");
        assertThat(names.fr()).isNull();
        assertThat(names.byLanguage()).containsExactly(Map.entry("en", "Front plank"), Map.entry("pt", "Prancha"));
        assertThat(ExerciseNameTranslations.of(Map.of("fr", "Gainage", "de", "Unterarmstütz")).byLanguage())
                .containsOnly(Map.entry("fr", "Gainage"));
        assertThat(ExerciseNameTranslations.EMPTY.isEmpty()).isTrue();
    }

    @Test
    void tooLongNamesAreRejected() {
        assertThatThrownBy(() -> new ExerciseNameTranslations("x".repeat(201), null, null))
                .isInstanceOf(FieldValidationException.class);
    }
}
