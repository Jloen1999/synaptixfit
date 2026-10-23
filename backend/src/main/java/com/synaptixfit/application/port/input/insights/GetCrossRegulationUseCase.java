package com.synaptixfit.application.port.input.insights;

import com.synaptixfit.domain.model.insights.CrossRegulationView;
import java.util.UUID;

/**
 * Estado de regulación cruzada actualizado a hoy (las ventanas de 7 y 28 días se desplazan cada
 * día, así que se recalcula y se guarda en cada lectura).
 */
public interface GetCrossRegulationUseCase {

    /** @param timeZone zona IANA del cliente (null: zona por defecto) */
    CrossRegulationView getCrossRegulation(UUID userId, String timeZone);
}
