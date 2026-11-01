package com.synaptixfit.infrastructure.adapter.output.external.ai.planner;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.ScheduleEntry;
import com.synaptixfit.domain.model.planner.ScheduleScan;
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
    public ScheduleScan extractWeeklyPattern(byte[] content, String mimeType, List<String> subjectNames,
                                             int semester) {
        String raw = ai.generateJson(prompt(subjectNames, semester), List.of(new AiAttachment(mimeType, content)),
                0.0);
        return new ScheduleScan(parse(raw, json), documentSubjects(raw, json));
    }

    /**
     * Los horarios de las universidades suelen traer varios cursos y semestres, con siglas en las celdas y una
     * leyenda («IPO : Interacción Persona-Ordenador») y prácticas por grupos («P. MDP-C (Lab. IV)»).
     */
    static String prompt(List<String> subjects, int semester) {
        String list = subjects.isEmpty() ? "(el usuario no tiene asignaturas configuradas)" : String.join(", ", subjects);
        String term = semester == 2 ? "SEGUNDO" : "PRIMER";
        return """
                Eres un analizador de datos determinista. Extrae el patrón semanal de clases del documento proporcionado y devuelve estrictamente un objeto JSON.
                REGLA 1: Solo busca horarios para estas asignaturas del usuario: %s. Ignora el resto.
                REGLA 2: Si el documento trae varios semestres, usa solo el %s semestre.
                REGLA 3: Las celdas pueden usar siglas: relaciónalas con su asignatura mediante la leyenda del documento (p. ej. «IPO : Interacción Persona-Ordenador»). Una asignatura del usuario coincide aunque el nombre varíe un poco («Fundamentos de la Programación» y «Programación I»).
                REGLA 4: Las prácticas suelen ir por grupos («P. MDP-C (Lab. IV)» = práctica de MDP, grupo C, en Lab. IV). Pon el grupo en "grupo" y el aula en "aula".
                REGLA 5: NUNCA inventes fechas absolutas. dia_semana es un entero (1=Lunes, 5=Viernes). Horas en formato HH:MM (24h).
                REGLA 6: Si un dato no aparece en el documento, usa cadena vacía; nunca lo inventes.
                REGLA 7: En "asignaturas_documento" pon TODAS las asignaturas que aparecen en el documento (también las que no son del usuario), como «SIGLAS: Nombre (curso, semestre)».
                Devuelve solo JSON, sin markdown. Formato exigido:
                {
                  "horarios": [
                    {
                      "asignatura_codigo": "SIGLAS",
                      "asignatura_nombre": "Nombre de la asignatura del usuario",
                      "tipo": "Teoría | Práctica",
                      "grupo": "",
                      "dia_semana": 1,
                      "hora_inicio": "17:00",
                      "hora_fin": "19:00",
                      "aula": "Aula X"
                    }
                  ],
                  "asignaturas_documento": ["IPO: Interacción Persona-Ordenador (2.º curso, 1.er semestre)"]
                }""".formatted(list, term);
    }

    /** Asignaturas que la IA vio en el documento (como mucho 60, sin repetir). */
    static List<String> documentSubjects(String raw, JsonMapper json) {
        try {
            JsonNode root = json.readTree(raw == null ? "" : raw.strip());
            JsonNode list = root.path("asignaturas_documento");
            if (!list.isArray()) {
                return List.of();
            }
            java.util.LinkedHashSet<String> out = new java.util.LinkedHashSet<>();
            for (JsonNode n : list) {
                String v = n.asString("").strip();
                if (!v.isEmpty() && out.size() < 60) {
                    out.add(v.length() > 120 ? v.substring(0, 120) : v);
                }
            }
            return List.copyOf(out);
        } catch (JacksonException e) {
            return List.of();
        }
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
            String group = node.path("grupo").asString("").strip();
            // El grupo de prácticas se ve junto al aula (el usuario sabe cuál es el suyo).
            String place = group.isEmpty() ? room : (room.isEmpty() ? "Grupo " + group : room + " · grupo " + group);
            entries.add(new ScheduleEntry(node.path("asignatura_codigo").asString("").strip(), name,
                    kind(node.path("tipo").asString("")), day.asInt(), from, to, place.isEmpty() ? null : place));
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
