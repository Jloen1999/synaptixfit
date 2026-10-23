package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.TrainingGoal;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/** Nombre y descripción de las rutinas generadas. */
public final class RoutineNaming {

    private static final Pattern WEEKS = Pattern.compile("\\d+\\s*semanas?", Pattern.CASE_INSENSITIVE);

    private RoutineNaming() {
    }

    public static String weeksLabel(int weeks) {
        return weeks == 1 ? "1 semana" : weeks + " semanas";
    }

    public static String baseName(TrainingGoal goal, String split, int weeks) {
        return fit(goal.label() + " · " + split + " · " + weeksLabel(weeks));
    }

    public static String baseDescription(TrainingGoal goal, String split, int daysPerWeek, List<String> equipment,
                                         List<String> reasons) {
        StringBuilder sb = new StringBuilder("Rutina de ").append(goal.label().toLowerCase(Locale.ROOT))
                .append(" con split ").append(split).append(" para ").append(daysPerWeek)
                .append(daysPerWeek == 1 ? " día por semana." : " días por semana.");
        if (equipment != null && !equipment.isEmpty()) {
            sb.append(" Equipamiento: ").append(String.join(", ", equipment.stream().limit(3).toList())).append('.');
        }
        if (reasons != null && !reasons.isEmpty()) {
            sb.append(" Adaptada: ").append(String.join(" | ", reasons)).append('.');
        }
        return sb.toString();
    }

    /**
     * Corrige el nombre propuesto por la IA: cualquier mención de semanas («4 semanas») se sustituye
     * por la duración real y se ajusta a la longitud permitida (3-120).
     */
    public static String sanitize(String name, int weeks, String fallback) {
        if (name == null || name.isBlank()) {
            return fallback;
        }
        String fixed = WEEKS.matcher(name.strip()).replaceAll(weeksLabel(weeks));
        fixed = fit(fixed);
        return fixed.length() < 3 ? fallback : fixed;
    }

    private static String fit(String value) {
        return value.length() > 120 ? value.substring(0, 120).strip() : value;
    }
}
