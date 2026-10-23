package com.synaptixfit.domain.model.profile;

import java.text.Normalizer;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * Objetivo principal de entrenamiento. Son las siete finalidades estándar que usa el motor de
 * recomendación de rutinas; {@link #label()} es el texto canónico que se guarda en la base de datos.
 */
public enum TrainingGoal {
    HYPERTROPHY("Hipertrofia Muscular"),
    MAX_STRENGTH("Fuerza Máxima"),
    POWER("Potencia y Explosividad"),
    STRENGTH_ENDURANCE("Fuerza Resistencia"),
    MOBILITY("Movilidad y Flexibilidad"),
    STABILITY("Estabilidad y Control Motor"),
    METABOLIC_CONDITIONING("Acondicionamiento Metabólico");

    /** Valores libres heredados del sistema antiguo y su finalidad estándar equivalente. */
    private static final Map<String, TrainingGoal> LEGACY = Map.ofEntries(
            Map.entry("hipertrofia", HYPERTROPHY),
            Map.entry("fuerza", MAX_STRENGTH),
            Map.entry("ganar_masa", HYPERTROPHY),
            Map.entry("perder_peso", METABOLIC_CONDITIONING),
            Map.entry("resistencia", STRENGTH_ENDURANCE),
            Map.entry("movilidad", MOBILITY),
            Map.entry("fitness_general", STABILITY),
            Map.entry("mixto", HYPERTROPHY),
            Map.entry("cardio", METABOLIC_CONDITIONING),
            Map.entry("flexibilidad", MOBILITY));

    private final String label;

    TrainingGoal(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }

    /** Busca por texto canónico (sin distinguir mayúsculas ni tildes) o por un valor heredado. */
    public static Optional<TrainingGoal> fromLabel(String text) {
        if (text == null || text.isBlank()) {
            return Optional.empty();
        }
        String key = normalize(text);
        for (TrainingGoal goal : values()) {
            if (normalize(goal.label).equals(key) || goal.name().equalsIgnoreCase(text.strip())) {
                return Optional.of(goal);
            }
        }
        return Optional.ofNullable(LEGACY.get(key));
    }

    private static String normalize(String text) {
        String noAccents = Normalizer.normalize(text.strip(), Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        return noAccents.toLowerCase(Locale.ROOT);
    }
}
