package com.synaptixfit.domain.model.insights;

import java.time.LocalDate;

/**
 * Estado actual de bienestar: energía (requiere check-in), adherencia académica y FCT (requieren
 * carga académica registrada esta semana). Los componentes sin datos son null: el cliente no debe
 * interpretarlos como "bajos".
 */
public record WellbeingSnapshot(LocalDate date, boolean checkInDone, DailyCheckIn checkIn, EnergyScore energy,
                                AcademicAdherence adherence, TotalLoadFactor totalLoad,
                                WeeklyAcademicLoad weeklyLoad) {
}
