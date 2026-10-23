package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.CatalogSubject;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

/** Lectura del catálogo académico (módulo Perfil y catálogo). */
public interface AcademicCatalogPort {

    List<CatalogSubject> findByIds(Collection<UUID> ids);

    /**
     * Asignaturas del catálogo de las carreras del usuario ({@code usuario_carreras}; si no tiene,
     * la carrera de su perfil académico por nombre), ordenadas por curso, semestre y nombre.
     */
    List<CatalogSubject> findForUserDegrees(UUID userId);
}
