package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.model.challenge.TaskMention;
import java.time.Instant;
import java.util.List;
import java.util.Objects;

/**
 * Avisos que el móvil debe programar, ya decididos por {@link ReminderPlanner} y ordenados por hora.
 * El cliente solo pone los textos y los programa.
 */
public record ReminderPlan(List<Item> reminders) {

    public ReminderPlan {
        reminders = List.copyOf(reminders);
    }

    public static ReminderPlan empty() {
        return new ReminderPlan(List.of());
    }

    /**
     * Aviso del plan. Según {@code kind}: {@code count} son los repasos vencidos ({@code REVIEWS}) o los días que
     * faltan ({@code EXAM}, {@code DEADLINE}, {@code CHALLENGE_TASK}); {@code startsAt} es el inicio del bloque o la
     * fecha de la entrega; {@code title}, el del bloque o la entrega. {@code targetId} es lo que se abre al tocarlo
     * cuando no coincide con {@code refId} (en las entregas, el {@code refId} lleva además los días de antelación;
     * en una tarea de reto, el reto); {@code place}, el aula de una clase ({@code CLASS_SOON}). {@code tasks}: tareas
     * de reto que menciona (las que avanzan con ese evento o esa entrega, o la propia en {@code CHALLENGE_TASK});
     * {@code summary}, lo que trae el resumen de la mañana ({@code MORNING_SUMMARY}).
     */
    public record Item(ReminderKind kind, Instant at, String refId, Integer count, String title,
                       Instant startsAt, String targetId, String place, List<TaskMention> tasks, DaySummary summary) {

        public Item {
            Objects.requireNonNull(kind, "kind");
            Objects.requireNonNull(at, "at");
            Objects.requireNonNull(refId, "refId");
            tasks = tasks == null ? List.of() : List.copyOf(tasks);
        }

        public Item(ReminderKind kind, Instant at, String refId, Integer count, String title,
                    Instant startsAt, String targetId, String place) {
            this(kind, at, refId, count, title, startsAt, targetId, place, List.of(), null);
        }

        /** Aviso cuyo {@code refId} ya es lo que se abre al tocarlo. */
        public Item(ReminderKind kind, Instant at, String refId, Integer count, String title, Instant startsAt) {
            this(kind, at, refId, count, title, startsAt, null, null);
        }

        /** El mismo aviso mencionando estas tareas de reto. */
        public Item withTasks(List<TaskMention> mentioned) {
            return new Item(kind, at, refId, count, title, startsAt, targetId, place, mentioned, summary);
        }

        /** El mismo resumen, ahora también con el registro diario (ver {@link ReminderPlanner}). */
        Item withCheckIn() {
            return new Item(kind, at, refId, count, title, startsAt, targetId, place, tasks,
                    summary == null ? null : summary.withCheckIn());
        }

        /** El mismo resumen, que ahora empieza felicitando el cumpleaños; {@code name} va en el título. */
        Item withBirthday(String name) {
            return new Item(kind, at, refId, count, name, startsAt, targetId, place, tasks,
                    summary == null ? null : summary.withBirthday());
        }
    }

    /**
     * Lo que trae un día, para el resumen de la mañana: estudios (estudio y repaso), entrenos, clases y eventos
     * personales que empiezan después del resumen, entregas y exámenes que vencen ese día, tareas de reto de ese día
     * que no van ya con uno de esos eventos, si incluye el aviso del registro diario y si felicita el cumpleaños
     * (ADR 0036: ese día el resumen lleva la felicitación en vez de llegar dos avisos).
     */
    public record DaySummary(int studies, int trainings, int classes, int personal, List<SummaryDeadline> deadlines,
                             int tasks, boolean checkIn, boolean birthday) {

        public DaySummary {
            deadlines = deadlines == null ? List.of() : List.copyOf(deadlines);
        }

        public DaySummary(int studies, int trainings, int classes, int personal, List<SummaryDeadline> deadlines,
                          int tasks, boolean checkIn) {
            this(studies, trainings, classes, personal, deadlines, tasks, checkIn, false);
        }

        /** ¿Hay algo que contar? Sin nada, no se manda resumen. */
        public boolean isEmpty() {
            return studies + trainings + classes + personal + tasks == 0 && deadlines.isEmpty();
        }

        DaySummary withCheckIn() {
            return new DaySummary(studies, trainings, classes, personal, deadlines, tasks, true, birthday);
        }

        DaySummary withBirthday() {
            return new DaySummary(studies, trainings, classes, personal, deadlines, tasks, checkIn, true);
        }
    }

    /** Entrega o examen del resumen de la mañana. */
    public record SummaryDeadline(String title, boolean exam) {
    }
}
