package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.ScheduleEntry;
import java.util.List;

/**
 * Extrae con IA el patrón semanal de clases de un horario (PDF o imagen), limitado a las asignaturas
 * indicadas. Nunca devuelve fechas absolutas. Lanza AiUnavailableException si la respuesta no es válida.
 */
public interface ScheduleScannerPort {

    List<ScheduleEntry> extractWeeklyPattern(byte[] content, String mimeType, List<String> subjectNames);
}
