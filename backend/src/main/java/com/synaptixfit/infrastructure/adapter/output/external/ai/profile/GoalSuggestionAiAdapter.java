package com.synaptixfit.infrastructure.adapter.output.external.ai.profile;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.profile.GoalSuggestion;
import com.synaptixfit.domain.model.profile.GoalSuggestionContext;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.domain.port.output.profile.GoalSuggestionPort;
import com.synaptixfit.infrastructure.adapter.output.external.ai.AiLanguage;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Recomienda el objetivo principal con IA. A diferencia del sistema antiguo (texto libre que
 * luego no encajaba en las finalidades estándar), el modelo debe elegir entre los siete códigos
 * válidos; cualquier respuesta fuera de ese vocabulario se descarta.
 */
@Component
public class GoalSuggestionAiAdapter implements GoalSuggestionPort {

    private static final int MAX_SUGGESTIONS = 3;
    private static final int MAX_REASON_LENGTH = 300;

    private final GenerativeAiPort ai;
    private final JsonMapper json;

    public GoalSuggestionAiAdapter(GenerativeAiPort ai, JsonMapper json) {
        this.ai = ai;
        this.json = json;
    }

    @Override
    public List<GoalSuggestion> suggest(GoalSuggestionContext context) {
        String response = ai.generateJson(prompt(context), List.of(), 0.4);
        return parse(response);
    }

    String prompt(GoalSuggestionContext c) {
        String goals = Arrays.stream(TrainingGoal.values())
                .map(g -> "- " + g.name() + ": " + g.label())
                .collect(Collectors.joining("\n"));
        return """
                Eres un asistente de entrenamiento y bienestar para estudiantes universitarios.
                Elige los 3 objetivos principales de entrenamiento más adecuados para este usuario,
                ordenados de más a menos recomendable, SOLO entre estos códigos:
                %s

                Contexto del usuario:
                - Edad: %s
                - Sexo: %s
                - Nivel de actividad: %s
                - Ciudad: %s

                Responde únicamente con JSON con esta forma exacta:
                {"suggestions":[{"goal":"CODIGO","reason":"motivo breve en %s (máximo 25 palabras)"}]}
                """.formatted(goals,
                c.age() == null ? "No especificada" : c.age(),
                c.sex() == null ? "No especificado" : c.sex().name(),
                c.activityLevel() == null ? "No especificado" : c.activityLevel().name(),
                c.city() == null ? "No especificada" : c.city(), AiLanguage.current());
    }

    List<GoalSuggestion> parse(String response) {
        JsonNode root;
        try {
            root = json.readTree(response);
        } catch (JacksonException e) {
            throw new AiUnavailableException("Goal suggestion response is not valid JSON");
        }
        JsonNode items = root.isArray() ? root : root.path("suggestions");
        if (!items.isArray()) {
            throw new AiUnavailableException("Goal suggestion response has no suggestions");
        }
        List<GoalSuggestion> result = new ArrayList<>();
        Set<TrainingGoal> seen = EnumSet.noneOf(TrainingGoal.class);
        for (JsonNode item : items) {
            TrainingGoal goal = toGoal(item.path("goal").asString(""));
            String reason = item.path("reason").asString("").strip();
            if (goal == null || reason.isEmpty() || !seen.add(goal)) {
                continue;
            }
            if (reason.length() > MAX_REASON_LENGTH) {
                reason = reason.substring(0, MAX_REASON_LENGTH).strip();
            }
            result.add(new GoalSuggestion(goal, reason));
            if (result.size() == MAX_SUGGESTIONS) {
                break;
            }
        }
        if (result.isEmpty()) {
            throw new AiUnavailableException("Goal suggestion response has no valid goals");
        }
        return result;
    }

    /** Acepta el código o, por tolerancia, la etiqueta en español. */
    private static TrainingGoal toGoal(String value) {
        if (value.isBlank()) {
            return null;
        }
        try {
            return TrainingGoal.valueOf(value.strip().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return TrainingGoal.fromLabel(value).orElse(null);
        }
    }
}
