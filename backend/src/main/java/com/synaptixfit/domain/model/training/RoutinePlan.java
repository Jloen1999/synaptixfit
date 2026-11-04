package com.synaptixfit.domain.model.training;

import java.time.LocalDate;
import java.util.List;

/**
 * Vista del plan de una rutina por fases (ADR 0032): en qué semana va («Semana 2 de 8»), cuánto lleva hecho,
 * las fechas de cada semana y qué conviene hacer al terminarla.
 *
 * <p>Reglas: la semana actual es la del primer día con ejercicios que sigue sin hacer ni saltar (el mismo que
 * propone {@code RoutineSchedule}); si no queda ninguno, la última. El avance cuenta los días hechos o
 * saltados, como el ciclo. Las fechas solo existen si la rutina tiene fecha de inicio: la semana N empieza
 * {@code 7·(N−1)} días después. Al terminar, un plan corto (menos de {@link #NEW_PLAN_FROM_WEEKS} semanas) se
 * repite subiendo un poco el peso; uno largo pide cambiar de plan, porque repetir lo mismo tanto tiempo deja
 * de hacer progresar.
 */
public record RoutinePlan(int currentWeek, int totalWeeks, int percentDone, NextStep nextStep,
                          List<WeekDates> weeks) {

    /** A partir de cuántas semanas se propone cambiar de plan en lugar de repetirlo. */
    public static final int NEW_PLAN_FROM_WEEKS = 8;

    /** Qué conviene hacer al terminar la rutina. */
    public enum NextStep {
        /** Repetir el ciclo subiendo un poco el peso. */
        REPEAT_STRONGER,
        /** Empezar otro plan (otra plantilla o uno nuevo con IA). */
        NEW_PLAN
    }

    /** Fechas de una semana; nulas si la rutina no tiene fecha de inicio. */
    public record WeekDates(int number, LocalDate startsOn, LocalDate endsOn) {
    }

    public RoutinePlan {
        weeks = List.copyOf(weeks);
    }

    public static RoutinePlan of(Routine routine) {
        int total = routine.weeks().size();
        int current = total == 0 ? 1 : routine.weeks().getLast().number();
        outer:
        for (RoutineWeek week : routine.weeks()) {
            for (RoutineDay day : week.trainableDays()) {
                if (!day.status().isClosed()) {
                    current = week.number();
                    break outer;
                }
            }
        }
        int days = routine.totalDays();
        int percent = days == 0 ? 0
                : (int) Math.round(100.0 * (routine.completedDays() + routine.skippedDays()) / days);
        LocalDate start = routine.startDate();
        List<WeekDates> dates = routine.weeks().stream()
                .map(w -> start == null ? new WeekDates(w.number(), null, null)
                        : new WeekDates(w.number(), start.plusDays(7L * (w.number() - 1)),
                        start.plusDays(7L * (w.number() - 1) + 6)))
                .toList();
        NextStep next = total >= NEW_PLAN_FROM_WEEKS ? NextStep.NEW_PLAN : NextStep.REPEAT_STRONGER;
        return new RoutinePlan(current, total, Math.min(100, percent), next, dates);
    }

    public WeekDates datesOf(int weekNumber) {
        return weeks.stream().filter(w -> w.number() == weekNumber).findFirst()
                .orElse(new WeekDates(weekNumber, null, null));
    }
}
