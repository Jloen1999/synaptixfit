package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.TemplatePlace;
import com.synaptixfit.domain.model.training.TrainingGoal;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;

/** DTOs de las plantillas de rutina (ADR 0032, 0043 y 0054). */
public final class RoutineTemplateDtos {

    private RoutineTemplateDtos() {
    }

    /**
     * Plantilla resumida: días por semana (con los de carrera), objetivo, lugar, nivel, si es para semanas de
     * exámenes y ejercicios. {@code dayNumbers} son los días de gimnasio o casa; {@code runDays}, los de salir a
     * correr con su entreno de carrera (uno por día de la semana: el de la primera semana si el plan cambia cada
     * semana). {@code dayNames}: nombre de la sesión de cada día de {@code dayNumbers}, en el mismo orden (nulo si no
     * tiene). {@code atHome} se mantiene para las apps anteriores.
     */
    public record RoutineTemplateResponse(UUID id, String code, String name, String description, TrainingGoal goal,
                                          boolean atHome, TemplatePlace place, TemplateLevel level, boolean forExams,
                                          int minutes, int weeks, int daysPerWeek, List<Integer> dayNumbers,
                                          List<RunDayResponse> runDays, int exerciseCount, List<String> dayNames) {
        public static RoutineTemplateResponse from(RoutineTemplate t) {
            return new RoutineTemplateResponse(t.id(), t.code(), t.name(), t.description(), t.goal(), t.atHome(),
                    t.place(), t.level(), t.forExams(), t.minutes(), t.weeks(), t.daysPerWeek(),
                    t.days().stream().map(RoutineTemplate.Day::dayNumber).toList(),
                    firstWeekRuns(t), t.days().stream().mapToInt(d -> d.exercises().size()).sum(),
                    t.days().stream().map(RoutineTemplate.Day::name).toList());
        }

        private static List<RunDayResponse> firstWeekRuns(RoutineTemplate t) {
            Map<Integer, RunDayResponse> byDay = new TreeMap<>();
            t.runDays().stream()
                    .sorted(Comparator.comparingInt(RoutineTemplate.RunDay::week))
                    .forEach(d -> byDay.putIfAbsent(d.dayNumber(), new RunDayResponse(d.dayNumber(), d.workoutCode())));
            return List.copyOf(byDay.values());
        }
    }

    /** Día de salir a correr con el entreno de carrera {@code workoutCode} (se crea en Entreno › Correr). */
    public record RunDayResponse(int dayNumber, String workoutCode) {
    }
}
