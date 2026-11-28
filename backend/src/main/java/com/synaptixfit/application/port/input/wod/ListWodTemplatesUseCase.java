package com.synaptixfit.application.port.input.wod;

import com.synaptixfit.domain.model.wod.WodTemplates;
import java.util.List;

/** Los WOD de ejemplo (ADR 0069). */
public interface ListWodTemplatesUseCase {

    List<WodTemplates.Template> listTemplates();
}
