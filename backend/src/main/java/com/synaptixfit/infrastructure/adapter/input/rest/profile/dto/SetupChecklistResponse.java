package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.domain.model.profile.SetupChecklist;
import com.synaptixfit.domain.model.profile.SetupChecklist.SetupTask;
import java.util.List;

/** Configuración pendiente en orden de importancia; {@code total} son las tareas que aplican al enfoque. */
public record SetupChecklistResponse(List<SetupTask> pending, int total) {

    public static SetupChecklistResponse from(SetupChecklist c) {
        return new SetupChecklistResponse(c.pending(), c.total());
    }
}
