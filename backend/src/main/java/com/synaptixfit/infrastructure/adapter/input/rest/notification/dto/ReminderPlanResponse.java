package com.synaptixfit.infrastructure.adapter.input.rest.notification.dto;

import com.synaptixfit.domain.model.notification.ReminderKind;
import com.synaptixfit.domain.model.notification.ReminderPlan;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.List;

/** Plan de recordatorios locales del móvil, ordenado por hora. El cliente solo pone los textos. */
public record ReminderPlanResponse(List<Item> reminders) {

    /**
     * Un aviso.
     *
     * @param refId    id del bloque, o día local (ISO) del aviso de repasos
     * @param count    repasos vencidos (solo {@code REVIEWS})
     * @param title    título o asignatura del bloque; nulo si no tiene (solo bloques)
     * @param startsAt inicio del bloque (solo bloques)
     */
    @Schema(name = "ReminderPlanItem")
    public record Item(ReminderKind kind, Instant at, String refId, Integer count, String title, Instant startsAt) {
    }

    public static ReminderPlanResponse from(ReminderPlan plan) {
        return new ReminderPlanResponse(plan.reminders().stream()
                .map(r -> new Item(r.kind(), r.at(), r.refId(), r.count(), r.title(), r.startsAt()))
                .toList());
    }
}
