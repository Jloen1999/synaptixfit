package com.synaptixfit.infrastructure.adapter.output.external.ai.training;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.training.DailyCheckIn;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.GoalParameters;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedExercise;
import com.synaptixfit.domain.model.training.generation.RoutineRefinement;
import com.synaptixfit.domain.model.training.generation.RoutineRefinement.RefinedExercise;
import com.synaptixfit.domain.model.training.generation.RoutineRefinementRequest;
import com.synaptixfit.domain.model.training.generation.TrainingHistory;
import com.synaptixfit.domain.model.training.generation.TrainingProfile;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.domain.port.output.training.RoutineGeneratorPort;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Refinado de rutinas con IA en modo JSON. Construye el prompt (en español) con el perfil, el
 * contexto, la semana base y el catálogo de candidatos, y parsea la respuesta. La validación de lo
 * que propone la IA la hace el dominio ({@code ProposalRepair}).
 */
@Component
public class RoutineGeneratorAiAdapter implements RoutineGeneratorPort {

    private static final double TEMPERATURE = 0.4;

    private final GenerativeAiPort ai;
    private final JsonMapper json;

    public RoutineGeneratorAiAdapter(GenerativeAiPort ai, JsonMapper json) {
        this.ai = ai;
        this.json = json;
    }

    @Override
    public RoutineRefinement refine(RoutineRefinementRequest request) {
        String raw = ai.generateJson(prompt(request), List.of(), TEMPERATURE);
        return parse(raw);
    }

    // ------------------------------------------------------------------ prompt

    String prompt(RoutineRefinementRequest r) {
        TrainingGoal goal = r.goal();
        GoalParameters params = GoalParameters.of(goal);
        StringBuilder base = new StringBuilder();
        for (ProposedDay day : r.baseDays()) {
            base.append("  Día ").append(day.dayNumber()).append(" (").append(day.name()).append("):\n");
            for (ProposedExercise e : day.exercises()) {
                ExerciseParameters p = e.parameters();
                base.append("    - ").append(e.exerciseName()).append("  id=").append(e.exerciseId())
                        .append("  (").append(p.sets()).append("x").append(p.reps()).append(", descanso ")
                        .append(p.restSeconds()).append("s").append(p.weightKg() == null ? "" : ", " + p.weightKg() + " kg")
                        .append(")\n");
            }
        }
        String equipment = r.profile().equipment().isEmpty() ? "peso corporal" : String.join(", ", r.profile().equipment());
        return """
                Eres un algoritmo de optimización deportiva. Refinas una rutina generada por reglas aplicando criterios lógicos según el perfil del usuario. No eres creativo, no inventas ejercicios.

                %s
                SEMANA BASE (se repite durante %d semana(s) con periodización automática):
                %s
                CATÁLOGO DE EJERCICIOS PARA SUSTITUCIONES (usa solo estos ids):
                %s

                REGLAS:
                1. NOMBRE: hazlo personal y motivador (p. ej. «Potencia Total — Fase de Carga»). No incluyas números de semanas ni de días.
                2. DESCRIPCIÓN: explica el enfoque de forma inspiradora, sin números de días ni semanas.%s
                3. VARIACIÓN (opcional, máximo 1-2 cambios por día): puedes sustituir un ejercicio por otro del catálogo que trabaje los MISMOS músculos y use equipamiento compatible (%s).
                4. ORDEN: compuestos primero y aislados al final. No cambies series, repeticiones ni descanso al reordenar.
                5. PARÁMETROS: no los cambies salvo razón clara. Ya están calculados para «%s» (%d-%d series, %d-%d repeticiones, %d-%ds de descanso).
                6. NOMBRA LOS DÍAS según sus grupos musculares (p. ej. «Torso: empuje y press»). Nada de nombres genéricos como «Día 1».
                7. NOMBRA LAS SEMANAS según su fase (p. ej. «Adaptación: técnica y activación», «Carga progresiva», «Descarga: recuperación activa»).

                Responde SOLO con este JSON:
                {
                  "nombre": "…",
                  "descripcion": "…",
                  "nombresSemanas": {"1": "…"},
                  "nombresDias": {"1": {"%s": "…"}},
                  "dias": {
                    "%s": [{"exerciseId": "id", "series": 3, "repeticiones": 10, "segundosDescanso": 90, "pesoKg": null, "duracionSegundos": null, "distanciaMetros": null, "tiempoIsometricoSegundos": null}]
                  }
                }
                "dias" debe contener TODOS los días y el MISMO número de ejercicios por día que la semana base, en el orden final. "nombresSemanas" debe tener una entrada por semana (1 a %d).
                """.formatted(context(r), r.durationWeeks(), base, candidates(r.candidates()),
                r.adjustmentReasons().isEmpty() ? "" : " Menciona sutilmente que se adaptó la intensidad al contexto actual del usuario.",
                equipment, goal.label(), params.setsMin(), params.setsMax(), params.repsMin(), params.repsMax(),
                params.restMin(), params.restMax(), firstDay(r), firstDay(r), r.durationWeeks());
    }

    private static String firstDay(RoutineRefinementRequest r) {
        return r.baseDays().isEmpty() ? "1" : String.valueOf(r.baseDays().getFirst().dayNumber());
    }

    private String candidates(List<Exercise> candidates) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (Exercise e : candidates) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", e.id().toString());
            m.put("nombre", e.name());
            m.put("musculos", e.targetMuscleNames());
            m.put("dificultad", e.difficulty().name().toLowerCase(Locale.ROOT));
            m.put("modalidad", e.modality().name().toLowerCase(Locale.ROOT));
            m.put("compuesto", e.isCompound());
            m.put("equipamiento", e.equipmentNames());
            list.add(m);
        }
        return json.writeValueAsString(list);
    }

    private static String context(RoutineRefinementRequest r) {
        TrainingProfile p = r.profile();
        StringBuilder sb = new StringBuilder("PERFIL DEL USUARIO:\n");
        sb.append(String.format(Locale.ROOT, "- %d años, %s, %.1f kg, %.0f cm, IMC %.1f, nivel de actividad %s%n",
                p.age(), p.sex(), p.weightKg(), p.heightCm(), p.bmi(), p.activityLevel().name().toLowerCase(Locale.ROOT)));
        sb.append("- Objetivo: ").append(r.goal().label()).append('\n');
        sb.append("- ").append(p.daysPerWeek()).append(" días por semana, ").append(p.minutesPerSession())
                .append(" minutos por sesión\n");
        sb.append("SEGURIDAD:\n").append(safetyRules(p));
        DailyCheckIn c = r.checkIn();
        if (c != null) {
            sb.append("ESTADO DE HOY: sueño ").append(c.sleepQuality()).append("/5, estrés ").append(c.stress())
                    .append("/5, energía ").append(c.energy()).append("/5, dolor ").append(c.soreness()).append("/5");
            if (!c.painZones().isEmpty()) {
                sb.append(", zonas con dolor: ").append(String.join(", ", c.painZones()));
            }
            sb.append(c.readyToTrain() ? "" : ", NO se siente listo para entrenar").append('\n');
        }
        AcademicContext a = r.academic();
        if (a != null) {
            sb.append(String.format(Locale.ROOT, "CONTEXTO ACADÉMICO: %.1f h de estudio esta semana, estrés %.0f/10, %d evaluaciones",
                    a.realStudyHours(), a.stressLevel(), a.evaluationsThisWeek()));
            if (a.daysToNextExam() != null) {
                sb.append(", próximo examen o entrega en ").append(a.daysToNextExam()).append(" días");
            }
            sb.append('\n');
        }
        TrainingHistory h = r.history();
        if (h != null && h.totalCompletedSessions() > 0) {
            sb.append(String.format(Locale.ROOT, "HISTORIAL: %d sesiones recientes, RPE medio %.1f, %d semanas seguidas entrenando%n",
                    h.totalCompletedSessions(), h.averageRpe(), h.consecutiveWeeks()));
        }
        if (!r.adjustmentReasons().isEmpty()) {
            sb.append("AJUSTES YA APLICADOS: ").append(String.join(" | ", r.adjustmentReasons())).append('\n');
        }
        return sb.toString();
    }

    private static String safetyRules(TrainingProfile p) {
        StringBuilder sb = new StringBuilder();
        if (p.bmi() > 30) {
            sb.append("- IMC > 30: prioriza bajo impacto articular; evita saltos pliométricos y carrera.\n");
        } else if (p.bmi() > 25) {
            sb.append("- IMC 25-30: modera el alto impacto; técnica ante todo.\n");
        }
        if (p.bmi() < 18.5) {
            sb.append("- IMC < 18,5: prioriza ganar masa muscular y evita volúmenes excesivos.\n");
        }
        if (p.age() > 50) {
            sb.append("- Más de 50 años: fortalecimiento articular y equilibrio, sin cargas máximas, 8-15 repeticiones.\n");
        }
        if (p.age() < 18) {
            sb.append("- Menor de 18: técnica sobre carga, sin pesos máximos.\n");
        }
        return sb.isEmpty() ? "- Sin restricciones específicas.\n" : sb.toString();
    }

    // ------------------------------------------------------------------ parseo

    RoutineRefinement parse(String raw) {
        JsonNode root;
        try {
            root = json.readTree(raw);
        } catch (JacksonException e) {
            throw new AiUnavailableException("AI returned invalid JSON for the routine");
        }
        if (root == null || !root.isObject()) {
            throw new AiUnavailableException("AI returned an unexpected routine payload");
        }
        Map<Integer, List<RefinedExercise>> days = new LinkedHashMap<>();
        JsonNode daysNode = root.has("dias") ? root.path("dias") : root.path("estructura").path("1");
        for (Map.Entry<String, JsonNode> day : daysNode.properties()) {
            Integer number = intKey(day.getKey());
            if (number == null || !day.getValue().isArray()) {
                continue;
            }
            List<RefinedExercise> list = new ArrayList<>();
            for (JsonNode e : day.getValue()) {
                list.add(new RefinedExercise(uuid(e.path("exerciseId")), integer(e.path("series")),
                        integer(e.path("repeticiones")), integer(e.path("segundosDescanso")), decimal(e.path("pesoKg")),
                        integer(e.path("duracionSegundos")), integer(e.path("distanciaMetros")),
                        integer(e.path("tiempoIsometricoSegundos"))));
            }
            days.put(number, list);
        }
        Map<Integer, String> weekNames = new LinkedHashMap<>();
        for (Map.Entry<String, JsonNode> w : root.path("nombresSemanas").properties()) {
            Integer number = intKey(w.getKey());
            if (number != null && w.getValue().isString()) {
                weekNames.put(number, w.getValue().asString());
            }
        }
        Map<Integer, Map<Integer, String>> dayNames = new LinkedHashMap<>();
        for (Map.Entry<String, JsonNode> w : root.path("nombresDias").properties()) {
            Integer week = intKey(w.getKey());
            if (week == null) {
                continue;
            }
            Map<Integer, String> names = new LinkedHashMap<>();
            for (Map.Entry<String, JsonNode> d : w.getValue().properties()) {
                Integer day = intKey(d.getKey());
                if (day != null && d.getValue().isString()) {
                    names.put(day, d.getValue().asString());
                }
            }
            dayNames.put(week, names);
        }
        return new RoutineRefinement(text(root.path("nombre")), text(root.path("descripcion")), days, weekNames, dayNames);
    }

    private static Integer intKey(String key) {
        try {
            return Integer.valueOf(key.strip());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static UUID uuid(JsonNode node) {
        try {
            return node.isString() ? UUID.fromString(node.asString().strip()) : null;
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static Integer integer(JsonNode node) {
        return node.isNumber() ? node.asInt() : null;
    }

    private static Double decimal(JsonNode node) {
        return node.isNumber() ? node.asDouble() : null;
    }

    private static String text(JsonNode node) {
        return node.isString() ? node.asString() : null;
    }
}
