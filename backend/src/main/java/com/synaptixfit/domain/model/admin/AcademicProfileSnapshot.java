package com.synaptixfit.domain.model.admin;

import java.time.LocalDate;

/** Datos del perfil académico visibles en el panel. */
public record AcademicProfileSnapshot(String university, String degree, int currentSemester, String modality,
                                      int semesterCredits, int weeklyStudyHoursGoal, Double targetGrade,
                                      LocalDate classesStart, LocalDate classesEnd) {
}
