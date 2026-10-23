package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.Difficulty;
import com.synaptixfit.domain.model.training.Exercise;
import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Reglas comunes para decidir si un ejercicio es apto para un usuario (equipamiento, nivel y
 * biometría). Unifica los dos comparadores de equipamiento que tenía el sistema heredado.
 */
public final class ExerciseEligibility {

    /** Equipamiento que todo usuario tiene. */
    private static final Set<String> ALWAYS_AVAILABLE = Set.of("peso corporal", "sin equipamiento", "suelo",
            "asistencia");

    /** Sinónimos entre los valores del perfil y los nombres del catálogo. */
    private static final Map<String, List<String>> SYNONYMS = Map.of(
            "kettlebell", List.of("pesa rusa"),
            "banda elastica", List.of("banda de resistencia", "banda elastica"),
            "maquina", List.of("maquina"),
            "mancuerna", List.of("mancuernas", "mancuerna"));

    private static final List<String> HIGH_IMPACT_KEYWORDS = List.of("salto", "saltar", "saltos", "saltando",
            "pliometrico", "plyometric", "plyo", "burpee", "box jump", "tuck jump", "broad jump", "depth jump",
            "squat jump");

    private ExerciseEligibility() {
    }

    public static String normalize(String value) {
        String n = Normalizer.normalize(value == null ? "" : value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return n.toLowerCase(Locale.ROOT).replace('_', ' ').strip();
    }

    /** Sin equipamiento, con equipamiento universal o con alguno que tenga el usuario. */
    public static boolean equipmentCompatible(Exercise exercise, List<String> userEquipment) {
        if (exercise.equipment().isEmpty()) {
            return true;
        }
        List<String> user = userEquipment.stream().map(ExerciseEligibility::normalize).toList();
        return exercise.equipmentNames().stream().map(ExerciseEligibility::normalize).anyMatch(req -> {
            if (ALWAYS_AVAILABLE.contains(req)) {
                return true;
            }
            for (String u : user) {
                if (u.isEmpty()) {
                    continue;
                }
                if (req.equals(u) || req.contains(u) || u.contains(req)) {
                    return true;
                }
                if (SYNONYMS.getOrDefault(u, List.of()).stream().anyMatch(req::contains)) {
                    return true;
                }
            }
            return false;
        });
    }

    /** Principiante siempre; intermedio desde nivel ligero; avanzado desde nivel moderado. */
    public static boolean difficultyFits(Difficulty difficulty, ActivityLevel level) {
        return switch (difficulty) {
            case BEGINNER -> true;
            case INTERMEDIATE -> level.rank() >= 1;
            case ADVANCED -> level.rank() >= 2;
        };
    }

    /** Con IMC &gt; 30 se excluyen ejercicios de pierna de alto impacto (saltos, burpees…). */
    public static boolean biometricallySafe(Exercise exercise, TrainingProfile profile) {
        if (profile.bmi() <= 30) {
            return true;
        }
        boolean legs = exercise.bodyPartNames().stream().map(ExerciseEligibility::normalize)
                .anyMatch(p -> p.contains("pierna") || p.contains("tren inferior"));
        if (!legs) {
            return true;
        }
        String name = normalize(exercise.name());
        return HIGH_IMPACT_KEYWORDS.stream().noneMatch(name::contains);
    }

    public static boolean eligible(Exercise exercise, TrainingProfile profile) {
        return exercise.active()
                && difficultyFits(exercise.difficulty(), profile.activityLevel())
                && equipmentCompatible(exercise, profile.equipment())
                && biometricallySafe(exercise, profile);
    }
}
