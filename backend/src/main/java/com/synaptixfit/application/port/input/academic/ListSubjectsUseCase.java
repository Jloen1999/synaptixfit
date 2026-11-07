package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectSummary;
import java.util.List;
import java.util.UUID;

/** Lista las asignaturas del usuario con sus conteos de apuntes y archivos (archived nulo: todas). */
public interface ListSubjectsUseCase {

    /** {@code zone}: zona IANA del móvil para contar los días de la agenda; nula, la del servidor. */
    List<SubjectSummary> listSubjects(UUID userId, Boolean archived, String zone);
}
