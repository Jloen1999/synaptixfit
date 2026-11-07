package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.AcademicSearch;
import java.util.UUID;

/** Busca a la vez asignaturas, apuntes, archivos y entregas o exámenes de la persona (ADR 0036). */
public interface SearchAcademicUseCase {

    AcademicSearch.Result search(UUID userId, String query);
}
