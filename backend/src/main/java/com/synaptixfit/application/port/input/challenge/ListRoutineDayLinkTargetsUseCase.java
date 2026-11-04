package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.RoutineDayTarget;
import java.util.List;
import java.util.UUID;

/** Días de la rutina en curso a los que se puede vincular una tarea de reto (los que quedan por entrenar). */
public interface ListRoutineDayLinkTargetsUseCase {

    List<RoutineDayTarget> routineDayTargets(UUID userId);
}
