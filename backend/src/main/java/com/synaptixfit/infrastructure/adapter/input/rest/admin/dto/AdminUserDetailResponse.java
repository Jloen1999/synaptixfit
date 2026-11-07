package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.AcademicProfileSnapshot;
import com.synaptixfit.domain.model.admin.AdminUserDetail;
import com.synaptixfit.domain.model.admin.WellbeingProfileSnapshot;
import java.time.LocalDate;

/**
 * Ficha de un usuario: cuenta y perfiles (nulos si no los ha completado). Los textos de los
 * perfiles son los valores almacenados (p. ej. {@code sex = "mujer"}, {@code mainGoal = "Fuerza Máxima"}).
 */
public record AdminUserDetailResponse(AdminUserAccountResponse account, WellbeingProfile wellbeingProfile,
                                      AcademicProfile academicProfile) {

    /** Perfil de bienestar. */
    public record WellbeingProfile(Integer age, String sex, Double weightKg, Double heightCm, Double bmi,
                                   String activityLevel, String mainGoal, int availableDaysPerWeek,
                                   int minutesPerSession, boolean onboardingCompleted) {

        static WellbeingProfile from(WellbeingProfileSnapshot p) {
            return p == null ? null : new WellbeingProfile(p.age(), p.sex(), p.weightKg(), p.heightCm(), p.bmi(),
                    p.activityLevel(), p.mainGoal(), p.availableDaysPerWeek(), p.minutesPerSession(),
                    p.onboardingCompleted());
        }
    }

    /** Perfil académico. */
    public record AcademicProfile(String university, String degree, int currentSemester, String modality,
                                  int semesterCredits, int weeklyStudyHoursGoal, Double targetGrade,
                                  LocalDate classesStart, LocalDate classesEnd) {

        static AcademicProfile from(AcademicProfileSnapshot p) {
            return p == null ? null : new AcademicProfile(p.university(), p.degree(), p.currentSemester(),
                    p.modality(), p.semesterCredits(), p.weeklyStudyHoursGoal(), p.targetGrade(), p.classesStart(),
                    p.classesEnd());
        }
    }

    public static AdminUserDetailResponse from(AdminUserDetail d) {
        return new AdminUserDetailResponse(AdminUserAccountResponse.from(d.user()), WellbeingProfile.from(d.wellbeing()),
                AcademicProfile.from(d.academic()));
    }
}
