package com.synaptixfit.domain.model.insights;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Definición única de la actividad cognitiva de un periodo: bloques completados con coste cognitivo
 * más las prácticas sin bloque que cuentan ({@link PracticeSessions}). La misma lista alimenta la carga
 * cognitiva, los minutos y kcal de estudio de hoy y los minutos de estudio de la semana del inicio, para
 * que un Pomodoro no sume en un sitio y no en otro.
 */
public final class StudyActivity {

    private StudyActivity() {
    }

    /** Bloques cognitivos ({@link CompletedStudyBlock#isCognitive}) y prácticas que cuentan. */
    public static List<CompletedStudyBlock> of(Collection<CompletedStudyBlock> completedBlocks,
                                               PracticeSessions.Log practice) {
        List<CompletedStudyBlock> activities = new ArrayList<>();
        completedBlocks.stream().filter(b -> CompletedStudyBlock.isCognitive(b.activityType())).forEach(activities::add);
        activities.addAll(PracticeSessions.countable(practice));
        return activities;
    }

    /** Minutos totales (redondeados) de la actividad. */
    public static int minutes(Collection<CompletedStudyBlock> activities) {
        return (int) Math.round(activities.stream().mapToDouble(CompletedStudyBlock::durationMinutes).sum());
    }
}
