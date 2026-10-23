package com.synaptixfit.domain.port.output.training;

import com.synaptixfit.domain.model.training.SessionLabel;
import java.util.Collection;
import java.util.Map;
import java.util.UUID;

/** Lee el nombre de rutina y día de varias sesiones para mostrarlas en el historial. */
public interface SessionLabelQueryPort {

    /** Etiqueta por id de sesión; las sesiones que no existen no aparecen. */
    Map<UUID, SessionLabel> labels(Collection<UUID> sessionIds);
}
