package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.neuro.ExerciseEnergy;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;

/** Ejercicio del catálogo con sus músculos, partes del cuerpo y equipamiento resueltos. */
public record Exercise(UUID id, String name, String description, List<String> instructions, Difficulty difficulty,
                       List<String> purposes, Modality modality, List<MeasurementType> measurementTypes,
                       boolean circuit, boolean active, double met, String gifUrl, String previewUrl,
                       List<CatalogItem> bodyParts, List<CatalogItem> targetMuscles,
                       List<CatalogItem> secondaryMuscles, List<CatalogItem> equipment,
                       Instant createdAt, Instant updatedAt, ExerciseCategory category) {

    /** Sin categoría guardada: se deduce de la modalidad. */
    public Exercise(UUID id, String name, String description, List<String> instructions, Difficulty difficulty,
                    List<String> purposes, Modality modality, List<MeasurementType> measurementTypes,
                    boolean circuit, boolean active, double met, String gifUrl, String previewUrl,
                    List<CatalogItem> bodyParts, List<CatalogItem> targetMuscles,
                    List<CatalogItem> secondaryMuscles, List<CatalogItem> equipment,
                    Instant createdAt, Instant updatedAt) {
        this(id, name, description, instructions, difficulty, purposes, modality, measurementTypes, circuit, active,
                met, gifUrl, previewUrl, bodyParts, targetMuscles, secondaryMuscles, equipment, createdAt, updatedAt,
                null);
    }

    public Exercise {
        Objects.requireNonNull(id, "id");
        instructions = List.copyOf(instructions == null ? List.of() : instructions);
        purposes = List.copyOf(purposes == null ? List.of() : purposes);
        measurementTypes = List.copyOf(measurementTypes == null || measurementTypes.isEmpty()
                ? List.of(MeasurementType.REPETITIONS) : measurementTypes);
        bodyParts = List.copyOf(bodyParts == null ? List.of() : bodyParts);
        targetMuscles = List.copyOf(targetMuscles == null ? List.of() : targetMuscles);
        secondaryMuscles = List.copyOf(secondaryMuscles == null ? List.of() : secondaryMuscles);
        equipment = List.copyOf(equipment == null ? List.of() : equipment);
        difficulty = difficulty == null ? Difficulty.INTERMEDIATE : difficulty;
        modality = modality == null ? Modality.STRENGTH : modality;
        category = category == null ? ExerciseCategory.of(modality) : category;
    }

    /** Compuesto: varios músculos secundarios y como mucho dos principales (regla del motor heredado). */
    public boolean isCompound() {
        return secondaryMuscles.size() >= 2 && targetMuscles.size() <= 2;
    }

    public boolean measuredBy(MeasurementType type) {
        return measurementTypes.contains(type);
    }

    /** Isométrico: se mide por tiempo y no por repeticiones. */
    public boolean isIsometric() {
        return measuredBy(MeasurementType.TIME) && !measuredBy(MeasurementType.REPETITIONS);
    }

    public boolean hasPurpose(TrainingGoal goal) {
        return purposes.stream().anyMatch(p -> p.equalsIgnoreCase(goal.label()));
    }

    /** MET efectivo: el del catálogo o, si falta, uno derivado de la modalidad. */
    public double effectiveMet() {
        String legacyModality = switch (modality) {
            case MOBILITY -> "movilidad";
            case METABOLIC -> "metabolica";
            case AEROBIC -> "aerobica";
            case STRENGTH -> "fuerza";
        };
        return ExerciseEnergy.deriveMet(met, legacyModality, circuit);
    }

    public List<String> targetMuscleNames() {
        return targetMuscles.stream().map(CatalogItem::name).toList();
    }

    public List<String> lowerTargetMuscleNames() {
        return targetMuscles.stream().map(m -> m.name().toLowerCase(Locale.ROOT)).toList();
    }

    public List<String> bodyPartNames() {
        return bodyParts.stream().map(CatalogItem::name).toList();
    }

    public List<String> equipmentNames() {
        return equipment.stream().map(CatalogItem::name).toList();
    }

    /** Referencia ligera para incrustar en rutinas y sesiones. */
    public ExerciseRef toRef() {
        return new ExerciseRef(id, name, gifUrl, previewUrl, modality, measurementTypes, circuit, met, active);
    }
}
