package com.synaptixfit.infrastructure.adapter.output.external.ai.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.ActivityLevel;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedExercise;
import com.synaptixfit.domain.model.training.generation.RoutineRefinement;
import com.synaptixfit.domain.model.training.generation.RoutineRefinementRequest;
import com.synaptixfit.domain.model.training.generation.TrainingHistory;
import com.synaptixfit.domain.model.training.generation.TrainingProfile;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

class RoutineGeneratorAiAdapterTest {

    private final List<String> prompts = new ArrayList<>();
    private String response = "{}";
    private final RoutineGeneratorAiAdapter adapter = new RoutineGeneratorAiAdapter(
            new com.synaptixfit.domain.port.output.ai.GenerativeAiPort() {
                public String generateText(String prompt, List<com.synaptixfit.domain.port.output.ai.AiAttachment> a, double t) {
                    throw new UnsupportedOperationException();
                }
                public String generateJson(String prompt, List<com.synaptixfit.domain.port.output.ai.AiAttachment> a, double t) {
                    prompts.add(prompt);
                    return response;
                }
            }, JsonMapper.builder().build());

    private RoutineRefinementRequest request(UUID exerciseId) {
        TrainingProfile profile = new TrainingProfile(20, "mujer", 55, 160, 21.5, ActivityLevel.LIGHT,
                TrainingGoal.HYPERTROPHY, List.of("mancuerna"), 3, 45, List.of());
        ProposedDay day = new ProposedDay(1, "D1 · Full-Body", List.of(new ProposedExercise(exerciseId, "Sentadilla",
                new ExerciseParameters(3, 10, 90, 20.0, null, null, null, null))));
        return new RoutineRefinementRequest(profile, TrainingGoal.HYPERTROPHY, 2, "Base", "Desc", List.of(day), List.of(),
                Map.of(), AcademicContext.NONE, null, TrainingHistory.EMPTY, List.of("Modo exámenes activo"));
    }

    @Test
    void promptContainsBaseWeekAndRules() {
        UUID id = UUID.randomUUID();
        response = "{\"nombre\":\"N\"}";
        adapter.refine(request(id));
        assertThat(prompts.getFirst()).contains(id.toString(), "Sentadilla", "Hipertrofia Muscular", "2 semana(s)",
                "Modo exámenes activo", "mancuerna");
    }

    @Test
    void parsesNamesAndDaysTolerantly() {
        UUID id = UUID.randomUUID();
        response = """
                {"nombre":"Potencia","descripcion":"D","nombresSemanas":{"1":"Adaptación","x":"ignorar"},
                 "nombresDias":{"1":{"1":"Torso"}},
                 "dias":{"1":[{"exerciseId":"%s","series":4,"repeticiones":"diez","segundosDescanso":60,"pesoKg":22.5},
                              {"exerciseId":"no-uuid","series":3}]}}""".formatted(id);
        RoutineRefinement r = adapter.refine(request(id));
        assertThat(r.name()).isEqualTo("Potencia");
        assertThat(r.weekNames()).containsExactly(Map.entry(1, "Adaptación"));
        assertThat(r.dayNames().get(1)).containsEntry(1, "Torso");
        assertThat(r.days().get(1)).hasSize(2);
        assertThat(r.days().get(1).get(0).exerciseId()).isEqualTo(id);
        assertThat(r.days().get(1).get(0).reps()).isNull();
        assertThat(r.days().get(1).get(0).weightKg()).isEqualTo(22.5);
        assertThat(r.days().get(1).get(1).exerciseId()).isNull();
    }

    @Test
    void invalidJsonIsReportedAsAiUnavailable() {
        response = "esto no es json";
        assertThatThrownBy(() -> adapter.refine(request(UUID.randomUUID()))).isInstanceOf(AiUnavailableException.class);
        response = "[1,2]";
        assertThatThrownBy(() -> adapter.refine(request(UUID.randomUUID()))).isInstanceOf(AiUnavailableException.class);
    }
}
