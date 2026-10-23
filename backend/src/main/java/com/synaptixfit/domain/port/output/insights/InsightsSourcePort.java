package com.synaptixfit.domain.port.output.insights;

import com.synaptixfit.domain.model.insights.BodyProfile;
import com.synaptixfit.domain.model.insights.CompletedStudyBlock;
import com.synaptixfit.domain.model.insights.DailyCheckIn;
import com.synaptixfit.domain.model.insights.PracticeSessions;
import com.synaptixfit.domain.model.insights.WeeklyAcademicLoad;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Lecturas de datos de otros módulos (perfil, planificador, entrenamiento) que necesitan los
 * indicadores. Solo lectura: el módulo nunca escribe en esas tablas.
 */
public interface InsightsSourcePort {

    /** Fecha límite del examen pendiente más próximo a partir de {@code from}. */
    Optional<Instant> nextPendingExam(UUID userId, Instant from);

    /**
     * Bloques completados con coste cognitivo ({@code ActivityType.isCognitive}: estudio, clase,
     * repaso, examen, entrega) que empiezan en [from, to).
     */
    List<CompletedStudyBlock> completedStudyBlocks(UUID userId, Instant from, Instant to);

    /**
     * Práctica académica sin bloque terminada en [from, to), sin filtrar: fases Pomodoro completadas
     * (con si su bloque acabó completado), tests de práctica, repasos SM-2 y los materiales con un
     * bloque de repaso completado en el periodo. Qué cuenta lo decide {@link PracticeSessions#countable}.
     */
    PracticeSessions.Log practiceLog(UUID userId, Instant from, Instant to);

    Optional<BodyProfile> bodyProfile(UUID userId);

    Optional<WeeklyAcademicLoad> weeklyAcademicLoad(UUID userId, LocalDate weekStart);

    Optional<DailyCheckIn> checkIn(UUID userId, LocalDate date);

    /** Check-ins entre dos fechas (incluidas), del más reciente al más antiguo. */
    List<DailyCheckIn> checkIns(UUID userId, LocalDate from, LocalDate to);

    /** Entregas y exámenes con fecha límite en [from, to). */
    DeadlineCounts deadlineCounts(UUID userId, Instant from, Instant to);

    /** Número total y completadas. */
    record DeadlineCounts(int total, int completed) {
    }
}
