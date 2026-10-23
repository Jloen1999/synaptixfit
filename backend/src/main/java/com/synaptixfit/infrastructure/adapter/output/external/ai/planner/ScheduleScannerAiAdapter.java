package com.synaptixfit.infrastructure.adapter.output.external.ai.planner;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.ScheduleEntry;
import com.synaptixfit.domain.model.planner.SubjectMatcher;
import com.synaptixfit.domain.port.output.ai.AiAttachment;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.domain.port.output.planner.ScheduleScannerPort;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Implementa {@link ScheduleScannerPort}: extrae el horario semanal de un PDF con la IA (el PDF se
 * convierte a texto antes de enviarlo; prompt heredado de {@code ai_schedule_parser_service}).
 *
 * <p>Solo se extrae el patrón semanal de las asignaturas activas del usuario (evita alucinaciones);
 * las fechas absolutas las pone el planificador con las del perfil académico.
 */
@Component
public class ScheduleScannerAiAdapter implements ScheduleScannerPort {

    private static final Pattern HOUR = Pattern.compile("^\\d{1,2}:\\d{2}$");

    private final GenerativeAiPort ai;
    private final JsonMapper json;

    public ScheduleScannerAiAdapter(GenerativeAiPort ai, JsonMapper json) {
        this.ai = ai;
        this.json = json;
    }

    @Override
    public List<ScheduleEntry> extractWeeklyPattern(byte[] content, String mimeType, List<String> subjectNames) {
        String raw = ai.generateJson(prompt(subjectNames), List.of(new AiAttachment(mimeType, content)), 0.0);
        return parse(raw, json);
    }

    static String prompt(List<String> subjects) {
        String list = subjects.isEmpty() ? "(el usuario no tiene asignaturas configuradas)" : String.join(", ", subjects);
        return """
                Eres un analizador de datos determinista. Extrae el patrón semanal de clases del documento proporcionado y devuelve estrictamente un objeto JSON con la lista en "horarios".
                REGLA 1: Solo busca horarios para estas asignaturas: %s. Ignora el resto.
                REGLA 2: NUNCA inventes fechas absolutas.
                REGLA 3: dia_semana es un entero (1=Lunes, 5=Viernes). Horas en formato HH:MM (24h).
                REGLA 4: Si un dato no aparece en el documento, usa cadena vacía; nunca lo inventes.
                Devuelve solo JSON, sin markdown. Formato exigido:
                {
                  "horarios": [
                    {
                      "asignatura_codigo": "SIGLAS",
                      "asignatura_nombre": "Nombre de la asignatura encontrada",
                      "tipo": "Teoría | Práctica",
                      "dia_semana": 1,
                      "hora_inicio": "17:00",
                      "hora_fin": "19:00",
                      "aula": "Aula X"
                    }
                  ]
                }""".formatted(list);
    }

    /** Sanea la respuesta: solo entradas con día 1-7, horas HH:MM y nombre. */
    static List<ScheduleEntry> parse(String raw, JsonMapper json) {
        JsonNode root;
        try {
            root = json.readTree(extractArray(raw));
        } catch (JacksonException e) {
            throw new AiUnavailableException("Schedule scan returned invalid JSON");
        }
        if (root.isObject() && root.path("horarios").isArray()) {
            root = root.path("horarios");
        }
        if (!root.isArray()) {
            throw new AiUnavailableException("Schedule scan did not return a JSON array");
        }
        List<ScheduleEntry> entries = new ArrayList<>();
        for (JsonNode node : root) {
            JsonNode day = node.path("dia_semana");
            String start = node.path("hora_inicio").asString("").strip();
            String end = node.path("hora_fin").asString("").strip();
            String name = node.path("asignatura_nombre").asString("").strip();
            if (!day.isNumber() || day.asInt() < 1 || day.asInt() > 7 || !HOUR.matcher(start).matches()
                    || !HOUR.matcher(end).matches() || name.isEmpty()) {
                continue;
            }
            LocalTime from = time(start);
            LocalTime to = time(end);
            if (from == null || to == null) {
                continue;
            }
            String room = node.path("aula").asString("").strip();
            entries.add(new ScheduleEntry(node.path("asignatura_codigo").asString("").strip(), name,
                    kind(node.path("tipo").asString("")), day.asInt(), from, to, room.isEmpty() ? null : room));
        }
        return entries;
    }

    private static String extractArray(String raw) {
        String s = raw == null ? "" : raw.strip();
        int start = s.indexOf('[');
        int end = s.lastIndexOf(']');
        boolean objectFirst = s.startsWith("{");
        if (!objectFirst && start >= 0 && end > start) {
            return s.substring(start, end + 1);
        }
        return s;
    }

    private static LocalTime time(String hhmm) {
        String[] parts = hhmm.split(":");
        int h = Integer.parseInt(parts[0]);
        int m = Integer.parseInt(parts[1]);
        if (h > 23 || m > 59) {
            return null;
        }
        return LocalTime.of(h, m);
    }

    private static ClassKind kind(String value) {
        String v = SubjectMatcher.normalize(value);
        if (v.startsWith("pr") || v.contains("practica") || v.contains("lab")) {
            return ClassKind.PRACTICE;
        }
        return v.startsWith("teo") || v.contains("teoria") ? ClassKind.THEORY : null;
    }
}
