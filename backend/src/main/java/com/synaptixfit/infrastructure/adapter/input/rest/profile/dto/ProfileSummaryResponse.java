package com.synaptixfit.infrastructure.adapter.input.rest.profile.dto;

import com.synaptixfit.application.port.input.profile.ProfileSummary;
import com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto.UserDegreeResponse;
import java.util.List;

/** Resumen del perfil. {@code wellness} y {@code academic} son nulos si aún no existen. */
public record ProfileSummaryResponse(WellnessProfileResponse wellness, AcademicProfileResponse academic,
                                     List<UserDegreeResponse> degrees, OnboardingStatusResponse onboarding) {

    public static ProfileSummaryResponse from(ProfileSummary s) {
        return new ProfileSummaryResponse(
                s.wellness() == null ? null : WellnessProfileResponse.from(s.wellness()),
                s.academic() == null ? null : AcademicProfileResponse.from(s.academic()),
                s.degrees().stream().map(UserDegreeResponse::from).toList(),
                OnboardingStatusResponse.from(s.onboarding()));
    }
}
