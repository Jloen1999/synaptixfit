package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.training.GenerateRoutineProposalUseCase;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.training.NoCompatibleExercisesException;
import com.synaptixfit.domain.exception.training.TrainingProfileRequiredException;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.generation.AcademicContext;
import com.synaptixfit.domain.model.training.generation.ActivityLevel;
import com.synaptixfit.domain.model.training.generation.PhysiologicalContext;
import com.synaptixfit.domain.model.training.generation.RoutineProposal;
import com.synaptixfit.domain.model.training.generation.RoutineRefinement;
import com.synaptixfit.domain.model.training.generation.RoutineRefinementRequest;
import com.synaptixfit.domain.model.training.generation.TrainingProfile;
import com.synaptixfit.domain.port.output.training.RoutineGeneratorPort;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.domain.model.insights.AcwrZone;
import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.model.insights.CrossRegulationView;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class RoutineGenerationServiceTest {

    private static final UUID USER = UUID.randomUUID();

    private final TrainingFakes.Exercises exercises = new TrainingFakes.Exercises();
    private final TrainingFakes.Sessions sessions = new TrainingFakes.Sessions();
    private final TrainingFakes.CheckIns checkIns = new TrainingFakes.CheckIns();
    private TrainingProfile profile;
    private AcademicContext academic = AcademicContext.NONE;
    private Function<RoutineRefinementRequest, RoutineRefinement> ai = r -> {
        throw new AiUnavailableException("sin clave");
    };
    private final List<RoutineRefinementRequest> aiCalls = new ArrayList<>();
    private RoutineGenerationService service;

    @BeforeEach
    void setUp() {
        for (String muscle : List.of("Pectoral mayor", "Dorsal ancho", "Cuádriceps", "Isquiotibiales", "Glúteo mayor",
                "Deltoides medio", "Bíceps braquial", "Tríceps braquial")) {
            exercises.add(TrainingFakes.exercise("Ejercicio de " + muscle, Modality.STRENGTH,
                    List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT), List.of(muscle),
                    List.of("Core", "Antebrazo"), TrainingGoal.HYPERTROPHY));
            exercises.add(TrainingFakes.exercise("Aislado de " + muscle, Modality.STRENGTH,
                    List.of(MeasurementType.REPETITIONS, MeasurementType.WEIGHT), List.of(muscle), List.of(),
                    TrainingGoal.HYPERTROPHY));
        }
        profile = new TrainingProfile(22, "mujer", 60, 165, 22, ActivityLevel.MODERATE, TrainingGoal.HYPERTROPHY,
                List.of(), 3, 60, List.of(1, 3, 5));
        TrainingContextPort context = new TrainingContextPort() {
            public Optional<Double> bodyWeightKg(UUID userId) { return Optional.of(60.0); }
            public Optional<TrainingProfile> profile(UUID userId) { return Optional.ofNullable(profile); }
            public AcademicContext academicContext(UUID userId, LocalDate today) { return academic; }
            public PhysiologicalContext physiologicalContext(UUID userId, LocalDate today) {
                return new PhysiologicalContext(null, null, 5, 3);
            }
            public Optional<GoalChange> latestGoalChange(UUID userId) { return Optional.empty(); }
        };
        RoutineGeneratorPort generator = request -> {
            aiCalls.add(request);
            return ai.apply(request);
        };
        Instant now = Instant.parse("2026-10-07T09:00:00Z");
        // Indicadores simulados: devuelven la carga cognitiva y el ACWR del contexto académico de la prueba.
        GetCognitiveStateUseCase cognitiveState = (userId, tz) -> new CognitiveState(userId,
                academic.cognitiveLoad() == null ? 0 : academic.cognitiveLoad(), 1, 0, null, null, now, now);
        GetCrossRegulationUseCase crossRegulation = (userId, tz) -> new CrossRegulationView(
                new CrossRegulationState(userId, 0, 0, 90, null, now), academic.acwr(), AcwrZone.of(academic.acwr()),
                0, 1);
        service = new RoutineGenerationService(context, exercises, sessions, checkIns, generator, cognitiveState,
                crossRegulation, Clock.fixed(now, ZoneOffset.UTC), ZoneOffset.UTC);
    }

    private RoutineProposal generate(int weeks, boolean useAi) {
        return service.generate(new GenerateRoutineProposalUseCase.Command(USER, weeks, null, useAi));
    }

    @Test
    void requiresAWellnessProfile() {
        profile = null;
        assertThatThrownBy(() -> generate(1, false)).isInstanceOf(TrainingProfileRequiredException.class);
    }

    @Test
    void rulesOnlyProposalCoversEveryWeekWithPeriodization() {
        RoutineProposal p = generate(4, false);
        assertThat(p.aiRefined()).isFalse();
        assertThat(p.aiNotice()).isNull();
        assertThat(aiCalls).isEmpty();
        assertThat(p.weeks()).extracting(RoutineProposal.ProposedWeek::type)
                .containsExactly(WeekType.ADAPTATION, WeekType.LOAD, WeekType.LOAD, WeekType.DELOAD);
        assertThat(p.weeks()).allSatisfy(w -> assertThat(w.days()).extracting(RoutineProposal.ProposedDay::dayNumber)
                .containsExactly(1, 3, 5));
        assertThat(p.weeks().getFirst().days().getFirst().exercises()).hasSize(5);
        int loadSets = p.weeks().get(1).days().getFirst().exercises().getFirst().parameters().sets();
        int deloadSets = p.weeks().get(3).days().getFirst().exercises().getFirst().parameters().sets();
        assertThat(deloadSets).isLessThan(loadSets);
        assertThat(p.name()).isEqualTo("Hipertrofia Muscular · Full-Body · 4 semanas");
        assertThat(p.split()).isEqualTo("Full-Body");
    }

    @Test
    void examSoonReducesVolumeAndExplainsWhy() {
        academic = new AcademicContext(10, 25, 9, 4, 0, 3, 5, 3, 0.9, null);
        RoutineProposal p = generate(1, false);
        assertThat(p.adjustmentReasons()).anyMatch(r -> r.startsWith("Regulación cruzada"))
                .contains("Modo exámenes activo");
        assertThat(p.weeks().getFirst().days().getFirst().exercises().size()).isLessThan(5);
        assertThat(p.totalLoadFactor()).isGreaterThan(0.5);
    }

    @Test
    void aiFailureFallsBackToTheRulesProposal() {
        RoutineProposal p = generate(2, true);
        assertThat(aiCalls).hasSize(1);
        assertThat(aiCalls.getFirst().candidates()).hasSizeLessThanOrEqualTo(60);
        assertThat(p.aiRefined()).isFalse();
        assertThat(p.aiNotice()).isEqualTo(RoutineGenerationService.AI_FALLBACK_NOTICE);
        assertThat(p.weeks()).hasSize(2);
    }

    @Test
    void aiOutputIsRepairedSanitizedAndNamed() {
        ai = request -> {
            var firstDay = request.baseDays().getFirst();
            UUID replacement = request.candidates().stream().map(Exercise::id)
                    .filter(id -> firstDay.exercises().stream().noneMatch(e -> e.exerciseId().equals(id)))
                    .findFirst().orElseThrow();
            List<RoutineRefinement.RefinedExercise> day = new ArrayList<>();
            day.add(new RoutineRefinement.RefinedExercise(replacement, 4, 12, 75, 20.0, null, null, null));
            day.add(new RoutineRefinement.RefinedExercise(UUID.randomUUID(), 4, 12, 75, null, null, null, null));
            day.add(new RoutineRefinement.RefinedExercise(firstDay.exercises().get(2).exerciseId(), 99, 500, 5, null,
                    null, null, null));
            return new RoutineRefinement("Potencia total 8 semanas", "Descripción IA", Map.of(firstDay.dayNumber(), day),
                    Map.of(1, "Adaptación técnica", 2, "Carga progresiva"),
                    Map.of(1, Map.of(firstDay.dayNumber(), "Torso: empuje")));
        };
        RoutineProposal base = generate(2, false);
        RoutineProposal p = generate(2, true);
        assertThat(p.aiRefined()).isTrue();
        assertThat(p.name()).isEqualTo("Potencia total 2 semanas");
        assertThat(p.description()).isEqualTo("Descripción IA");
        assertThat(p.weeks()).extracting(RoutineProposal.ProposedWeek::name)
                .containsExactly("Adaptación técnica", "Carga progresiva");
        assertThat(p.weeks().get(1).days().getFirst().name()).isEqualTo("Torso: empuje");

        var refinedDay = p.weeks().get(1).days().getFirst().exercises();
        var baseDay = base.weeks().get(1).days().getFirst().exercises();
        assertThat(refinedDay).hasSameSizeAs(baseDay);
        assertThat(refinedDay.get(0).exerciseId()).isNotEqualTo(baseDay.get(0).exerciseId());
        assertThat(refinedDay.get(0).parameters().reps()).isEqualTo(12);
        // id inexistente → se conserva el de la base; parámetros fuera de rango → los de la base
        assertThat(refinedDay.get(1).exerciseId()).isEqualTo(baseDay.get(1).exerciseId());
        assertThat(refinedDay.get(2).parameters().reps()).isEqualTo(baseDay.get(2).parameters().reps());
    }

    @Test
    void refineSubstitutesInEveryWeekAndKeepsParametersOfOtherWeeks() {
        RoutineProposal base = generate(3, false);
        var firstDay = base.weeks().getFirst().days().getFirst();
        UUID original = firstDay.exercises().getFirst().exerciseId();
        ai = request -> {
            UUID replacement = request.candidates().stream().map(Exercise::id)
                    .filter(id -> request.baseDays().getFirst().exercises().stream().noneMatch(e -> e.exerciseId().equals(id)))
                    .findFirst().orElseThrow();
            return new RoutineRefinement(null, null, Map.of(firstDay.dayNumber(), List.of(
                    new RoutineRefinement.RefinedExercise(replacement, null, null, null, null, null, null, null))),
                    Map.of(), Map.of());
        };
        RoutineProposal refined = service.refine(USER, base);
        assertThat(refined.name()).isEqualTo(base.name());
        var week3Before = base.weeks().get(2).days().getFirst().exercises().getFirst();
        var week3After = refined.weeks().get(2).days().getFirst().exercises().getFirst();
        assertThat(week3After.exerciseId()).isNotEqualTo(original);
        assertThat(week3After.parameters()).isEqualTo(week3Before.parameters());
    }

    @Test
    void noCompatibleExercisesIsAnError() {
        profile = new TrainingProfile(22, "mujer", 60, 165, 22, ActivityLevel.MODERATE, TrainingGoal.MOBILITY,
                List.of(), 3, 60, List.of());
        assertThatThrownBy(() -> generate(1, false)).isInstanceOf(NoCompatibleExercisesException.class);
    }
}
