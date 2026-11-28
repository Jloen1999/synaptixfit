package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.RoutineTemplateDetail;
import com.synaptixfit.domain.model.training.WeekType;
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
     * tiene). {@code atHome} se mantiene para las apps anteriores. {@code coverImageUrl}: foto de uno de sus
     * ejercicios para el fondo de la tarjeta (nula si ninguno tiene).
     */
    public record RoutineTemplateResponse(UUID id, String code, String name, String description, TrainingGoal goal,
                                          boolean atHome, TemplatePlace place, TemplateLevel level, boolean forExams,
                                          int minutes, int weeks, int daysPerWeek, List<Integer> dayNumbers,
                                          List<RunDayResponse> runDays, int exerciseCount, List<String> dayNames,
                                          String coverImageUrl) {
        public static RoutineTemplateResponse from(RoutineTemplate t) {
            return new RoutineTemplateResponse(t.id(), t.code(), t.name(), t.description(), t.goal(), t.atHome(),
                    t.place(), t.level(), t.forExams(), t.minutes(), t.weeks(), t.daysPerWeek(),
                    t.days().stream().map(RoutineTemplate.Day::dayNumber).toList(),
                    firstWeekRuns(t), t.days().stream().mapToInt(d -> d.exercises().size()).sum(),
                    t.days().stream().map(RoutineTemplate.Day::name).toList(), t.coverImageUrl());
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

    /**
     * Detalle de una plantilla: los datos de la tarjeta ({@code summary}), cada día con sus ejercicios y los días de
     * carrera con el nombre de su entreno.
     */
    public record RoutineTemplateDetailResponse(RoutineTemplateResponse summary, List<TemplateDayResponse> days,
                                                List<TemplateRunDayResponse> runDays) {
        public static RoutineTemplateDetailResponse from(RoutineTemplateDetail detail) {
            RoutineTemplate t = detail.template();
            List<TemplateDayResponse> days = t.days().stream()
                    .map(d -> new TemplateDayResponse(d.dayNumber(), d.name(), d.exercises().stream()
                            .map(e -> TemplateExerciseResponse.from(e, detail.exercises().get(e.exerciseId())))
                            .toList()))
                    .toList();
            Map<Integer, TemplateRunDayResponse> runs = new TreeMap<>();
            t.runDays().stream()
                    .sorted(Comparator.comparingInt(RoutineTemplate.RunDay::week))
                    .forEach(d -> runs.putIfAbsent(d.dayNumber(),
                            new TemplateRunDayResponse(d.dayNumber(), d.workoutCode(), d.workoutName())));
            return new RoutineTemplateDetailResponse(RoutineTemplateResponse.from(t), days, List.copyOf(runs.values()));
        }
    }

    /** Día de la plantilla (1 = lunes) con el nombre de la sesión (nulo si no tiene) y sus ejercicios en orden. */
    public record TemplateDayResponse(int dayNumber, String name, List<TemplateExerciseResponse> exercises) {
    }

    /**
     * Ejercicio en una semana de carga (las suaves hacen una serie menos): series, repeticiones (las de partida, el mínimo del rango si lo hay), rango y
     * cuántas deben sobrar, segundos aguantando (planchas) y descanso. {@code name} e {@code imageUrl} son nulos si
     * el ejercicio ya no está en el catálogo.
     */
    public record TemplateExerciseResponse(UUID exerciseId, String name, String imageUrl, int sets, int reps,
                                           Integer repMin, Integer repMax, Integer repsInReserve,
                                           Integer holdSeconds, int restSeconds) {
        static TemplateExerciseResponse from(RoutineTemplate.Item item, RoutineTemplateDetail.ExerciseInfo info) {
            ExerciseParameters p = RoutineTemplate.parametersFor(item, WeekType.LOAD);
            var range = item.repRange();
            return new TemplateExerciseResponse(item.exerciseId(), info == null ? null : info.name(),
                    info == null ? null : info.imageUrl(), p.sets(), p.reps(),
                    range == null ? null : range.min(), range == null ? null : range.max(),
                    range == null ? null : range.reserve(), item.holdSeconds(), p.restSeconds());
        }
    }

    /** Día de salir a correr con su entreno de carrera (el de la primera semana si el plan cambia cada semana). */
    public record TemplateRunDayResponse(int dayNumber, String workoutCode, String workoutName) {
    }
}
