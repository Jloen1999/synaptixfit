package com.synaptixfit.infrastructure.adapter.input.rest.profile;

import com.synaptixfit.application.port.input.profile.CompleteOnboardingUseCase;
import com.synaptixfit.application.port.input.profile.GetOnboardingStatusUseCase;
import com.synaptixfit.application.port.input.profile.GetProfileSummaryUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.OnboardingStatusResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.profile.dto.ProfileSummaryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Resumen del perfil y estado del onboarding. */
@Tag(name = "Profile")
@RestController
@RequestMapping("/api/v1/profile")
public class ProfileController {

    private final GetProfileSummaryUseCase getSummary;
    private final GetOnboardingStatusUseCase getOnboarding;
    private final CompleteOnboardingUseCase completeOnboarding;

    public ProfileController(GetProfileSummaryUseCase getSummary, GetOnboardingStatusUseCase getOnboarding,
                             CompleteOnboardingUseCase completeOnboarding) {
        this.getSummary = getSummary;
        this.getOnboarding = getOnboarding;
        this.completeOnboarding = completeOnboarding;
    }

    @GetMapping
    public ProfileSummaryResponse summary(@CurrentUserId UUID userId) {
        return ProfileSummaryResponse.from(getSummary.getProfileSummary(userId));
    }

    @GetMapping("/onboarding")
    public OnboardingStatusResponse onboarding(@CurrentUserId UUID userId) {
        return OnboardingStatusResponse.from(getOnboarding.getOnboardingStatus(userId));
    }

    @PostMapping("/onboarding/complete")
    public OnboardingStatusResponse complete(@CurrentUserId UUID userId) {
        return OnboardingStatusResponse.from(completeOnboarding.completeOnboarding(userId));
    }
}
