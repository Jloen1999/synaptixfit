package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.ScheduleScan;
import java.util.List;

/**
 * Extrae con IA el patrón semanal de clases de un horario (PDF o imagen), limitado a las asignaturas
 * indicadas y al semestre en curso ({@code semester}: 1 o 2). Nunca devuelve fechas absolutas. Lanza
 * AiUnavailableException si la respuesta no es válida.
 */
public interface ScheduleScannerPort {

    ScheduleScan extractWeeklyPattern(byte[] content, String mimeType, List<String> subjectNames, int semester);
}
