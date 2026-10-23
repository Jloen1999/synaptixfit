package com.synaptixfit.domain.model.insights;

import com.synaptixfit.domain.model.neuro.StudyEnergy;
import java.time.LocalDate;
import java.util.List;

/** Gasto calórico y minutos de la actividad cognitiva de un día: bloques y prácticas (fórmula 1). */
public record StudyCaloriesSummary(LocalDate date, double totalCalories, int completedBlocks, int studyMinutes) {

    /**
     * Suma las kcal de los bloques cognitivos. Si el planificador ya guardó las kcal del bloque se
     * respetan; si no, se calculan con el RMR del perfil (0 si no hay perfil).
     */
    public static StudyCaloriesSummary of(LocalDate date, List<CompletedStudyBlock> blocks, Double rmr) {
        double total = 0;
        double minutes = 0;
        int count = 0;
        for (CompletedStudyBlock b : blocks) {
            if (!CompletedStudyBlock.isCognitive(b.activityType())) {
                continue;
            }
            count++;
            minutes += b.durationMinutes();
            if (b.storedCalories() != null) {
                total += b.storedCalories();
            } else if (rmr != null) {
                total += StudyEnergy.blockCalories(rmr, b.durationSeconds(), StudyEnergy.cognitiveMet(b.activityType()));
            }
        }
        return new StudyCaloriesSummary(date, total, count, (int) Math.round(minutes));
    }
}
