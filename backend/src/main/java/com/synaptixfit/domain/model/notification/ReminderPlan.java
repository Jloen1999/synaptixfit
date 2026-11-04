package com.synaptixfit.domain.model.notification;

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
     * faltan ({@code EXAM}, {@code DEADLINE}); {@code startsAt} es el inicio del bloque o la fecha de la entrega;
     * {@code title}, el del bloque o la entrega. {@code targetId} es lo que se abre al tocarlo cuando no
     * coincide con {@code refId} (en las entregas, el {@code refId} lleva además los días de antelación);
     * {@code place}, el aula de una clase ({@code CLASS_SOON}).
     */
    public record Item(ReminderKind kind, Instant at, String refId, Integer count, String title,
                       Instant startsAt, String targetId, String place) {

        public Item {
            Objects.requireNonNull(kind, "kind");
            Objects.requireNonNull(at, "at");
            Objects.requireNonNull(refId, "refId");
        }

        /** Aviso cuyo {@code refId} ya es lo que se abre al tocarlo. */
        public Item(ReminderKind kind, Instant at, String refId, Integer count, String title, Instant startsAt) {
            this(kind, at, refId, count, title, startsAt, null, null);
        }
    }
}
