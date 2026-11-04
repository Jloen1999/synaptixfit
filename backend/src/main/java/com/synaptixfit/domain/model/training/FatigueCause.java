package com.synaptixfit.domain.model.training;

/**
 * Lo que más pesa en la fatiga del registro diario ({@link DailyCheckIn#mainCause()}). Sirve para explicar en
 * sencillo por qué se adapta el entreno («porque dormiste mal»).
 */
public enum FatigueCause {
    POOR_SLEEP,
    STRESS,
    LOW_ENERGY,
    SORENESS
}
