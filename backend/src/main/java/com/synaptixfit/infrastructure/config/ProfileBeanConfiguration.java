package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.academic.CreateSubjectUseCase;
import com.synaptixfit.application.port.input.academic.CreateSubjectsFromCatalogUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectsUseCase;
import com.synaptixfit.application.port.input.catalog.LinkDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.ListDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.ListMyDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.ListUniversitiesUseCase;
import com.synaptixfit.application.port.input.catalog.SearchCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlocksUseCase;
import com.synaptixfit.application.port.input.profile.ApplyEnrollmentUseCase;
import com.synaptixfit.application.port.input.profile.CompleteOnboardingUseCase;
import com.synaptixfit.application.port.input.profile.GetAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.GetGoalHistoryUseCase;
import com.synaptixfit.application.port.input.profile.GetOnboardingStatusUseCase;
import com.synaptixfit.application.port.input.profile.GetProfileSummaryUseCase;
import com.synaptixfit.application.port.input.profile.GetSetupChecklistUseCase;
import com.synaptixfit.application.port.input.profile.GetWeightHistoryUseCase;
import com.synaptixfit.application.port.input.profile.GetWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.ReadEnrollmentUseCase;
import com.synaptixfit.application.port.input.profile.SaveAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.SaveWellnessProfileUseCase;
import com.synaptixfit.application.port.input.profile.SuggestGoalsUseCase;
import com.synaptixfit.application.port.input.profile.UpdateAcademicProfileUseCase;
import com.synaptixfit.application.port.input.profile.UpdateWellnessProfileUseCase;
import com.synaptixfit.application.port.input.training.ListMyRoutinesUseCase;
import com.synaptixfit.application.service.profile.AcademicProfileService;
import com.synaptixfit.application.service.profile.EnrollmentImportService;
import com.synaptixfit.application.service.profile.OnboardingService;
import com.synaptixfit.application.service.profile.SetupChecklistService;
import com.synaptixfit.application.service.profile.WellnessProfileService;
import com.synaptixfit.domain.port.output.catalog.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.catalog.UserDegreeRepositoryPort;
import com.synaptixfit.domain.port.output.profile.AcademicProfileRepositoryPort;
import com.synaptixfit.domain.port.output.profile.DocumentTextPort;
import com.synaptixfit.domain.port.output.profile.EnrollmentReaderPort;
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

    /** Importar la matrícula: los casos de uso de catálogo y académicos llegan por parámetro (sin ciclos). */
    @Bean(autowireCandidate = false)
    EnrollmentImportService enrollmentImportService(DocumentTextPort documents, EnrollmentReaderPort reader,
                                                    ListUniversitiesUseCase universities, ListDegreesUseCase degrees,
                                                    SearchCatalogSubjectsUseCase catalogSubjects,
                                                    ListSubjectsUseCase mySubjects, LinkDegreeUseCase linkDegree,
                                                    CreateSubjectsFromCatalogUseCase fromCatalog,
                                                    CreateSubjectUseCase createSubject) {
        return new EnrollmentImportService(documents, reader, users, universities, degrees, catalogSubjects,
                mySubjects, linkDegree, fromCatalog, createSubject);
    }

    /** Sin transacción: leer el PDF y la IA tardan; sus lecturas del catálogo llevan la suya propia. */
    @Bean
    ReadEnrollmentUseCase readEnrollmentUseCase(DocumentTextPort documents, EnrollmentReaderPort reader,
                                                ListUniversitiesUseCase universities, ListDegreesUseCase degrees,
                                                SearchCatalogSubjectsUseCase catalogSubjects,
                                                ListSubjectsUseCase mySubjects, LinkDegreeUseCase linkDegree,
                                                CreateSubjectsFromCatalogUseCase fromCatalog,
                                                CreateSubjectUseCase createSubject) {
        return enrollmentImportService(documents, reader, universities, degrees, catalogSubjects, mySubjects,
                linkDegree, fromCatalog, createSubject)::readEnrollment;
    }

    @Bean
    ApplyEnrollmentUseCase applyEnrollmentUseCase(DocumentTextPort documents, EnrollmentReaderPort reader,
                                                  ListUniversitiesUseCase universities, ListDegreesUseCase degrees,
                                                  SearchCatalogSubjectsUseCase catalogSubjects,
                                                  ListSubjectsUseCase mySubjects, LinkDegreeUseCase linkDegree,
                                                  CreateSubjectsFromCatalogUseCase fromCatalog,
                                                  CreateSubjectUseCase createSubject) {
        return tx.wrap(ApplyEnrollmentUseCase.class, enrollmentImportService(documents, reader, universities, degrees,
                catalogSubjects, mySubjects, linkDegree, fromCatalog, createSubject));
    }

    /** Rutinas y calendario llegan por parámetro (no por constructor) para no crear ciclos entre configuraciones. */
    @Bean
    GetSetupChecklistUseCase getSetupChecklistUseCase(ListMyRoutinesUseCase routines, GetCalendarBlocksUseCase blocks) {
        return tx.wrap(GetSetupChecklistUseCase.class,
                new SetupChecklistService(getOnboardingStatusUseCase(), routines, blocks, clock));
    }
}
