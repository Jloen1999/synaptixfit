package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.AcademicSearch;
import java.util.List;
import java.util.UUID;

/** Busca en lo académico de una persona ({@link AcademicSearch}); cada método trae como mucho {@code limit} filas. */
public interface AcademicSearchPort {

    /** Asignaturas (sin archivar primero) por nombre, siglas o profesor. */
    List<AcademicSearch.Hit> subjects(UUID userId, String folded, int limit);

    /** Apuntes propios por título o contenido, los más recientes primero. */
    List<AcademicSearch.Hit> notes(UUID userId, String folded, int limit);

    /** Archivos subidos por nombre. */
    List<AcademicSearch.Hit> files(UUID userId, String folded, int limit);

    /** Entregas y exámenes sin hacer por título, los más cercanos primero. */
    List<AcademicSearch.Hit> deadlines(UUID userId, String folded, int limit);
}
