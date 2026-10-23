package com.synaptixfit.domain.model.insights;

import java.time.LocalDate;

/**
 * Check-in diario (lectura de {@code estado_diario_usuario}). Escalas 1-5; los valores ausentes
 * toman los neutros de la app antigua (sueño 3, estrés 3, energía 3, dolor 1).
 */
public record DailyCheckIn(LocalDate date, Integer sleepQuality, Integer stressLevel, Integer energyLevel,
                           Integer muscleSoreness, Boolean readyToTrain) {

    public int sleep() { return sleepQuality == null ? 3 : sleepQuality; }
    public int stress() { return stressLevel == null ? 3 : stressLevel; }
    public int energy() { return energyLevel == null ? 3 : energyLevel; }
    public int soreness() { return muscleSoreness == null ? 1 : muscleSoreness; }
    public boolean ready() { return readyToTrain == null || readyToTrain; }

    /** Puntuación de fatiga 0-100 (sueño 0-25, estrés 0-20, energía 0-20, dolor 0-28). */
    public int fatigueScore() {
        int score = (6 - sleep()) * 5 + (stress() - 1) * 5 + (6 - energy()) * 4 + (soreness() - 1) * 7;
        return Math.max(0, Math.min(100, score));
    }

    /** Fatiga alta: requiere adaptar la carga (umbral 50 de la app antigua). */
    public boolean highFatigue() {
        return fatigueScore() > 50;
    }
}
