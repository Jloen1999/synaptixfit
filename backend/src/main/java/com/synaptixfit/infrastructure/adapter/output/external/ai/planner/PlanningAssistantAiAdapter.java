package com.synaptixfit.infrastructure.adapter.output.external.ai.planner;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.PlanningInbox;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.model.planner.SubjectMatcher;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.SuggestedBlock;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.domain.port.output.planner.PlanningAssistantPort;
import com.synaptixfit.infrastructure.adapter.output.external.ai.AiLanguage;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Sugerencias de planificación semanal con IA (prompt heredado de {@code timeblock_ia_service}
 * con las reglas N1-N10 y H1-H5). Devuelve las propuestas en bruto: el servicio las sanea.
 */
@Component
public class PlanningAssistantAiAdapter implements PlanningAssistantPort {

    static final List<String> DAY_KEYS = List.of("lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo");
    private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("H:mm");

    private final GenerativeAiPort ai;
    private final JsonMapper json;

    public PlanningAssistantAiAdapter(GenerativeAiPort ai, JsonMapper json) {
        this.ai = ai;
        this.json = json;
    }

    @Override
    public List<SuggestedBlock> suggestWeek(PlanningInbox inbox, PlannerZone zone) {
        return parse(ai.generateJson(prompt(inbox, zone), List.of(), 0.4), inbox, zone, json);
    }

    static String prompt(PlanningInbox inbox, PlannerZone zone) {
        String deadlines = inbox.deadlines().isEmpty() ? "No hay entregas pendientes esta semana."
                : inbox.deadlines().stream().map(d -> "- %s (%s, dificultad: %s, fecha límite: %s, asignatura: %s)".formatted(
                        d.title(), d.type().name().toLowerCase(Locale.ROOT), d.difficulty().name().toLowerCase(Locale.ROOT),
                        zone.localDate(d.dueAt()), subjectName(inbox, d))).collect(Collectors.joining("\n"));
        String fixed = inbox.busyBlocks().isEmpty() ? "No hay horarios fijos."
                : inbox.busyBlocks().stream().map(b -> "- Día %d: %s (%s) de %s a %s".formatted(
                        zone.dayOfWeek(b.start()), b.details().topics() == null ? b.type().code() : b.details().topics(),
                        b.type().code(), hhmm(zone.localTime(b.start())), hhmm(zone.localTime(b.end()))))
                .collect(Collectors.joining("\n"));
        String subjects = inbox.subjects().isEmpty() ? "No hay asignaturas activas."
                : inbox.subjects().stream().map(s -> "- %s (créditos: %d, dificultad: %s)".formatted(
                        s.name(), s.credits(), difficulty(s.perceivedDifficulty()))).collect(Collectors.joining("\n"));
        String routines = inbox.routines().isEmpty() ? "No hay rutinas deportivas disponibles."
                : inbox.routines().stream().map(r -> "- %s (objetivo: %s, %d ejercicios, %d semanas)".formatted(
                        r.name(), r.goal(), r.exerciseCount(), r.weeks())).collect(Collectors.joining("\n"));
        int sportMinutes = inbox.minutesPerSportSession();
        int tMax = inbox.maxStudyBlockMinutes();
        return """
                Eres un planificador académico y deportivo para estudiantes universitarios.
                Tu tarea es generar un plan semanal optimizado en formato JSON para la semana que empieza el lunes %s.
                Responde ÚNICAMENTE con el JSON. Sin Markdown, sin bloques de código, sin texto adicional.

                === CONTEXTO DEL USUARIO ===
                - Objetivo de estudio semanal: %.1f horas
                - Sesiones de deporte objetivo: %d sesiones
                - Duración por sesión deportiva: %d minutos
                - Total horas deporte objetivo: %.1f horas

                === ENTREGAS Y EXÁMENES PRÓXIMOS ===
                %s

                === ASIGNATURAS ACTIVAS ===
                %s

                === RUTINAS DEPORTIVAS DISPONIBLES ===
                %s

                === HORARIOS FIJOS (ZONAS PROHIBIDAS — NO PUEDES COLOCAR BLOQUES EN ESTOS HORARIOS) ===
                %s

                === REGLAS INQUEBRANTABLES ===
                N1. PRIORIZACIÓN DE ENTREGAS: Los bloques de estudio deben colocarse 1-3 días antes de cada fecha límite.
                N2. FRANJA PREFERENTE ESTUDIO: Los bloques de estudio se colocan preferentemente entre 15:00 y 22:00.
                N3. FRANJA PREFERENTE DEPORTE: Las sesiones deportivas se colocan preferentemente entre 17:00 y 21:00.
                N4. DURACIÓN ESTUDIO: Cada bloque de estudio debe durar entre 60 y 150 minutos.
                N5. DURACIÓN DEPORTE: Cada sesión deportiva debe durar exactamente %d minutos.
                N6. DISTRIBUCIÓN SEMANAL: Distribuye el estudio en al menos 5 días distintos.
                N7. DESCANSO ENTRE BLOQUES: Deja al menos 30 minutos entre bloques consecutivos del mismo tipo.
                N8. ASIGNATURAS PESADAS PRIMERO: Las asignaturas con dificultad "alta" deben tener al menos 2 bloques antes de las 18:00.
                N9. DESCANSO NOCTURNO: No coloques ningún bloque después de las 22:00.
                N10. EQUILIBRIO CARGA: La carga diaria total no debe superar las 6 horas en ningún día.

                === REGLAS ADICIONALES ===
                H1. No solapes bloques de estudio con bloques de deporte si la carga diaria supera las 4 horas.
                H2. Si una entrega tiene dificultad "alta", asigna al menos 3 bloques de estudio para esa asignatura.
                H3. Prioriza bloques de %d minutos para estudio profundo; usa bloques de %d minutos para repaso ligero.
                H4. Las sesiones deportivas deben espaciarse al menos 48 horas entre sí.
                H5. Los sábados prioriza repaso ligero (60 min); los domingos evita colocar bloques de estudio.

                === FORMATO JSON EXACTO REQUERIDO ===
                {
                  "semana": {
                    "lunes": [
                      {"tipo": "estudio", "hora_inicio": "16:00", "hora_fin": "17:30", "asignatura": "Álgebra", "tema": "Matrices y determinantes"},
                      {"tipo": "deporte", "hora_inicio": "18:00", "hora_fin": "19:00", "rutina": "Rutina de Torso"}
                    ],
                    "martes": [], "miercoles": [], "jueves": [], "viernes": [], "sabado": [], "domingo": []
                  }
                }

                === INSTRUCCIONES FINALES ===
                - Usa EXACTAMENTE las claves: "lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo".
                - Para cada bloque: "tipo" debe ser "estudio" o "deporte".
                - "hora_inicio" y "hora_fin" en formato "HH:mm" (24h).
                - El campo "asignatura" debe coincidir EXACTAMENTE con el nombre de una asignatura activa.
                - El campo "rutina" debe coincidir EXACTAMENTE con el nombre de una rutina disponible.
                - El campo "tema" debe ser específico (máximo 5 palabras).
                - Responde ÚNICAMENTE con el JSON. Sin Markdown, sin explicaciones.
                """.formatted(inbox.weekStart(), inbox.studyHoursTarget(), inbox.sportSessionsTarget(), sportMinutes,
                inbox.sportSessionsTarget() * sportMinutes / 60.0, deadlines, subjects, routines, fixed, sportMinutes,
                tMax, Math.round(tMax * 0.6))
                + "- Escribe el campo \"tema\" en " + AiLanguage.current() + ".\n";
    }

    /** Convierte la respuesta en propuestas; los nombres de asignatura y rutina se resuelven a sus ids. */
    static List<SuggestedBlock> parse(String raw, PlanningInbox inbox, PlannerZone zone, JsonMapper json) {
        JsonNode root;
        try {
            root = json.readTree(raw);
        } catch (JacksonException e) {
            throw new AiUnavailableException("Planning assistant returned invalid JSON");
        }
        JsonNode week = root.path("semana");
        if (!week.isObject()) {
            throw new AiUnavailableException("Planning assistant response has no 'semana' object");
        }
        List<SuggestedBlock> result = new ArrayList<>();
        for (int i = 0; i < DAY_KEYS.size(); i++) {
            LocalDate date = inbox.weekStart().plusDays(i);
            for (JsonNode node : week.path(DAY_KEYS.get(i))) {
                String type = node.path("tipo").asString("");
                ActivityType activity = "deporte".equalsIgnoreCase(type) ? ActivityType.SPORT
                        : "estudio".equalsIgnoreCase(type) ? ActivityType.STUDY : null;
                Optional<LocalTime> start = time(node.path("hora_inicio").asString(""));
                Optional<LocalTime> end = time(node.path("hora_fin").asString(""));
                if (activity == null || start.isEmpty() || end.isEmpty()) {
                    continue;
                }
                SubjectRef subject = activity == ActivityType.STUDY
                        ? SubjectMatcher.match(null, node.path("asignatura").asString(""), inbox.subjects()).orElse(null)
                        : null;
                RoutineRef routine = activity == ActivityType.SPORT ? routine(node.path("rutina").asString(""), inbox) : null;
                String topic = node.path("tema").asString("").strip();
                result.add(new SuggestedBlock(activity, zone.at(date, start.get()), zone.at(date, end.get()),
                        subject == null ? null : subject.id(), subject == null ? null : subject.name(),
                        routine == null ? null : routine.id(), routine == null ? null : routine.name(),
                        topic.isEmpty() ? null : topic));
            }
        }
        return result;
    }

    private static RoutineRef routine(String name, PlanningInbox inbox) {
        String n = SubjectMatcher.normalize(name);
        return inbox.routines().stream().filter(r -> SubjectMatcher.normalize(r.name()).equals(n)).findFirst()
                .orElse(inbox.routines().isEmpty() ? null : inbox.routines().get(0));
    }

    private static Optional<LocalTime> time(String value) {
        try {
            return Optional.of(LocalTime.parse(value.strip(), HH_MM));
        } catch (DateTimeParseException e) {
            return Optional.empty();
        }
    }

    private static String subjectName(PlanningInbox inbox, Deadline d) {
        return inbox.subjects().stream().filter(s -> s.id().equals(d.subjectId())).map(SubjectRef::name)
                .findFirst().orElse("Sin asignatura");
    }

    private static String difficulty(int perceived) {
        return perceived >= 4 ? "alta" : perceived == 3 ? "media" : "baja";
    }

    private static String hhmm(LocalTime t) {
        return "%02d:%02d".formatted(t.getHour(), t.getMinute());
    }
}
