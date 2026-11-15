package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.TemplatePlace;
import com.synaptixfit.domain.model.training.TrainingGoal;
import java.util.List;
import java.util.UUID;

/** DTOs de las plantillas de rutina (ADR 0032 y 0043). */
public final class RoutineTemplateDtos {

    private RoutineTemplateDtos() {
    }

    /**
     * Plantilla resumida: días por semana (con los de carrera), objetivo, lugar, nivel, si es para semanas de
     * exámenes y ejercicios. {@code dayNumbers} son los días de gimnasio o casa; {@code runDays}, los de salir a
     * correr con su entreno de carrera. {@code atHome} se mantiene para las apps anteriores.
     */
    public record RoutineTemplateResponse(UUID id, String code, String name, String description, TrainingGoal goal,
                                          boolean atHome, TemplatePlace place, TemplateLevel level, boolean forExams,
                                          int minutes, int weeks, int daysPerWeek, List<Integer> dayNumbers,
                                          List<RunDayResponse> runDays, int exerciseCount) {
        public static RoutineTemplateResponse from(RoutineTemplate t) {
            return new RoutineTemplateResponse(t.id(), t.code(), t.name(), t.description(), t.goal(), t.atHome(),
                    t.place(), t.level(), t.forExams(), t.minutes(), t.weeks(), t.daysPerWeek(),
                    t.days().stream().map(RoutineTemplate.Day::dayNumber).toList(),
                    t.runDays().stream().map(d -> new RunDayResponse(d.dayNumber(), d.workoutCode())).toList(),
                    t.days().stream().mapToInt(d -> d.exercises().size()).sum());
        }
    }

    /** Día de salir a correr con el entreno de carrera {@code workoutCode} (se crea en Entreno › Correr). */
    public record RunDayResponse(int dayNumber, String workoutCode) {
    }
}
