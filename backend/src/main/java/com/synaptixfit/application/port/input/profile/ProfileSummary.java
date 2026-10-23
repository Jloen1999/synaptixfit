package com.synaptixfit.application.port.input.profile;

import com.synaptixfit.domain.model.catalog.UserDegree;
import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.OnboardingStatus;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import java.util.List;

/** Resumen del perfil para la pantalla de perfil. {@code wellness} y {@code academic} pueden ser nulos. */
public record ProfileSummary(WellnessProfile wellness, AcademicProfile academic, List<UserDegree> degrees,
                             OnboardingStatus onboarding) {

    public ProfileSummary {
        degrees = List.copyOf(degrees);
    }
}
