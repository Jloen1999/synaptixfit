package com.synaptixfit.infrastructure.adapter.output.external.ai.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

class ExerciseNameTranslatorAiAdapterTest {

    private final ExerciseNameTranslatorAiAdapter adapter = new ExerciseNameTranslatorAiAdapter(null,
            JsonMapper.builder().build());

    @Test
    void readsTheThreeNamesAndDropsEmptyOnes() {
        assertThat(adapter.parse("{\"en\":\"Front plank\",\"fr\":\" \",\"pt\":\"Prancha\"}"))
                .isEqualTo(new ExerciseNameTranslations("Front plank", null, "Prancha"));
    }

    @Test
    void anAnswerWithoutNamesIsAnAiFailure() {
        assertThatThrownBy(() -> adapter.parse("{}")).isInstanceOf(AiUnavailableException.class);
        assertThatThrownBy(() -> adapter.parse("no json")).isInstanceOf(AiUnavailableException.class);
    }

    @Test
    void thePromptAsksForPortugalUsage() {
        assertThat(ExerciseNameTranslatorAiAdapter.prompt("Curl de bíceps con mancuernas"))
                .contains("Curl de bíceps con mancuernas").contains("Portugal").contains("haltere");
    }
}
