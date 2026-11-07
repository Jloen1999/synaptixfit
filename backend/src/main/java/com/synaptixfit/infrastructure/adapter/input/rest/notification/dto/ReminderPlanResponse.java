package com.synaptixfit.infrastructure.adapter.input.rest.notification.dto;

import com.synaptixfit.domain.model.challenge.TaskMention;
import com.synaptixfit.domain.model.notification.ReminderKind;
import com.synaptixfit.domain.model.notification.ReminderPlan;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Plan de recordatorios locales del móvil, ordenado por hora. El cliente solo pone los textos y descarta los tipos
 * ({@code kind}) que no conoce.
 */
public record ReminderPlanResponse(List<Item> reminders) {

    /**
     * Un aviso.
     *
     * @param refId    id del evento, o día local (ISO) del aviso de repasos y del resumen de la mañana
     * @param count    repasos vencidos ({@code REVIEWS}) o días que faltan ({@code EXAM}, {@code DEADLINE},
     *                 {@code CHALLENGE_TASK})
     * @param title    título o asignatura del evento, o título de la entrega o de la tarea de reto
     * @param startsAt inicio del evento, fecha de la entrega o de la tarea
     * @param targetId lo que se abre al tocar el aviso si no es {@code refId} (entrega o reto)
     * @param place    aula de la clase (solo {@code CLASS_SOON}; nula si no se sabe)
     * @param tasks    tareas de reto que menciona el aviso (ADR 0035)
     * @param summary  contenido del resumen de la mañana (solo {@code MORNING_SUMMARY})
     */
    @Schema(name = "ReminderPlanItem")
    public record Item(ReminderKind kind, Instant at, String refId, Integer count, String title, Instant startsAt,
                       String targetId, String place, List<Task> tasks, Summary summary) {
    }

    /** Tarea de reto mencionada; {@code title} nulo: el propio reto (sin tareas, va con su entrega). */
    @Schema(name = "ReminderPlanTask")
    public record Task(UUID challengeId, String challengeTitle, UUID milestoneId, String title) {

        static Task from(TaskMention t) {
            return new Task(t.challengeId(), t.challengeTitle(), t.milestoneId(), t.title());
        }
    }

    /**
     * Lo que trae el día: estudios (estudio y repaso), entrenos, clases y eventos personales; entregas y exámenes;
     * tareas de reto sueltas; y si recuerda también el registro diario.
     */
    @Schema(name = "ReminderPlanSummary")
    public record Summary(int studies, int trainings, int classes, int personal, List<SummaryDeadline> deadlines,
                          int tasks, boolean checkIn) {

        static Summary from(ReminderPlan.DaySummary s) {
            return s == null ? null : new Summary(s.studies(), s.trainings(), s.classes(), s.personal(),
                    s.deadlines().stream().map(d -> new SummaryDeadline(d.title(), d.exam())).toList(), s.tasks(),
                    s.checkIn());
        }
    }

    /** Entrega o examen del resumen. */
    @Schema(name = "ReminderPlanSummaryDeadline")
    public record SummaryDeadline(String title, boolean exam) {
    }

    public static ReminderPlanResponse from(ReminderPlan plan) {
        return new ReminderPlanResponse(plan.reminders().stream()
                .map(r -> new Item(r.kind(), r.at(), r.refId(), r.count(), r.title(), r.startsAt(), r.targetId(),
                        r.place(), r.tasks().stream().map(Task::from).toList(), Summary.from(r.summary())))
                .toList());
    }
}
