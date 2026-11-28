package com.synaptixfit.application.port.input.wod;

import com.synaptixfit.domain.model.wod.WodMark;
import java.util.List;
import java.util.UUID;

/** «Mis marcas»: de la más reciente a la más antigua, señalando la mejor de cada WOD y división (ADR 0069). */
public interface ListWodMarksUseCase {

    List<WodMark> listMarks(UUID userId);
}
