package com.synaptixfit.domain.port.output.admin;

import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserActivity;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserFocus;
import com.synaptixfit.domain.model.admin.PlatformCounts;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Lecturas de toda la plataforma para el panel. Devuelve recuentos simples y filas sin agrupar: qué es
 * un usuario activo y cómo se agrupa por día lo decide {@code AdminActivityAggregation} en el caso de uso.
 */
public interface PlatformMetricsQueryPort {

    /** Recuentos en el instante {@code now} (un reto activo no está completado y no ha vencido). */
    PlatformCounts counts(Instant now);

    /** Instantes de alta de los usuarios registrados en [from, to). */
    List<Instant> signups(Instant from, Instant to);

    /** Sesiones de entrenamiento completadas en [from, to). */
    List<UserActivity> completedTrainingSessions(Instant from, Instant to);

    /** Bloques del calendario completados que empiezan en [from, to). */
    List<UserActivity> completedBlocks(Instant from, Instant to);

    /** Fases Pomodoro registradas de {@code from} a {@code to} (días del planificador, inclusive). */
    List<UserFocus> focusSessions(LocalDate from, LocalDate to);
}
