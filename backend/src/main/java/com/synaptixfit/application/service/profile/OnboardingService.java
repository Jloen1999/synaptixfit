package com.synaptixfit.application.service.profile;

import com.synaptixfit.application.port.input.catalog.ListMyDegreesUseCase;
import com.synaptixfit.application.port.input.profile.CompleteOnboardingUseCase;
import com.synaptixfit.application.port.input.profile.GetOnboardingStatusUseCase;
import com.synaptixfit.application.port.input.profile.GetProfileSummaryUseCase;
import com.synaptixfit.application.port.input.profile.ProfileSummary;
import com.synaptixfit.domain.exception.profile.OnboardingRequiresWellnessProfileException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.OnboardingStatus;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.profile.AcademicProfileRepositoryPort;
import com.synaptixfit.domain.port.output.profile.UserSubjectsQueryPort;
import com.synaptixfit.domain.port.output.profile.WellnessProfileRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.Optional;
import java.util.UUID;

/**
 * Estado del onboarding y resumen del perfil. El cierre se guarda en la cuenta ({@link User}); el
 * perfil físico solo es obligatorio si el enfoque incluye deporte.
 */
public class OnboardingService implements GetOnboardingStatusUseCase, CompleteOnboardingUseCase,
        GetProfileSummaryUseCase {

    private final UserRepositoryPort users;
    private final WellnessProfileRepositoryPort wellnessProfiles;
    private final AcademicProfileRepositoryPort academicProfiles;
    private final UserSubjectsQueryPort subjects;
    private final ListMyDegreesUseCase myDegrees;
    private final Clock clock;

    public OnboardingService(UserRepositoryPort users, WellnessProfileRepositoryPort wellnessProfiles,
                             AcademicProfileRepositoryPort academicProfiles, UserSubjectsQueryPort subjects,
                             ListMyDegreesUseCase myDegrees, Clock clock) {
        this.users = users;
        this.wellnessProfiles = wellnessProfiles;
        this.academicProfiles = academicProfiles;
        this.subjects = subjects;
        this.myDegrees = myDegrees;
        this.clock = clock;
    }

    @Override
    public OnboardingStatus getOnboardingStatus(UUID userId) {
        return status(activeUser(userId), wellnessProfiles.findByUserId(userId),
                academicProfiles.findByUserId(userId));
    }

    @Override
    public OnboardingStatus completeOnboarding(UUID userId) {
        User user = activeUser(userId);
        Optional<WellnessProfile> wellness = wellnessProfiles.findByUserId(userId);
        if (user.effectiveFocus().includesFitness() && wellness.isEmpty()) {
            throw new OnboardingRequiresWellnessProfileException();
        }
        // Se sigue marcando también el perfil físico: el panel de administración lo muestra.
        if (wellness.isPresent() && !wellness.get().onboardingCompleted()) {
            WellnessProfile profile = wellness.get();
            profile.completeOnboarding();
            profile.touch(clock.instant());
            wellness = Optional.of(wellnessProfiles.save(profile));
        }
        if (!user.onboardingCompleted()) {
            user.completeOnboarding();
            users.save(user);
        }
        return status(user, wellness, academicProfiles.findByUserId(userId));
    }

    @Override
    public ProfileSummary getProfileSummary(UUID userId) {
        Optional<WellnessProfile> wellness = wellnessProfiles.findByUserId(userId);
        Optional<AcademicProfile> academic = academicProfiles.findByUserId(userId);
        return new ProfileSummary(wellness.orElse(null), academic.orElse(null), myDegrees.listMyDegrees(userId),
                status(activeUser(userId), wellness, academic));
    }

    private OnboardingStatus status(User user, Optional<WellnessProfile> wellness,
                                    Optional<AcademicProfile> academic) {
        UUID userId = user.id();
        boolean marked = user.onboardingCompleted()
                || wellness.map(WellnessProfile::onboardingCompleted).orElse(false);
        return new OnboardingStatus(user.hasPassword(), user.usageFocus(), wellness.isPresent(),
                academic.isPresent(), subjects.hasActiveSubjects(userId), marked);
    }

    private User activeUser(UUID userId) {
        return users.findById(userId).filter(User::isActive)
                .orElseThrow(() -> new UserNotFoundException(userId));
    }
}
