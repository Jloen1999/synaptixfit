package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import java.util.List;
import java.util.UUID;

/**
 * Lectura de la carga física (módulo Indicadores) para el ajuste por fatiga del SM-2. Solo devuelve
 * las filas: la carga de hoy y el máximo diario los calcula {@link PhysicalLoadHistory} en el caso de uso.
 */
public interface PhysicalLoadPort {

    /** Historial de carga del usuario (fecha, RPE y minutos de cada registro). */
    List<PhysicalLoadHistory.Entry> history(UUID userId);
}
