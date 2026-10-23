package com.synaptixfit.application.port.input.profile;

import java.util.UUID;

/** Resumen del perfil: bienestar, académico, carreras vinculadas y estado del onboarding. */
public interface GetProfileSummaryUseCase {

    ProfileSummary getProfileSummary(UUID userId);
}
