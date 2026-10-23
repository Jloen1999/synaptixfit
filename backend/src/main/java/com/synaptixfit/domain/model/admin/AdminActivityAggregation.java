package com.synaptixfit.domain.model.admin;

import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Reglas de agregación del panel de administración (antes en SQL: vista {@code v_admin_metricas},
 * {@code generate_series} y {@code date_trunc}). Los días y las semanas se cuentan en UTC y las
 * semanas empiezan en lunes. La aplican los casos de uso del panel; los adaptadores solo traen filas.
 */
public final class AdminActivityAggregation {

    /** Semanas recientes de carga académica con las que se mide la adherencia. */
    public static final int ADHERENCE_WEEKS = 4;

    private AdminActivityAggregation() {
    }

    /** Algo que hizo un usuario en un instante (sesión de entrenamiento o bloque de estudio completados). */
    public record UserActivity(UUID userId, Instant at) {
    }

    /** Fase Pomodoro de un usuario; {@code day} ya es el día del planificador. */
    public record UserFocus(UUID userId, LocalDate day, int minutes) {
    }

    /** Intervalo de un bloque de estudio completado. */
    public record StudyInterval(Instant start, Instant end) {

        public double minutes() {
            return Math.max(0, Duration.between(start, end).getSeconds()) / 60.0;
        }
    }

    /** Horas de estudio planificadas y reales de una semana registrada. */
    public record StudyWeek(int plannedHours, int actualHours) {
    }

    /**
     * Un punto por día de {@code from} a {@code to} (incluidos los días sin actividad). Un usuario
     * está activo un día si completó una sesión de entrenamiento o un bloque de estudio, o registró
     * una fase Pomodoro.
     */
    public static List<DailyActivityPoint> daily(LocalDate from, LocalDate to, Collection<Instant> signups,
                                                 Collection<UserActivity> trainingSessions,
                                                 Collection<UserActivity> completedBlocks,
                                                 Collection<UserFocus> focus) {
        Map<LocalDate, Long> signupsByDay = new HashMap<>();
        signups.forEach(at -> signupsByDay.merge(utcDay(at), 1L, Long::sum));
        Map<LocalDate, Long> sessionsByDay = new HashMap<>();
        Map<LocalDate, Set<UUID>> activeByDay = new HashMap<>();
        for (UserActivity s : trainingSessions) {
            sessionsByDay.merge(utcDay(s.at()), 1L, Long::sum);
            activeByDay.computeIfAbsent(utcDay(s.at()), k -> new HashSet<>()).add(s.userId());
        }
        completedBlocks.forEach(b -> activeByDay.computeIfAbsent(utcDay(b.at()), k -> new HashSet<>()).add(b.userId()));
        focus.forEach(f -> activeByDay.computeIfAbsent(f.day(), k -> new HashSet<>()).add(f.userId()));

        List<DailyActivityPoint> points = new ArrayList<>();
        for (LocalDate day = from; !day.isAfter(to); day = day.plusDays(1)) {
            points.add(new DailyActivityPoint(day, signupsByDay.getOrDefault(day, 0L),
                    activeByDay.getOrDefault(day, Set.of()).size(), sessionsByDay.getOrDefault(day, 0L)));
        }
        return points;
    }

    /**
     * Un punto por semana de {@code firstWeek} a {@code lastWeek} (lunes): entrenamiento (con el
     * mismo agregado que la analítica), minutos de bloques de estudio (por su inicio) y de Pomodoro.
     * El panel de administración trabaja en UTC (igual que sus métricas diarias).
     */
    public static List<WeeklyActivityPoint> weekly(LocalDate firstWeek, LocalDate lastWeek,
                                                   Collection<CompletedSession> sessions,
                                                   Collection<StudyInterval> studyBlocks,
                                                   Collection<UserFocus> focus) {
        Map<LocalDate, WeeklyTrainingMetric> training = new HashMap<>();
        WeeklyTrainingMetric.byWeek(sessions, java.time.ZoneOffset.UTC).forEach(m -> training.put(m.weekStart(), m));
        Map<LocalDate, Double> study = new HashMap<>();
        studyBlocks.forEach(b -> study.merge(WeeklyTrainingMetric.weekStart(b.start(), java.time.ZoneOffset.UTC), b.minutes(), Double::sum));
        Map<LocalDate, Integer> focusMinutes = new HashMap<>();
        focus.forEach(f -> focusMinutes.merge(f.day().with(DayOfWeek.MONDAY), f.minutes(), Integer::sum));

        List<WeeklyActivityPoint> points = new ArrayList<>();
        for (LocalDate week = firstWeek; !week.isAfter(lastWeek); week = week.plusWeeks(1)) {
            WeeklyTrainingMetric t = training.getOrDefault(week, WeeklyTrainingMetric.empty(week));
            points.add(new WeeklyActivityPoint(week, t.sessions(), t.totalMinutes(), t.totalCalories(), t.averageRpe(),
                    (int) Math.round(study.getOrDefault(week, 0.0)), focusMinutes.getOrDefault(week, 0)));
        }
        return points;
    }

    /** Minutos totales (redondeados) de los bloques de estudio. */
    public static long studyMinutes(Collection<StudyInterval> blocks) {
        return Math.round(blocks.stream().mapToDouble(StudyInterval::minutes).sum());
    }

    /**
     * Adherencia académica: horas reales / planificadas (en %) de las últimas semanas registradas
     * (como mucho {@value #ADHERENCE_WEEKS}); nula si no hay horas planificadas.
     */
    public static Integer adherencePercent(List<StudyWeek> recentWeeks) {
        int planned = recentWeeks.stream().mapToInt(StudyWeek::plannedHours).sum();
        if (planned <= 0) {
            return null;
        }
        int actual = recentWeeks.stream().mapToInt(StudyWeek::actualHours).sum();
        return (int) Math.round(100.0 * actual / planned);
    }

    private static LocalDate utcDay(Instant at) {
        return LocalDate.ofInstant(at, ZoneOffset.UTC);
    }
}
