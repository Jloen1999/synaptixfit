package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.AdjustmentReason;
import com.synaptixfit.domain.model.training.ExerciseAdjustment;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.model.training.RecommendationType;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RecommendationEntity;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Los ajustes de una sugerencia viajan en el jsonb {@code datos}: lo de antes y el motivo, sin migración. */
class RecommendationJsonMappingTest {

    private static final ExerciseParameters BEFORE = new ExerciseParameters(3, 12, 90, 40.0, null, null, null, null);
    private static final ExerciseParameters AFTER = new ExerciseParameters(3, 8, 90, 42.0, null, null, null, null);

    @Test
    void beforeAndReasonSurviveTheRoundTrip() {
        UUID planned = UUID.randomUUID();
        Recommendation r = Recommendation.create(UUID.randomUUID(), RecommendationType.PROGRESSION, "Sube",
                null, UUID.randomUUID(), List.of(new ExerciseAdjustment(planned, UUID.randomUUID(), "Press banca",
                        AFTER, "RPE bajo", BEFORE, AdjustmentReason.LOW_RPE_MORE_WEIGHT)),
                Map.of("rpe", 6), Instant.now());
        RecommendationEntity entity = new RecommendationEntity();
        TrainingPersistenceMapper.copy(r, entity);

        ExerciseAdjustment back = TrainingPersistenceMapper.toDomain(entity).adjustments().getFirst();
        assertThat(back.before().weightKg()).isEqualTo(40.0);
        assertThat(back.before().reps()).isEqualTo(12);
        assertThat(back.parameters().weightKg()).isEqualTo(42.0);
        assertThat(back.reasonCode()).isEqualTo(AdjustmentReason.LOW_RPE_MORE_WEIGHT);
    }

    @Test
    void oldSuggestionsWithoutTheNewKeysOrWithAnUnknownReasonStillLoad() {
        UUID planned = UUID.randomUUID();
        Map<String, Object> adjustment = new LinkedHashMap<>();
        adjustment.put("plannedExerciseId", planned.toString());
        adjustment.put("exerciseName", "Sentadilla");
        adjustment.put("sets", 4);
        adjustment.put("reps", 8);
        adjustment.put("restSeconds", 120);
        adjustment.put("weightKg", 60.0);
        Map<String, Object> unknown = new LinkedHashMap<>(adjustment);
        unknown.put("reasonCode", "ALGO_NUEVO");
        RecommendationEntity entity = new RecommendationEntity();
        entity.setId(UUID.randomUUID());
        entity.setUsuarioId(UUID.randomUUID());
        entity.setTipo("progresion");
        entity.setTitulo("Antigua");
        entity.setDatos(new LinkedHashMap<>(Map.of("adjustments", List.of(adjustment, unknown))));

        List<ExerciseAdjustment> loaded = TrainingPersistenceMapper.toDomain(entity).adjustments();
        assertThat(loaded).hasSize(2).allSatisfy(a -> {
            assertThat(a.before()).isNull();
            assertThat(a.reasonCode()).isNull();
            assertThat(a.parameters().weightKg()).isEqualTo(60.0);
        });
    }
}
