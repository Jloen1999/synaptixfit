package com.synaptixfit.domain.model.training;

import java.util.Arrays;
import java.util.Locale;
import java.util.Optional;

/**
 * Objetivo de entrenamiento. Son los siete valores estándar del sistema; la etiqueta en español es
 * la que usan el catálogo de ejercicios ({@code finalidad}) y el perfil de bienestar.
 */
public enum TrainingGoal {
    HYPERTROPHY("Hipertrofia Muscular"),
    MAX_STRENGTH("Fuerza Máxima"),
    POWER("Potencia y Explosividad"),
    STRENGTH_ENDURANCE("Fuerza Resistencia"),
    MOBILITY("Movilidad y Flexibilidad"),
    STABILITY("Estabilidad y Control Motor"),
    METABOLIC_CONDITIONING("Acondicionamiento Metabólico");

    private final String label;

    TrainingGoal(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }

    /** Traduce una etiqueta (sin distinguir mayúsculas) al objetivo; vacío si no es estándar. */
    public static Optional<TrainingGoal> fromLabel(String value) {
        if (value == null) {
            return Optional.empty();
        }
        String v = value.strip().toLowerCase(Locale.ROOT);
        return Arrays.stream(values()).filter(g -> g.label.toLowerCase(Locale.ROOT).equals(v)).findFirst();
    }

    /** Igual que {@link #fromLabel} pero con hipertrofia como valor por defecto (regla heredada). */
    public static TrainingGoal fromLabelOrDefault(String value) {
        return fromLabel(value).orElse(HYPERTROPHY);
    }
}
