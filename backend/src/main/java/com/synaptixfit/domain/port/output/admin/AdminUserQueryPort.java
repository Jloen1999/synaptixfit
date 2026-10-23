package com.synaptixfit.domain.port.output.admin;

import com.synaptixfit.domain.model.admin.AcademicProfileSnapshot;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyInterval;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyWeek;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserFocus;
import com.synaptixfit.domain.model.admin.AdminUserCounts;
import com.synaptixfit.domain.model.admin.AdminUserSummary;
import com.synaptixfit.domain.model.admin.TimelineEntry;
import com.synaptixfit.domain.model.admin.UserSearchCriteria;
import com.synaptixfit.domain.model.admin.WellbeingProfileSnapshot;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Lecturas sobre usuarios y su actividad (tablas de varios módulos) para el panel. Solo filas y
 * recuentos: las series semanales, la adherencia y los minutos de estudio los calcula
 * {@code AdminActivityAggregation} en el caso de uso.
 */
public interface AdminUserQueryPort {

    PageResult<AdminUserSummary> search(UserSearchCriteria criteria, PageRequest page);

    Optional<WellbeingProfileSnapshot> findWellbeingProfile(UUID userId);

    Optional<AcademicProfileSnapshot> findAcademicProfile(UUID userId);

    /** Recuentos y sumas simples de la actividad del usuario. */
    AdminUserCounts counts(UUID userId);

    /** Carga académica de las últimas {@code weeks} semanas registradas, de la más reciente a la más antigua. */
    List<StudyWeek> recentStudyWeeks(UUID userId, int weeks);

    /**
     * Bloques de estudio ({@code ActivityType.countsAsStudy}) completados que empiezan en [from, to);
     * con {@code from} y {@code to} nulos, todo el historial.
     */
    List<StudyInterval> completedStudyIntervals(UUID userId, Instant from, Instant to);

    /** Sesiones de entrenamiento completadas en [from, to). */
    List<CompletedSession> completedTrainingSessions(UUID userId, Instant from, Instant to);

    /** Fases Pomodoro de concentración completadas con día en [from, to). */
    List<UserFocus> completedFocus(UUID userId, LocalDate from, LocalDate to);

    /** Eventos de actividad del usuario de varias tablas, del más reciente al más antiguo. */
    PageResult<TimelineEntry> timeline(UUID userId, PageRequest page);

    /** Administradores con la cuenta activa. */
    long countActiveAdmins();
}
