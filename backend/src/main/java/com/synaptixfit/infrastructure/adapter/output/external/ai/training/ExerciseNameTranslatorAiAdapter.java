package com.synaptixfit.infrastructure.adapter.output.external.ai.training;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.domain.port.output.training.ExerciseNameTranslatorPort;
import java.util.List;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Propone con IA (modo JSON) el nombre técnico de un ejercicio en inglés, francés y portugués de
 * Portugal. Mismo criterio que la traducción del catálogo ({@code tools/exercises/translate_names.py}):
 * el nombre que diría un entrenador en un gimnasio de cada país.
 */
@Component
public class ExerciseNameTranslatorAiAdapter implements ExerciseNameTranslatorPort {

    static final double TEMPERATURE = 0.2;

    private final GenerativeAiPort ai;
    private final JsonMapper json;

    public ExerciseNameTranslatorAiAdapter(GenerativeAiPort ai, JsonMapper json) {
        this.ai = ai;
        this.json = json;
    }

    @Override
    public ExerciseNameTranslations suggest(String spanishName) {
        return parse(ai.generateJson(prompt(spanishName), List.of(), TEMPERATURE));
    }

    static String prompt(String spanishName) {
        return """
                You are a certified strength & conditioning coach and a professional translator of fitness apps.
                Translate this exercise name from Spanish into the name a coach would use in a gym in each language:
                - "en": English (US), the standard technical name (e.g. "Barbell bench press", "Romanian deadlift",
                  "Dumbbell lateral raise", "Child's pose").
                - "fr": French (France), the usual gym terminology (e.g. "Développé couché à la barre",
                  "Soulevé de terre roumain", "Élévations latérales aux haltères", "Fente arrière", "Gainage").
                - "pt": European Portuguese (Portugal), the usual gym terminology (e.g. "Supino reto com barra",
                  "Peso morto romeno", "Elevação lateral com halteres", "Afundo", "Prancha"). Use Portugal usage,
                  not Brazil: "curl" (not "rosca"), "haltere" / "halteres" (not "halter").
                Rules:
                - Sentence case (only the first letter and proper nouns capitalized). No quotes.
                - Keep equipment and variations that matter (grip, stance, bench angle, unilateral).
                - Keep established loanwords when coaches use them (press, curl, kettlebell, burpee, crunch,
                  pilates and yoga pose names).
                Return ONLY JSON: {"en": "...", "fr": "...", "pt": "..."}

                Spanish name: %s
                """.formatted(spanishName);
    }

    ExerciseNameTranslations parse(String response) {
        JsonNode root;
        try {
            root = json.readTree(response);
        } catch (JacksonException e) {
            throw new AiUnavailableException("Exercise name response is not valid JSON");
        }
        ExerciseNameTranslations names = new ExerciseNameTranslations(text(root, "en"), text(root, "fr"),
                text(root, "pt"));
        if (names.isEmpty()) {
            throw new AiUnavailableException("Exercise name response has no names");
        }
        return names;
    }

    /** Un texto vacío o demasiado largo se descarta: ese idioma queda para escribirlo a mano. */
    private static String text(JsonNode node, String field) {
        String s = node.path(field).asString("").strip();
        return s.isEmpty() || s.length() > 200 ? null : s;
    }
}
