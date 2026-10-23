package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.PersonalRecord;
import java.util.List;
import java.util.UUID;

/** Mejor serie de la última sesión en que se hizo cada ejercicio (referencia para la siguiente). */
public interface ListLastPerformanceUseCase {

    List<PersonalRecord> lastPerformance(UUID userId);
}
