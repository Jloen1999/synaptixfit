package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.neuro.ExerciseEnergy;
import java.util.List;
import java.util.UUID;

/** Datos mínimos de un ejercicio que acompañan a un ejercicio planificado. */
public record ExerciseRef(UUID id, String name, String gifUrl, String previewUrl, Modality modality,
                          List<MeasurementType> measurementTypes, boolean circuit, double met, boolean active) {

    public ExerciseRef {
        measurementTypes = List.copyOf(measurementTypes == null ? List.of() : measurementTypes);
        modality = modality == null ? Modality.STRENGTH : modality;
    }

    /** Referencia a un ejercicio desconocido (borrado o sin cargar). */
    public static ExerciseRef unknown(UUID id) {
        return new ExerciseRef(id, null, null, null, Modality.STRENGTH, List.of(MeasurementType.REPETITIONS),
                false, 6.0, false);
    }

    public boolean measuredBy(MeasurementType type) {
        return measurementTypes.contains(type);
    }

    public double effectiveMet() {
        String legacyModality = switch (modality) {
            case MOBILITY -> "movilidad";
            case METABOLIC -> "metabolica";
            case AEROBIC -> "aerobica";
            case STRENGTH -> "fuerza";
        };
        return ExerciseEnergy.deriveMet(met, legacyModality, circuit);
    }
}
