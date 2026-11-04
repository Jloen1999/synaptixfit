package com.synaptixfit.infrastructure.adapter.output.external.ai.academic;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.port.output.academic.NoteTidierPort;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.infrastructure.adapter.output.external.ai.AiLanguage;
import java.util.List;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Implementa {@link NoteTidierPort} con {@link GenerativeAiPort} (DeepSeek): ordena el texto que el
 * OCR leyó de unas fotos de apuntes. Temperatura baja: aquí se corrige, no se escribe.
 */
@Component
public class NoteTidierAiAdapter implements NoteTidierPort {

    static final double TEMPERATURE = 0.1;

    /** El texto del OCR va dentro del prompt; nunca se le deja «completar» los apuntes. */
    private static final String PROMPT = """
            Eres un asistente que pasa a limpio apuntes de estudiantes. Te paso el texto que un lector automático (OCR) \
            ha sacado de unas fotos de apuntes en papel. Puede traer letras cambiadas, palabras partidas, saltos de línea \
            raros o trozos sin sentido.
            REGLA 1: Corrige solo los errores evidentes de lectura (letras cambiadas, palabras cortadas). NO añadas \
            contenido, explicaciones ni ejemplos que no estén en el texto. Si un trozo es ilegible, quítalo.
            REGLA 2: Respeta el idioma original de los apuntes; no los traduzcas.
            REGLA 3: Ordénalo en Markdown: títulos (##) donde el texto cambie de tema, listas donde haya enumeraciones \
            y párrafos cortos. Las fórmulas, tal cual.
            REGLA 4: Las páginas vienen separadas por «---»; puedes quitar el separador si una página sigue a la anterior.
            REGLA 5: Propón un título corto y descriptivo para el apunte (sin fechas ni la palabra «apuntes»). %s
            Devuelve SOLO un objeto JSON, sin markdown alrededor: {"titulo": "...", "texto": "..."}
            TEXTO LEÍDO:
            <<<
            %s
            >>>
            """;

    private final GenerativeAiPort ai;
    private final JsonMapper mapper;

    public NoteTidierAiAdapter(GenerativeAiPort ai, JsonMapper mapper) {
        this.ai = ai;
        this.mapper = mapper;
    }

    @Override
    public TidiedNote tidy(String recognizedText) {
        String raw = ai.generateJson(PROMPT.formatted(titleLanguageRule(), recognizedText), List.of(), TEMPERATURE);
        JsonNode node = parse(raw);
        String title = node.path("titulo").asString("").strip();
        String text = node.path("texto").asString("").strip();
        return new TidiedNote(title.isEmpty() ? null : title, text);
    }

    /** El título lo lee la persona en la app: va en su idioma aunque los apuntes estén en otro. */
    private static String titleLanguageRule() {
        return "Escribe el título en " + AiLanguage.current() + ".";
    }

    JsonNode parse(String raw) {
        String s = raw == null ? "" : raw.strip();
        int start = s.indexOf('{');
        int end = s.lastIndexOf('}');
        if (start < 0 || end <= start) {
            throw new AiUnavailableException("AI did not return a JSON object");
        }
        try {
            JsonNode node = mapper.readTree(s.substring(start, end + 1));
            if (node == null || !node.isObject()) {
                throw new AiUnavailableException("AI did not return a JSON object");
            }
            return node;
        } catch (JacksonException e) {
            throw new AiUnavailableException("AI returned invalid JSON");
        }
    }
}
