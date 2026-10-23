package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.University;
import java.util.List;

/** Universidades del catálogo (filtro opcional por nombre). */
public interface ListUniversitiesUseCase {

    List<University> listUniversities(String query);
}
