package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.training.generation.ActivityLevel;

/** Para quién es una plantilla de rutina (ADR 0043): quien empieza o quien ya entrena con constancia. */
public enum TemplateLevel {
    BEGINNER, INTERMEDIATE;

    /**
     * Nivel para el peso de partida de una rutina generada (ADR 0054): quien declara una actividad moderada o alta
     * cuenta como quien ya entrena (sin historial, lo ajusta la calibración).
     */
    public static TemplateLevel forActivity(ActivityLevel activity) {
        return activity != null && activity.rank() >= 2 ? INTERMEDIATE : BEGINNER;
    }
}
