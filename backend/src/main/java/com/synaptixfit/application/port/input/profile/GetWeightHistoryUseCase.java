package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.WeightRecord;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Historial de peso del usuario entre dos días (ambos opcionales e inclusivos, en UTC). */
public interface GetWeightHistoryUseCase {

    List<WeightRecord> getWeightHistory(UUID userId, LocalDate from, LocalDate to);
}
