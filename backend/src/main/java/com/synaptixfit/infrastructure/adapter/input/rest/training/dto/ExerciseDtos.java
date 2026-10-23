package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.SessionBookends;
import com.synaptixfit.domain.model.training.ExerciseCategory;
import com.synaptixfit.domain.model.training.CatalogItem;
import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseDraft;
import com.synaptixfit.domain.model.training.ExerciseFilterOptions;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.TrainingGoal;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** DTOs del catálogo de ejercicios. */
public final class ExerciseDtos {

    private ExerciseDtos() {
    }

    /** Músculo, parte del cuerpo o equipamiento. */
    public record CatalogItemResponse(int id, String name, String imageUrl) {
        public static CatalogItemResponse from(CatalogItem c) {
            return new CatalogItemResponse(c.id(), c.name(), c.imageUrl());
        }

        static List<CatalogItemResponse> list(List<CatalogItem> items) {
            return items.stream().map(CatalogItemResponse::from).toList();
        }
    }

    /** Ejercicio del catálogo. {@code purposes} son etiquetas de objetivo («Hipertrofia Muscular»…). */
    public record ExerciseResponse(UUID id, String name, String description, List<String> instructions,
                                   Difficulty difficulty, List<String> purposes, Modality modality,
                                   List<MeasurementType> measurementTypes, boolean circuit, boolean active, double met,
                                   String gifUrl, String previewUrl, List<CatalogItemResponse> bodyParts,
                                   List<CatalogItemResponse> targetMuscles, List<CatalogItemResponse> secondaryMuscles,
                                   List<CatalogItemResponse> equipment, Instant createdAt, Instant updatedAt,
                                   ExerciseCategory category) {
        public static ExerciseResponse from(Exercise e) {
            return new ExerciseResponse(e.id(), e.name(), e.description(), e.instructions(), e.difficulty(),
                    e.purposes(), e.modality(), e.measurementTypes(), e.circuit(), e.active(), e.met(), e.gifUrl(),
                    e.previewUrl(), CatalogItemResponse.list(e.bodyParts()), CatalogItemResponse.list(e.targetMuscles()),
                    CatalogItemResponse.list(e.secondaryMuscles()), CatalogItemResponse.list(e.equipment()),
                    e.createdAt(), e.updatedAt(), e.category());
        }
    }

    /** Valores para los filtros del catálogo. */
    public record ExerciseFilterOptionsResponse(List<CatalogItemResponse> bodyParts, List<CatalogItemResponse> muscles,
                                                List<CatalogItemResponse> equipment) {
        public static ExerciseFilterOptionsResponse from(ExerciseFilterOptions o) {
            return new ExerciseFilterOptionsResponse(CatalogItemResponse.list(o.bodyParts()),
                    CatalogItemResponse.list(o.muscles()), CatalogItemResponse.list(o.equipment()));
        }
    }

    /** Alta o edición de un ejercicio (administración). */
    public record ExerciseRequest(@NotBlank @Size(min = 2, max = 200) String name,
                                  @Size(max = 4000) String description,
                                  @Size(max = 30) List<@NotBlank @Size(max = 1000) String> instructions,
                                  @NotNull Difficulty difficulty,
                                  List<@NotNull TrainingGoal> purposes,
                                  @NotNull Modality modality,
                                  List<@NotNull MeasurementType> measurementTypes,
                                  boolean circuit,
                                  @NotNull @DecimalMin("1.0") @DecimalMax("25.0") Double met,
                                  @Size(max = 2048) String gifUrl,
                                  @Size(max = 2048) String previewUrl,
                                  List<@NotNull Integer> bodyPartIds,
                                  List<@NotNull Integer> targetMuscleIds,
                                  List<@NotNull Integer> secondaryMuscleIds,
                                  List<@NotNull Integer> equipmentIds) {
        public ExerciseDraft toDraft() {
            return new ExerciseDraft(name, description, instructions, difficulty, purposes, modality, measurementTypes,
                    circuit, met, gifUrl, previewUrl, bodyPartIds, targetMuscleIds, secondaryMuscleIds, equipmentIds);
        }
    }

    /** Activar o desactivar un ejercicio. */
    public record SetActiveRequest(@NotNull Boolean active) {
    }

    /** Resultado del borrado: borrado o, si estaba en uso, desactivado. */
    public record DeleteExerciseResponse(boolean deleted, boolean deactivated) {
    }

    /** Calentamiento (movilidad) y vuelta a la calma (estiramientos) de una sesión. */
    public record SessionBookendsResponse(List<ExerciseResponse> warmUp, List<ExerciseResponse> coolDown) {

        public static SessionBookendsResponse from(SessionBookends b) {
            return new SessionBookendsResponse(b.warmUp().stream().map(ExerciseResponse::from).toList(),
                    b.coolDown().stream().map(ExerciseResponse::from).toList());
        }
    }
}
