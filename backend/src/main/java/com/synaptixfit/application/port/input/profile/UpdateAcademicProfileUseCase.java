package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.StudyModality;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Edición parcial del perfil académico (los nulos no cambian). Si el perfil no existe se crea con
 * los valores por defecto. {@code degreeId} se resuelve y vincula como en el guardado completo.
 */
public interface UpdateAcademicProfileUseCase {

    record Command(UUID userId, String university, String degree, UUID degreeId, Integer semester,
                   StudyModality modality, Integer semesterCredits, Integer weeklyStudyHoursGoal, Double targetGpa,
                   LocalDate classesStartDate, LocalDate classesEndDate) {}

    AcademicProfile updateAcademicProfile(Command command);
}
