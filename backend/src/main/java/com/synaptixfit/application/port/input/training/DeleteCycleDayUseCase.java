package com.synaptixfit.application.port.input.training;

import java.time.LocalDate;
import java.util.UUID;

/** Borra lo apuntado un día del ciclo (no falla si no había nada). */
public interface DeleteCycleDayUseCase {

    void delete(UUID userId, LocalDate date);
}
