package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.CatalogSubjectSelection;
import java.util.List;
import java.util.UUID;

/** Asignaturas del catálogo de las carreras del usuario, marcando las que ya tiene activas. */
public interface ListCatalogSubjectsUseCase {

    List<CatalogSubjectSelection> listCatalogSubjects(UUID userId);
}
