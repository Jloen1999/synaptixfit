package com.synaptixfit.infrastructure.adapter.output.external.ai.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.ClassKind;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.planner.PlanningInbox;
import com.synaptixfit.domain.model.planner.RoutineRef;
import com.synaptixfit.domain.model.planner.ScheduleEntry;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.SuggestedBlock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

/** Saneado de las respuestas de la IA (sin llamadas reales). */
class PlannerAiAdaptersTest {

    private static final JsonMapper JSON = JsonMapper.builder().build();
    private static final PlannerZone ZONE = PlannerZone.of("Europe/Madrid");

    @Test
    void scheduleParserKeepsOnlyValidEntries() {
        String raw = """
                ```json
                [
                  {"asignatura_codigo": "ALG", "asignatura_nombre": "Álgebra", "tipo": "Práctica",
                   "dia_semana": 2, "hora_inicio": "9:00", "hora_fin": "11:00", "aula": "B2"},
                  {"asignatura_nombre": "Sin día", "dia_semana": 9, "hora_inicio": "09:00", "hora_fin": "10:00"},
                  {"asignatura_nombre": "Hora rara", "dia_semana": 1, "hora_inicio": "25:00", "hora_fin": "26:00"},
                  {"asignatura_nombre": "", "dia_semana": 1, "hora_inicio": "09:00", "hora_fin": "10:00"},
                  {"asignatura_nombre": "Física", "tipo": "Teoría", "dia_semana": 5, "hora_inicio": "15:30", "hora_fin": "17:00", "aula": ""}
                ]
                ```""";

        List<ScheduleEntry> entries = ScheduleScannerAiAdapter.parse(raw, JSON);

        assertThat(entries).hasSize(2);
        assertThat(entries.get(0)).isEqualTo(new ScheduleEntry("ALG", "Álgebra", ClassKind.PRACTICE, 2,
                LocalTime.of(9, 0), LocalTime.of(11, 0), "B2"));
        assertThat(entries.get(1).classKind()).isEqualTo(ClassKind.THEORY);
        assertThat(entries.get(1).room()).isNull();
        assertThat(ScheduleScannerAiAdapter.parse("{\"horarios\": []}", JSON)).isEmpty();
        assertThatThrownBy(() -> ScheduleScannerAiAdapter.parse("no es json", JSON))
                .isInstanceOf(AiUnavailableException.class);
        assertThat(ScheduleScannerAiAdapter.prompt(List.of("Álgebra", "Física")))
                .contains("Solo busca horarios para estas asignaturas: Álgebra, Física");
    }

    @Test
    void planningParserResolvesDaysSubjectsAndRoutines() {
        SubjectRef algebra = new SubjectRef(UUID.randomUUID(), "Álgebra", "ALG", 4, 6, null);
        RoutineRef routine = new RoutineRef(UUID.randomUUID(), "Rutina de Torso", "Fuerza", 4, 6, List.of());
        PlanningInbox inbox = new PlanningInbox(LocalDate.of(2026, 10, 19), 10, 2, 60, 90, List.of(algebra), List.of(),
                List.of(routine), List.of());
        String raw = """
                {"semana": {
                  "lunes": [{"tipo": "estudio", "hora_inicio": "16:00", "hora_fin": "17:30", "asignatura": "algebra", "tema": "Matrices"}],
                  "miercoles": [{"tipo": "deporte", "hora_inicio": "18:00", "hora_fin": "19:00", "rutina": "Rutina de Torso"},
                                {"tipo": "siesta", "hora_inicio": "15:00", "hora_fin": "16:00"},
                                {"tipo": "estudio", "hora_inicio": "xx", "hora_fin": "16:00"}]
                }}""";

        List<SuggestedBlock> blocks = PlanningAssistantAiAdapter.parse(raw, inbox, ZONE, JSON);

        assertThat(blocks).hasSize(2);
        assertThat(blocks.get(0).type()).isEqualTo(ActivityType.STUDY);
        assertThat(blocks.get(0).start()).isEqualTo(Instant.parse("2026-10-19T14:00:00Z"));
        assertThat(blocks.get(0).subjectId()).isEqualTo(algebra.id());
        assertThat(blocks.get(1).routineId()).isEqualTo(routine.id());
        assertThat(blocks.get(1).start()).isEqualTo(Instant.parse("2026-10-21T16:00:00Z"));
        assertThatThrownBy(() -> PlanningAssistantAiAdapter.parse("{\"plan\": 1}", inbox, ZONE, JSON))
                .isInstanceOf(AiUnavailableException.class);
        assertThat(PlanningAssistantAiAdapter.prompt(inbox, ZONE))
                .contains("N10. EQUILIBRIO CARGA").contains("H5.").contains("- Álgebra (créditos: 6, dificultad: alta)");
    }
}
