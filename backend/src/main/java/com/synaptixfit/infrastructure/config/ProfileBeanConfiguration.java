package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.catalog.ListMyDegreesUseCase;
import com.synaptixfit.application.port.input.profile.CompleteOnboardingUseCase;
import com.synaptixfit.application.port.input.profile.GetAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.GetGoalHistoryUseCase;
import com.synaptixfit.application.port.input.profile.GetOnboardingStatusUseCase;
import com.synaptixfit.application.port.input.profile.GetProfileSummaryUseCase;
import com.synaptixfit.application.port.input.profile.GetWeightHistoryUseCase;
import com.synaptixfit.application.port.input.profile.GetWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.SaveAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.SaveWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.SuggestGoalsUseCase;
import com.synaptixfit.application.port.input.profile.UpdateAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.UpdateWellnessProfileUseCase;
import com.synaptixfit.application.service.profile.AcademicProfileService;
import com.synaptixfit.application.service.profile.OnboardingService;
import com.synaptixfit.application.service.profile.WellnessProfileService;
import com.synaptixfit.domain.port.output.catalog.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.catalog.UserDegreeRepositoryPort;
import com.synaptixfit.domain.port.output.profile.AcademicProfileRepositoryPort;
import com.synaptixfit.domain.port.output.profile.GoalHistoryRepositoryPort;
import com.synaptixfit.domain.port.output.profile.GoalSuggestionPort;
import com.synaptixfit.domain.port.output.profile.UserSubjectsQueryPort;
import com.synaptixfit.domain.port.output.profile.WeightHistoryRepositoryPort;
import com.synaptixfit.domain.port.output.profile.WellnessProfileRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Raíz de composición del perfil (bienestar, académico y onboarding), patrón de {@link BeanConfiguration}. */
@Configuration
public class ProfileBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final WellnessProfileRepositoryPort wellnessProfiles;
    private final WeightHistoryRepositoryPort weightHistory;
    private final GoalHistoryRepositoryPort goalHistory;
    private final GoalSuggestionPort goalSuggestions;
    private final AcademicProfileRepositoryPort academicProfiles;
    private final AcademicCatalogPort catalog;
    private final UserDegreeRepositoryPort userDegrees;
    private final UserSubjectsQueryPort subjects;
    private final UserRepositoryPort users;
    private final ListMyDegreesUseCase listMyDegrees;
    private final Clock clock;

    public ProfileBeanConfiguration(TransactionalUseCaseFactory tx, WellnessProfileRepositoryPort wellnessProfiles,
                                    WeightHistoryRepositoryPort weightHistory, GoalHistoryRepositoryPort goalHistory,
                                    GoalSuggestionPort goalSuggestions, AcademicProfileRepositoryPort academicProfiles,
                                    AcademicCatalogPort catalog, UserDegreeRepositoryPort userDegrees,
                                    UserSubjectsQueryPort subjects, UserRepositoryPort users,
                                    ListMyDegreesUseCase listMyDegrees, Clock clock) {
        this.tx = tx;
        this.wellnessProfiles = wellnessProfiles;
        this.weightHistory = weightHistory;
        this.goalHistory = goalHistory;
        this.goalSuggestions = goalSuggestions;
        this.academicProfiles = academicProfiles;
        this.catalog = catalog;
        this.userDegrees = userDegrees;
        this.subjects = subjects;
        this.users = users;
        this.listMyDegrees = listMyDegrees;
        this.clock = clock;
    }

    // ---------------------------------------------------------------- bienestar

    @Bean(autowireCandidate = false)
    WellnessProfileService wellnessProfileService() {
        return new WellnessProfileService(wellnessProfiles, weightHistory, goalHistory, goalSuggestions, clock);
    }

    @Bean
    GetWellnessProfileUseCase getWellnessProfileUseCase() {
        return tx.wrap(GetWellnessProfileUseCase.class, wellnessProfileService());
    }

    @Bean
    SaveWellnessProfileUseCase saveWellnessProfileUseCase() {
        return tx.wrap(SaveWellnessProfileUseCase.class, wellnessProfileService());
    }

    @Bean
    UpdateWellnessProfileUseCase updateWellnessProfileUseCase() {
        return tx.wrap(UpdateWellnessProfileUseCase.class, wellnessProfileService());
    }

    @Bean
    GetWeightHistoryUseCase getWeightHistoryUseCase() {
        return tx.wrap(GetWeightHistoryUseCase.class, wellnessProfileService());
    }

    @Bean
    GetGoalHistoryUseCase getGoalHistoryUseCase() {
        return tx.wrap(GetGoalHistoryUseCase.class, wellnessProfileService());
    }

    /** Sin transacción: la llamada a la IA puede tardar y solo lee el perfil. */
    @Bean
    SuggestGoalsUseCase suggestGoalsUseCase() {
        return wellnessProfileService()::suggestGoals;
    }

    // ---------------------------------------------------------------- académico

    @Bean(autowireCandidate = false)
    AcademicProfileService academicProfileService() {
        return new AcademicProfileService(academicProfiles, catalog, userDegrees, clock);
    }

    @Bean
    GetAcademicProfileUseCase getAcademicProfileUseCase() {
        return tx.wrap(GetAcademicProfileUseCase.class, academicProfileService());
    }

    @Bean
    SaveAcademicProfileUseCase saveAcademicProfileUseCase() {
        return tx.wrap(SaveAcademicProfileUseCase.class, academicProfileService());
    }

    @Bean
    UpdateAcademicProfileUseCase updateAcademicProfileUseCase() {
        return tx.wrap(UpdateAcademicProfileUseCase.class, academicProfileService());
    }

    // ---------------------------------------------------------------- onboarding y resumen

    @Bean(autowireCandidate = false)
    OnboardingService onboardingService() {
        return new OnboardingService(users, wellnessProfiles, academicProfiles, subjects, listMyDegrees, clock);
    }

    @Bean
    GetOnboardingStatusUseCase getOnboardingStatusUseCase() {
        return tx.wrap(GetOnboardingStatusUseCase.class, onboardingService());
    }

    @Bean
    CompleteOnboardingUseCase completeOnboardingUseCase() {
        return tx.wrap(CompleteOnboardingUseCase.class, onboardingService());
    }

    @Bean
    GetProfileSummaryUseCase getProfileSummaryUseCase() {
        return tx.wrap(GetProfileSummaryUseCase.class, onboardingService());
    }
}
