package com.synaptixfit.domain.port.output.analytics;

import com.synaptixfit.domain.model.analytics.StudyBySubject;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Datos en bruto para la analítica de estudio por asignatura (solo trae filas; agrega el dominio). */
public interface StudyBySubjectSourcePort {

    /** Asignaturas no archivadas: id → nombre. */
    Map<UUID, String> activeSubjects(UUID userId);

    /** Bloques de estudio y de repaso completados que empiezan en [from, to). */
    List<StudyBySubject.StudyBlock> completedStudyBlocks(UUID userId, Instant from, Instant to);

    /** Repasos hechos en [from, to) con la asignatura de su material. */
    List<StudyBySubject.Review> reviews(UUID userId, Instant from, Instant to);
}
