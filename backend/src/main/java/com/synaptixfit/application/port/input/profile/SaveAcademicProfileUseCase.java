package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.StudyModality;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Crea o reemplaza el perfil académico completo. Los opcionales nulos toman su valor por defecto
 * o se borran. Si llega {@code degreeId}, la universidad y la carrera se resuelven desde el
 * catálogo (ignorando los textos) y la carrera se vincula al usuario.
 */
public interface SaveAcademicProfileUseCase {

    record Command(UUID userId, String university, String degree, UUID degreeId, Integer semester,
                   StudyModality modality, Integer semesterCredits, Integer weeklyStudyHoursGoal, Double targetGpa,
                   LocalDate classesStartDate, LocalDate classesEndDate) {}

    AcademicProfile saveAcademicProfile(Command command);
}
