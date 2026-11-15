package com.synaptixfit.domain.model.badge;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;

/**
 * Estado de la racha diaria del usuario (días con una sesión de entrenamiento, un check-in o un Pomodoro).
 *
 * @param currentDays         días consecutivos actuales
 * @param bestDays            récord histórico
 * @param activeToday         hoy ya hay actividad
 * @param atRisk              quedan menos de {@value #RISK_HOURS} h del día sin actividad y hay racha que perder
 * @param nextMilestone       próximo hito (7, 30, 100, 365) o {@code null} si ya se superaron todos
 * @param daysToNextMilestone días que faltan para el próximo hito
 * @param milestoneProgress   progreso (0-1) desde el hito anterior hasta el próximo
 * @param reachedMilestones   hitos alcanzados por la racha actual
 * @param freezesAvailable    comodines guardados ({@link StreakFreezes})
 * @param frozenDays          días de la racha actual salvados con un comodín
 * @param pause               pausa en curso ({@link StreakPause}) o {@code null}
 * @param pauseDaysLeft       días que duraría una pausa que empiece hoy (0 si no quedan o ya hay una)
 * @param canPause            se ofrece «Pausar racha»: hay racha que proteger, no hay pausa y quedan días
 */
public record StreakStatus(int currentDays, int bestDays, boolean activeToday, boolean atRisk, Integer nextMilestone,
                           int daysToNextMilestone, double milestoneProgress, List<Integer> reachedMilestones,
                           int freezesAvailable, List<LocalDate> frozenDays, StreakPause pause, int pauseDaysLeft,
                           boolean canPause) {

    public static final List<Integer> MILESTONES = List.of(7, 30, 100, 365);
    public static final int RISK_HOURS = 4;

    /** Calcula la racha a partir de los días con actividad y la hora local del usuario. */
    public static StreakStatus compute(Set<LocalDate> activeDays, LocalDateTime now) {
        return compute(activeDays, List.of(), now);
    }

    /** Igual, teniendo en cuenta las pausas de racha del usuario. */
    public static StreakStatus compute(Set<LocalDate> activeDays, List<StreakPause> pauses, LocalDateTime now) {
        LocalDate today = now.toLocalDate();
        StreakPause pause = StreakPause.active(pauses, today).orElse(null);
        StreakFreezes.Run run = StreakFreezes.run(activeDays, StreakPause.pausedDays(pauses, today), today);
        int current = run.currentDays();
        int best = Math.max(current, ActivityDays.longestRun(activeDays));
        boolean activeToday = activeDays.contains(today);
        boolean lateInDay = !now.toLocalTime().isBefore(LocalTime.MIDNIGHT.minusHours(RISK_HOURS));
        // Con un comodín guardado o la racha en pausa, un día sin actividad no la rompe: no está en riesgo.
        boolean atRisk = !activeToday && current > 0 && lateInDay && run.available() == 0 && pause == null;

        Integer next = null;
        int previous = 0;
        for (int milestone : MILESTONES) {
            if (current < milestone) {
                next = milestone;
                break;
            }
            previous = milestone;
        }
        int daysToNext = next == null ? 0 : next - current;
        double progress = next == null ? 1.0 : Math.min(1.0, Math.max(0.0,
                (double) (current - previous) / (next - previous)));
        List<Integer> reached = MILESTONES.stream().filter(m -> current >= m).toList();
        int pauseDaysLeft = StreakPause.daysLeft(pauses, today);
        return new StreakStatus(current, best, activeToday, atRisk, next, daysToNext, progress, reached,
                run.available(), run.frozenDays(), pause, pauseDaysLeft,
                pause == null && current > 0 && pauseDaysLeft > 0);
    }
}
