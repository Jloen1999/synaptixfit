package com.synaptixfit.application.port.input.planner;

import java.util.List;
import java.util.UUID;

/**
 * Escanea con IA un horario (PDF o imagen, máx. 10 MB), extrae el patrón semanal de las asignaturas
 * activas del usuario y lo materializa entre las fechas de inicio y fin de clases del perfil académico
 * como bloques {@code clase} inamovibles. Idempotente: re-escanear actualiza.
 */
public interface ScanScheduleUseCase {

    long MAX_BYTES = 10L * 1024 * 1024;

    record Command(UUID userId, byte[] content, String mimeType) {
    }

    /**
     * @param classesFound      clases del patrón semanal devueltas por la IA
     * @param unmatchedSubjects asignaturas del documento que no se pudieron vincular
     */
    record Result(int classesFound, int blocksCreated, int blocksUpdated, List<String> unmatchedSubjects) {
    }

    Result scan(Command command);
}
