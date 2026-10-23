package com.synaptixfit.application.service.profile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.profile.ProfileSummary;
import com.synaptixfit.application.service.catalog.UserDegreeService;
import com.synaptixfit.domain.exception.profile.OnboardingRequiresWellnessProfileException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.ActivityLevel;
import com.synaptixfit.domain.model.profile.BodyMeasurement;
import com.synaptixfit.domain.model.profile.OnboardingStatus;
import com.synaptixfit.domain.model.profile.OnboardingStep;
import com.synaptixfit.domain.model.profile.Sex;
import com.synaptixfit.domain.model.profile.TrainingGoal;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import com.synaptixfit.support.ProfileTestDoubles;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class OnboardingServiceTest {

    private final Instant now = Instant.parse("2026-10-01T10:00:00Z");
    private final Map<UUID, User> users = new HashMap<>();
    private final ProfileTestDoubles.Wellness wellness = new ProfileTestDoubles.Wellness();
    private final ProfileTestDoubles.Academic academic = new ProfileTestDoubles.Academic();
    private final ProfileTestDoubles.Catalog catalog = new ProfileTestDoubles.Catalog();
    private final ProfileTestDoubles.UserDegrees userDegrees = new ProfileTestDoubles.UserDegrees();
    private boolean hasSubjects;
    private OnboardingService service;
    private User googleUser;

    @BeforeEach
    void setUp() {
        UserRepositoryPort userPort = new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return Optional.ofNullable(users.get(id)); }
            public Optional<User> findByEmail(String e) { return Optional.empty(); }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return false; }
            public User save(User u) { users.put(u.id(), u); return u; }
        };
        googleUser = User.builder().id(UUID.randomUUID()).email("g@example.com").fullName("Gina")
                .googleSubject("sub").createdAt(now).build();
        users.put(googleUser.id(), googleUser);
        Clock clock = Clock.fixed(now, ZoneOffset.UTC);
        UserDegreeService degrees = new UserDegreeService(userDegrees, catalog, academic,
                new ProfileTestDoubles.SubjectLinks(), clock);
        service = new OnboardingService(userPort, wellness, academic, userId -> hasSubjects, degrees, clock);
    }

    private WellnessProfile wellnessProfile(UUID userId) {
        return WellnessProfile.builder().id(UUID.randomUUID()).userId(userId).age(21).sex(Sex.MALE)
                .measurement(new BodyMeasurement(70, 175)).activityLevel(ActivityLevel.LIGHT)
                .primaryGoal(TrainingGoal.STABILITY).availableDays(List.of(2, 4)).minutesPerSession(30)
                .createdAt(now).build();
    }

    @Test
    void newGoogleUserHasEveryStepPending() {
        OnboardingStatus status = service.getOnboardingStatus(googleUser.id());

        // La contraseña no es un paso: se pone en Ajustes cuando se quiera.
        assertThat(status.pendingSteps()).containsExactly(OnboardingStep.FOCUS,
                OnboardingStep.WELLNESS_PROFILE, OnboardingStep.ACADEMIC_PROFILE, OnboardingStep.SUBJECTS);
        assertThat(status.accountCompleted()).isFalse();
        assertThat(status.nextStep()).isEqualTo(OnboardingStep.FOCUS);
        assertThat(status.completed()).isFalse();
    }

    @Test
    void allStepsDoneMeansCompleted() {
        User withPassword = User.builder().id(UUID.randomUUID()).email("p@example.com").fullName("Pepe")
                .passwordHash("h").usageFocus(UsageFocus.BOTH).createdAt(now).build();
        users.put(withPassword.id(), withPassword);
        wellness.save(wellnessProfile(withPassword.id()));
        academic.save(AcademicProfile.createDefault(withPassword.id(), now));
        hasSubjects = true;

        OnboardingStatus status = service.getOnboardingStatus(withPassword.id());

        assertThat(status.pendingSteps()).isEmpty();
        assertThat(status.nextStep()).isNull();
        assertThat(status.completed()).isTrue();
    }

    @Test
    void completingRequiresWellnessProfileAndIsIdempotent() {
        assertThatThrownBy(() -> service.completeOnboarding(googleUser.id()))
                .isInstanceOf(OnboardingRequiresWellnessProfileException.class)
                .extracting("code").isEqualTo("PROFILE_ONBOARDING_WELLNESS_REQUIRED");

        wellness.save(wellnessProfile(googleUser.id()));
        OnboardingStatus status = service.completeOnboarding(googleUser.id());
        service.completeOnboarding(googleUser.id());

        assertThat(status.completed()).isTrue();
        assertThat(status.pendingSteps()).doesNotContain(OnboardingStep.ACCOUNT);
        assertThat(wellness.byUser.get(googleUser.id()).onboardingCompleted()).isTrue();
        assertThat(wellness.saves).isEqualTo(2);
        assertThat(users.get(googleUser.id()).onboardingCompleted()).isTrue();
    }

    @Test
    void academicOnlyFocusSkipsThePhysicalProfile() {
        User student = User.builder().id(UUID.randomUUID()).email("s@example.com").fullName("Sofía")
                .passwordHash("h").usageFocus(UsageFocus.ACADEMIC).createdAt(now).build();
        users.put(student.id(), student);

        assertThat(service.getOnboardingStatus(student.id()).pendingSteps())
                .containsExactly(OnboardingStep.ACADEMIC_PROFILE, OnboardingStep.SUBJECTS);

        OnboardingStatus status = service.completeOnboarding(student.id());

        assertThat(status.completed()).isTrue();
        assertThat(wellness.byUser).doesNotContainKey(student.id());
        assertThat(users.get(student.id()).onboardingCompleted()).isTrue();
    }

    @Test
    void unknownOrDeletedUserIsNotFound() {
        assertThatThrownBy(() -> service.getOnboardingStatus(UUID.randomUUID()))
                .isInstanceOf(UserNotFoundException.class);
        googleUser.anonymize(now);
        assertThatThrownBy(() -> service.getOnboardingStatus(googleUser.id()))
                .isInstanceOf(UserNotFoundException.class);
    }

    @Test
    void summaryAggregatesProfilesAndLinkedDegrees() {
        Degree degree = catalog.addDegree("Grado en Ingeniería Informática");
        userDegrees.link(googleUser.id(), degree.id(), now);
        wellness.save(wellnessProfile(googleUser.id()));

        ProfileSummary summary = service.getProfileSummary(googleUser.id());

        assertThat(summary.wellness()).isNotNull();
        assertThat(summary.academic()).isNull();
        assertThat(summary.degrees()).singleElement()
                .satisfies(d -> assertThat(d.degree().name()).isEqualTo("Grado en Ingeniería Informática"));
        assertThat(summary.onboarding().wellnessProfileCompleted()).isTrue();
    }
}
