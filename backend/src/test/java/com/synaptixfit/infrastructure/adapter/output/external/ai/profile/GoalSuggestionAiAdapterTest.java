package com.synaptixfit.infrastructure.adapter.output.external.ai.profile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.GoalSuggestion;
import com.synaptixfit.domain.model.profile.GoalSuggestionContext;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.port.output.ai.AiAttachment;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import java.util.List;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

class GoalSuggestionAiAdapterTest {

    private String response;
    private String lastPrompt;
    private final GenerativeAiPort ai = new GenerativeAiPort() {
        public String generateText(String prompt, List<AiAttachment> attachments, double temperature) {
            throw new UnsupportedOperationException();
        }

        public String generateJson(String prompt, List<AiAttachment> attachments, double temperature) {
            lastPrompt = prompt;
            return response;
        }
    };
    private final GoalSuggestionAiAdapter adapter = new GoalSuggestionAiAdapter(ai, JsonMapper.builder().build());

    @Test
    void parsesValidGoalsDiscardingUnknownAndDuplicates() {
        response = """
                {"suggestions":[
                  {"goal":"HYPERTROPHY","reason":"Ganar masa"},
                  {"goal":"YOGA","reason":"no vale"},
                  {"goal":"hypertrophy","reason":"repetido"},
                  {"goal":"Movilidad y Flexibilidad","reason":"Compensa estar sentado"},
                  {"goal":"POWER","reason":""},
                  {"goal":"STABILITY","reason":"Base técnica"},
                  {"goal":"MAX_STRENGTH","reason":"sobra"}
                ]}
                """;
        List<GoalSuggestion> result = adapter.suggest(new GoalSuggestionContext(20, null, ActivityLevel.LIGHT, "Granada"));

        assertThat(result).extracting(GoalSuggestion::goal)
                .containsExactly(TrainingGoal.HYPERTROPHY, TrainingGoal.MOBILITY, TrainingGoal.STABILITY);
        assertThat(lastPrompt).contains("Edad: 20").contains("LIGHT").contains("Granada").contains("METABOLIC_CONDITIONING");
    }

    @Test
    void invalidResponsesAreAiUnavailable() {
        GoalSuggestionContext ctx = new GoalSuggestionContext(null, null, null, null);
        response = "no es json";
        assertThatThrownBy(() -> adapter.suggest(ctx)).isInstanceOf(AiUnavailableException.class);
        response = "{\"suggestions\":[{\"goal\":\"YOGA\",\"reason\":\"x\"}]}";
        assertThatThrownBy(() -> adapter.suggest(ctx)).isInstanceOf(AiUnavailableException.class);
        response = "{\"other\":1}";
        assertThatThrownBy(() -> adapter.suggest(ctx)).isInstanceOf(AiUnavailableException.class);
    }
}
