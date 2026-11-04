package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.CycleDay;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Días apuntados entre dos fechas, como mucho {@code MAX_DAYS} días (un mes y algo para el calendario). */
public interface ListCycleDaysUseCase {

    int MAX_DAYS = 93;

    List<CycleDay> list(UUID userId, LocalDate from, LocalDate to);
}
