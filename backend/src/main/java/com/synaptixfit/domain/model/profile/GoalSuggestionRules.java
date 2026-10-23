package com.synaptixfit.domain.model.profile;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Recomendación determinista de objetivo principal (respaldo cuando la IA no responde).
 *
 * <p>Regla: el nivel de actividad marca la progresión (sedentario → salud metabólica y movilidad;
 * activo → fuerza e hipertrofia; muy activo → fuerza máxima y potencia). A partir de 50 años se
 * priorizan movilidad y estabilidad y se descarta la potencia.
 */
public final class GoalSuggestionRules {

    public static final int MAX_SUGGESTIONS = 3;

    private GoalSuggestionRules() {
    }

    public static GoalSuggestions suggest(GoalSuggestionContext context) {
        ActivityLevel level = context.activityLevel() == null ? ActivityLevel.SEDENTARY : context.activityLevel();
        Map<TrainingGoal, String> ranked = new LinkedHashMap<>();
        boolean senior = context.age() != null && context.age() >= 50;
        if (senior) {
            ranked.put(TrainingGoal.MOBILITY, "Mantener la amplitud de movimiento protege las articulaciones con la edad.");
            ranked.put(TrainingGoal.STABILITY, "El control motor reduce el riesgo de caídas y lesiones.");
        }
        switch (level) {
            case SEDENTARY -> {
                ranked.putIfAbsent(TrainingGoal.METABOLIC_CONDITIONING,
                        "Mejora la salud cardiovascular y la energía diaria partiendo de poca actividad.");
                ranked.putIfAbsent(TrainingGoal.MOBILITY,
                        "Compensa las horas sentado estudiando y prepara el cuerpo para entrenar.");
                ranked.putIfAbsent(TrainingGoal.STABILITY,
                        "Construye una base técnica segura antes de añadir carga.");
            }
            case LIGHT -> {
                ranked.putIfAbsent(TrainingGoal.STRENGTH_ENDURANCE,
                        "Aumenta la capacidad de trabajo sin exigir cargas altas.");
                ranked.putIfAbsent(TrainingGoal.METABOLIC_CONDITIONING,
                        "Mejora la condición física general con sesiones cortas.");
                ranked.putIfAbsent(TrainingGoal.MOBILITY,
                        "Complementa la actividad ligera y previene molestias posturales.");
            }
            case MODERATE -> {
                ranked.putIfAbsent(TrainingGoal.HYPERTROPHY,
                        "Con una base activa, el trabajo de volumen permite ganar masa muscular.");
                ranked.putIfAbsent(TrainingGoal.STRENGTH_ENDURANCE,
                        "Consolida la resistencia muscular que ya tienes.");
                ranked.putIfAbsent(TrainingGoal.METABOLIC_CONDITIONING,
                        "Mantiene la salud cardiovascular junto al trabajo de fuerza.");
            }
            case HIGH -> {
                ranked.putIfAbsent(TrainingGoal.MAX_STRENGTH,
                        "Tu nivel de actividad permite progresar hacia cargas altas.");
                ranked.putIfAbsent(TrainingGoal.HYPERTROPHY,
                        "El volumen de entrenamiento favorece el desarrollo muscular.");
                if (!senior) {
                    ranked.putIfAbsent(TrainingGoal.POWER,
                            "Puedes trabajar la explosividad con seguridad sobre una buena base.");
                }
            }
        }
        List<GoalSuggestion> suggestions = new ArrayList<>();
        ranked.forEach((goal, reason) -> {
            if (suggestions.size() < MAX_SUGGESTIONS) {
                suggestions.add(new GoalSuggestion(goal, reason));
            }
        });
        return new GoalSuggestions(GoalSuggestionSource.RULES, suggestions);
    }
}
