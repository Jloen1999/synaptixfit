package com.synaptixfit.application.port.input.training;

import com.synaptixfit.domain.model.training.PersonalRecord;
import java.util.List;
import java.util.UUID;

/** Mejor marca actual de cada ejercicio entrenado, de la más reciente a la más antigua. */
public interface ListPersonalRecordsUseCase {

    List<PersonalRecord> listPersonalRecords(UUID userId);
}
