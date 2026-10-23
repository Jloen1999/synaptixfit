package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.SessionBookends;
import java.util.List;
import java.util.UUID;

/** Calentamiento y vuelta a la calma para los ejercicios de una sesión. */
public interface SuggestSessionBookendsUseCase {

    SessionBookends bookends(List<UUID> exerciseIds);
}
