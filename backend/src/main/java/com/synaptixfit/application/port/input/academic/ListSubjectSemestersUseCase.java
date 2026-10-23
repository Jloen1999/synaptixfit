package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SubjectSemester;
import java.util.List;
import java.util.UUID;

/** Curso y semestre asignados a las asignaturas del usuario. */
public interface ListSubjectSemestersUseCase {

    List<SubjectSemester> listSemesters(UUID userId);
}
