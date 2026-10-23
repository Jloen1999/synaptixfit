package com.synaptixfit.domain.model.insights;

import java.time.LocalDate;
import java.util.List;

/**
 * Carga física de hoy frente a la máxima diaria histórica (denominador de la fórmula 4,
 * SM-2-Physio) y serie diaria de los últimos 28 días (con ceros en los días sin entrenar).
 */
public record PhysicalLoadSummary(LocalDate date, double todayLoad, double maxDailyLoad, double todayRatio,
                                  List<DailyLoad> last28Days) {

    public PhysicalLoadSummary {
        last28Days = List.copyOf(last28Days);
    }
}
