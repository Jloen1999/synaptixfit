package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.ExerciseNote;
import com.synaptixfit.domain.model.training.ExerciseTips;
import java.util.Optional;
import com.synaptixfit.domain.model.training.CatalogItem;
import com.synaptixfit.domain.model.training.CatalogTranslations;
import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseCategory;
import com.synaptixfit.domain.model.training.ExerciseDraft;
import com.synaptixfit.domain.model.training.ExerciseFilterOptions;
import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.SessionBookends;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.infrastructure.adapter.input.rest.support.LocalizedNames;
import jakarta.validation.Valid;
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
            return from(c, LocalizedNames.current());
        }

        static CatalogItemResponse from(CatalogItem c, CatalogTranslations names) {
            return new CatalogItemResponse(c.id(), names.term(c.name()), c.imageUrl());
        }

        static List<CatalogItemResponse> list(List<CatalogItem> items, CatalogTranslations names) {
            return items.stream().map(c -> from(c, names)).toList();
        }

        static List<CatalogItemResponse> list(List<CatalogItem> items) {
            return list(items, LocalizedNames.current());
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
        /** En el idioma de la petición. */
        public static ExerciseResponse from(Exercise e) {
            return from(e, LocalizedNames.current());
        }

        /**
         * Con los nombres canónicos en español, sea cual sea el idioma: la administración edita el
         * catálogo y, si recibiera la traducción, al guardar la escribiría sobre el español que usan las
         * reglas de rutinas.
         */
        public static ExerciseResponse canonical(Exercise e) {
            return from(e, CatalogTranslations.NONE);
        }

        private static ExerciseResponse from(Exercise e, CatalogTranslations names) {
            return new ExerciseResponse(e.id(), names.exercise(e.id(), e.name()), e.description(), e.instructions(), e.difficulty(),
                    e.purposes(), e.modality(), e.measurementTypes(), e.circuit(), e.active(), e.met(), e.gifUrl(),
                    e.previewUrl(), CatalogItemResponse.list(e.bodyParts(), names),
                    CatalogItemResponse.list(e.targetMuscles(), names), CatalogItemResponse.list(e.secondaryMuscles(), names),
                    CatalogItemResponse.list(e.equipment(), names), e.createdAt(), e.updatedAt(), e.category());
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
                                  List<@NotNull Integer> equipmentIds,
                                  @Valid ExerciseNamesDto translations) {
        public ExerciseDraft toDraft() {
            return new ExerciseDraft(name, description, instructions, difficulty, purposes, modality, measurementTypes,
                    circuit, met, gifUrl, previewUrl, bodyPartIds, targetMuscleIds, secondaryMuscleIds, equipmentIds,
                    translations == null ? null : translations.toDomain());
        }
    }

    /**
     * Nombre del ejercicio en los demás idiomas de la app (vacío o nulo: se muestra en español). En el
     * alta o edición, omitirlo deja los que tenga.
     */
    public record ExerciseNamesDto(@Size(max = 200) String en, @Size(max = 200) String fr,
                                   @Size(max = 200) String pt) {

        public static ExerciseNamesDto from(ExerciseNameTranslations n) {
            return new ExerciseNamesDto(n.en(), n.fr(), n.pt());
        }

        ExerciseNameTranslations toDomain() {
            return new ExerciseNameTranslations(en, fr, pt);
        }
    }

    /** Nombre en español para el que se piden propuestas de traducción. */
    public record ExerciseNameSuggestionRequest(@NotBlank @Size(min = 2, max = 200) String name) {
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

    /** «Las claves» y «Errores comunes» de un ejercicio (ADR 0031). */
    public record ExerciseTipsResponse(List<String> keyPoints, List<String> commonMistakes) {
        public static ExerciseTipsResponse from(ExerciseTips t) {
            return new ExerciseTipsResponse(t.keyPoints(), t.commonMistakes());
        }
    }

    /** Nota propia sobre un ejercicio; {@code text} y {@code updatedAt} nulos si no hay. */
    public record ExerciseNoteResponse(String text, Instant updatedAt) {
        public static ExerciseNoteResponse from(Optional<ExerciseNote> note) {
            return note.map(n -> new ExerciseNoteResponse(n.text(), n.updatedAt()))
                    .orElse(new ExerciseNoteResponse(null, null));
        }
    }

    /** Guardar la nota propia: hasta 500 caracteres; vacío o nulo la borra. */
    public record ExerciseNoteRequest(@Size(max = ExerciseNote.MAX_LENGTH) String text) {
    }
}
