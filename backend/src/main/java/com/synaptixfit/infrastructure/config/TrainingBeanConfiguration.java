package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.training.AddRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.AddRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.AddRoutineWeekUseCase;
import com.synaptixfit.application.port.input.training.AdminGetExerciseUseCase;
import com.synaptixfit.application.port.input.training.AdminSearchExercisesUseCase;
import com.synaptixfit.application.port.input.training.ApplyRecommendationUseCase;
import com.synaptixfit.application.port.input.training.CancelTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.ChangeRoutineStatusUseCase;
import com.synaptixfit.application.port.input.training.CloneRoutineUseCase;
import com.synaptixfit.application.port.input.training.CreateExerciseUseCase;
import com.synaptixfit.application.port.input.training.CreateRoutineUseCase;
import com.synaptixfit.application.port.input.training.DeleteExerciseUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineUseCase;
import com.synaptixfit.application.port.input.training.DeleteRoutineWeekUseCase;
import com.synaptixfit.application.port.input.training.DeleteSessionSetUseCase;
import com.synaptixfit.application.port.input.training.DeleteWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.DiscardRecommendationUseCase;
import com.synaptixfit.application.port.input.training.DuplicateRoutineUseCase;
import com.synaptixfit.application.port.input.training.FinishTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.GenerateRoutineProposalUseCase;
import com.synaptixfit.application.port.input.training.GetExerciseFilterOptionsUseCase;
import com.synaptixfit.application.port.input.training.GetExerciseUseCase;
import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.application.port.input.training.GetRoutineUseCase;
import com.synaptixfit.application.port.input.training.GetTodayCheckInUseCase;
import com.synaptixfit.application.port.input.training.GetTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.GetWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.ListCheckInsUseCase;
import com.synaptixfit.application.port.input.training.ListCommunityRoutinesUseCase;
import com.synaptixfit.application.port.input.training.ListExerciseAlternativesUseCase;
import com.synaptixfit.application.port.input.training.ListMyRoutinesUseCase;
import com.synaptixfit.application.port.input.training.ListRecommendationsUseCase;
import com.synaptixfit.application.port.input.training.ListTrainingSessionsUseCase;
import com.synaptixfit.application.port.input.training.ListWeeklyPlansUseCase;
import com.synaptixfit.application.port.input.training.PrivatizeUserRoutinesUseCase;
import com.synaptixfit.application.port.input.training.RecordSessionSetUseCase;
import com.synaptixfit.application.port.input.training.RefineRoutineProposalUseCase;
import com.synaptixfit.application.port.input.training.RemoveRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.RenameRoutineDayUseCase;
import com.synaptixfit.application.port.input.training.ReorderRoutineExercisesUseCase;
import com.synaptixfit.application.port.input.training.SaveWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.training.SearchExercisesUseCase;
import com.synaptixfit.application.port.input.training.SetExerciseActiveUseCase;
import com.synaptixfit.application.port.input.training.StartTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.SubmitDailyCheckInUseCase;
import com.synaptixfit.application.port.input.training.SuggestSessionBookendsUseCase;
import com.synaptixfit.application.port.input.training.UnmarkTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.UpdateExerciseUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineExerciseUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineUseCase;
import com.synaptixfit.application.port.input.training.UpdateRoutineWeekUseCase;
import com.synaptixfit.application.service.training.DailyCheckInService;
import com.synaptixfit.application.service.training.ExerciseCatalogService;
import com.synaptixfit.application.service.training.RecommendationService;
import com.synaptixfit.application.service.training.RoutineGenerationService;
import com.synaptixfit.application.service.training.RoutineService;
import com.synaptixfit.application.service.training.TrainingSessionService;
import com.synaptixfit.application.service.training.WeeklyPlanService;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.training.DailyCheckInRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.domain.port.output.training.RecommendationRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineGeneratorPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingContextPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import com.synaptixfit.domain.port.output.training.WeeklyPlanRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Raíz de composición del módulo de entrenamiento (catálogo de ejercicios, rutinas, generación,
 * sesiones, sugerencias, check-in diario y plan semanal). Sigue el patrón de {@link BeanConfiguration}.
 */
@Configuration
public class TrainingBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final ExerciseRepositoryPort exercises;
    private final RoutineRepositoryPort routines;
    private final TrainingSessionRepositoryPort sessions;
    private final DailyCheckInRepositoryPort checkIns;
    private final WeeklyPlanRepositoryPort plans;
    private final RecommendationRepositoryPort recommendations;
    private final TrainingContextPort context;
    private final RoutineGeneratorPort generator;
    private final UserRepositoryPort users;
    private final AwardExperienceUseCase awardExperience;
    private final RevokeExperienceUseCase revokeExperience;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final ZoneId zone;
    private final GetCognitiveStateUseCase cognitiveState;
    private final GetCrossRegulationUseCase crossRegulation;

    /**
     * @param zone «día» de sesiones y check-ins: la zona de los indicadores
     *             ({@code synaptixfit.insights.default-zone}), para que todos los módulos fechen igual
     */
    public TrainingBeanConfiguration(TransactionalUseCaseFactory tx,
                                     ExerciseRepositoryPort exercises,
                                     RoutineRepositoryPort routines,
                                     TrainingSessionRepositoryPort sessions,
                                     DailyCheckInRepositoryPort checkIns,
                                     WeeklyPlanRepositoryPort plans,
                                     RecommendationRepositoryPort recommendations,
                                     TrainingContextPort context,
                                     RoutineGeneratorPort generator,
                                     UserRepositoryPort users,
                                     AwardExperienceUseCase awardExperience,
                                     RevokeExperienceUseCase revokeExperience,
                                     DomainEventPublisherPort events,
                                     Clock clock,
                                     GetCognitiveStateUseCase cognitiveState,
                                     GetCrossRegulationUseCase crossRegulation,
                                     @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.exercises = exercises;
        this.routines = routines;
        this.sessions = sessions;
        this.checkIns = checkIns;
        this.plans = plans;
        this.recommendations = recommendations;
        this.context = context;
        this.generator = generator;
        this.users = users;
        this.awardExperience = awardExperience;
        this.revokeExperience = revokeExperience;
        this.events = events;
        this.clock = clock;
        this.cognitiveState = cognitiveState;
        this.crossRegulation = crossRegulation;
        this.zone = ZoneId.of(zone);
    }

    // ---------------------------------------------------------------- ExerciseCatalogService

    @Bean(autowireCandidate = false)
    ExerciseCatalogService exerciseCatalogService() {
        return new ExerciseCatalogService(exercises, clock);
    }

    @Bean
    SearchExercisesUseCase searchExercisesUseCase() {
        return tx.wrap(SearchExercisesUseCase.class, exerciseCatalogService());
    }

    @Bean
    SuggestSessionBookendsUseCase suggestSessionBookendsUseCase() {
        return tx.wrap(SuggestSessionBookendsUseCase.class, exerciseCatalogService());
    }

    @Bean
    ListExerciseAlternativesUseCase listExerciseAlternativesUseCase() {
        return tx.wrap(ListExerciseAlternativesUseCase.class, exerciseCatalogService());
    }

    @Bean
    GetExerciseUseCase getExerciseUseCase() {
        return tx.wrap(GetExerciseUseCase.class, exerciseCatalogService());
    }

    @Bean
    GetExerciseFilterOptionsUseCase getExerciseFilterOptionsUseCase() {
        return tx.wrap(GetExerciseFilterOptionsUseCase.class, exerciseCatalogService());
    }

    @Bean
    AdminSearchExercisesUseCase adminSearchExercisesUseCase() {
        return tx.wrap(AdminSearchExercisesUseCase.class, exerciseCatalogService());
    }

    @Bean
    AdminGetExerciseUseCase adminGetExerciseUseCase() {
        return tx.wrap(AdminGetExerciseUseCase.class, exerciseCatalogService());
    }

    @Bean
    CreateExerciseUseCase createExerciseUseCase() {
        return tx.wrap(CreateExerciseUseCase.class, exerciseCatalogService());
    }

    @Bean
    UpdateExerciseUseCase updateExerciseUseCase() {
        return tx.wrap(UpdateExerciseUseCase.class, exerciseCatalogService());
    }

    @Bean
    SetExerciseActiveUseCase setExerciseActiveUseCase() {
        return tx.wrap(SetExerciseActiveUseCase.class, exerciseCatalogService());
    }

    @Bean
    DeleteExerciseUseCase deleteExerciseUseCase() {
        return tx.wrap(DeleteExerciseUseCase.class, exerciseCatalogService());
    }

    // ---------------------------------------------------------------- RoutineService

    @Bean(autowireCandidate = false)
    RoutineService routineService() {
        return new RoutineService(routines, exercises, users, clock);
    }

    @Bean
    CreateRoutineUseCase createRoutineUseCase() {
        return tx.wrap(CreateRoutineUseCase.class, routineService());
    }

    @Bean
    GetRoutineUseCase getRoutineUseCase() {
        return tx.wrap(GetRoutineUseCase.class, routineService());
    }

    @Bean
    ListMyRoutinesUseCase listMyRoutinesUseCase() {
        return tx.wrap(ListMyRoutinesUseCase.class, routineService());
    }

    @Bean
    UpdateRoutineUseCase updateRoutineUseCase() {
        return tx.wrap(UpdateRoutineUseCase.class, routineService());
    }

    @Bean
    ChangeRoutineStatusUseCase changeRoutineStatusUseCase() {
        return tx.wrap(ChangeRoutineStatusUseCase.class, routineService());
    }

    @Bean
    DeleteRoutineUseCase deleteRoutineUseCase() {
        return tx.wrap(DeleteRoutineUseCase.class, routineService());
    }

    @Bean
    DuplicateRoutineUseCase duplicateRoutineUseCase() {
        return tx.wrap(DuplicateRoutineUseCase.class, routineService());
    }

    @Bean
    CloneRoutineUseCase cloneRoutineUseCase() {
        return tx.wrap(CloneRoutineUseCase.class, routineService());
    }

    @Bean
    ListCommunityRoutinesUseCase listCommunityRoutinesUseCase() {
        return tx.wrap(ListCommunityRoutinesUseCase.class, routineService());
    }

    @Bean
    AddRoutineWeekUseCase addRoutineWeekUseCase() {
        return tx.wrap(AddRoutineWeekUseCase.class, routineService());
    }

    @Bean
    UpdateRoutineWeekUseCase updateRoutineWeekUseCase() {
        return tx.wrap(UpdateRoutineWeekUseCase.class, routineService());
    }

    @Bean
    DeleteRoutineWeekUseCase deleteRoutineWeekUseCase() {
        return tx.wrap(DeleteRoutineWeekUseCase.class, routineService());
    }

    @Bean
    AddRoutineDayUseCase addRoutineDayUseCase() {
        return tx.wrap(AddRoutineDayUseCase.class, routineService());
    }

    @Bean
    RenameRoutineDayUseCase renameRoutineDayUseCase() {
        return tx.wrap(RenameRoutineDayUseCase.class, routineService());
    }

    @Bean
    DeleteRoutineDayUseCase deleteRoutineDayUseCase() {
        return tx.wrap(DeleteRoutineDayUseCase.class, routineService());
    }

    @Bean
    AddRoutineExerciseUseCase addRoutineExerciseUseCase() {
        return tx.wrap(AddRoutineExerciseUseCase.class, routineService());
    }

    @Bean
    UpdateRoutineExerciseUseCase updateRoutineExerciseUseCase() {
        return tx.wrap(UpdateRoutineExerciseUseCase.class, routineService());
    }

    @Bean
    RemoveRoutineExerciseUseCase removeRoutineExerciseUseCase() {
        return tx.wrap(RemoveRoutineExerciseUseCase.class, routineService());
    }

    @Bean
    ReorderRoutineExercisesUseCase reorderRoutineExercisesUseCase() {
        return tx.wrap(ReorderRoutineExercisesUseCase.class, routineService());
    }

    @Bean
    GetPendingTrainingDayUseCase getPendingTrainingDayUseCase() {
        return tx.wrap(GetPendingTrainingDayUseCase.class, routineService());
    }

    @Bean
    PrivatizeUserRoutinesUseCase privatizeUserRoutinesUseCase() {
        return tx.wrap(PrivatizeUserRoutinesUseCase.class, routineService());
    }

    // ---------------------------------------------------------------- RoutineGenerationService

    @Bean(autowireCandidate = false)
    RoutineGenerationService routineGenerationService() {
        return new RoutineGenerationService(context, exercises, sessions, checkIns, generator, cognitiveState,
                crossRegulation, clock, zone);
    }

    @Bean
    GenerateRoutineProposalUseCase generateRoutineProposalUseCase() {
        return tx.wrap(GenerateRoutineProposalUseCase.class, routineGenerationService());
    }

    @Bean
    RefineRoutineProposalUseCase refineRoutineProposalUseCase() {
        return tx.wrap(RefineRoutineProposalUseCase.class, routineGenerationService());
    }

    // ---------------------------------------------------------------- TrainingSessionService

    @Bean(autowireCandidate = false)
    TrainingSessionService trainingSessionService() {
        return new TrainingSessionService(sessions, routines, recommendations, context, awardExperience,
                revokeExperience, events, clock, zone);
    }

    @Bean
    StartTrainingSessionUseCase startTrainingSessionUseCase() {
        return tx.wrap(StartTrainingSessionUseCase.class, trainingSessionService());
    }

    @Bean
    RecordSessionSetUseCase recordSessionSetUseCase() {
        return tx.wrap(RecordSessionSetUseCase.class, trainingSessionService());
    }

    @Bean
    DeleteSessionSetUseCase deleteSessionSetUseCase() {
        return tx.wrap(DeleteSessionSetUseCase.class, trainingSessionService());
    }

    @Bean
    FinishTrainingSessionUseCase finishTrainingSessionUseCase() {
        return tx.wrap(FinishTrainingSessionUseCase.class, trainingSessionService());
    }

    @Bean
    UnmarkTrainingSessionUseCase unmarkTrainingSessionUseCase() {
        return tx.wrap(UnmarkTrainingSessionUseCase.class, trainingSessionService());
    }

    @Bean
    CancelTrainingSessionUseCase cancelTrainingSessionUseCase() {
        return tx.wrap(CancelTrainingSessionUseCase.class, trainingSessionService());
    }

    @Bean
    ListTrainingSessionsUseCase listTrainingSessionsUseCase() {
        return tx.wrap(ListTrainingSessionsUseCase.class, trainingSessionService());
    }

    @Bean
    GetTrainingSessionUseCase getTrainingSessionUseCase() {
        return tx.wrap(GetTrainingSessionUseCase.class, trainingSessionService());
    }

    // ---------------------------------------------------------------- RecommendationService

    @Bean(autowireCandidate = false)
    RecommendationService recommendationService() {
        return new RecommendationService(recommendations, routines);
    }

    @Bean
    ListRecommendationsUseCase listRecommendationsUseCase() {
        return tx.wrap(ListRecommendationsUseCase.class, recommendationService());
    }

    @Bean
    ApplyRecommendationUseCase applyRecommendationUseCase() {
        return tx.wrap(ApplyRecommendationUseCase.class, recommendationService());
    }

    @Bean
    DiscardRecommendationUseCase discardRecommendationUseCase() {
        return tx.wrap(DiscardRecommendationUseCase.class, recommendationService());
    }

    // ---------------------------------------------------------------- DailyCheckInService

    @Bean(autowireCandidate = false)
    DailyCheckInService dailyCheckInService() {
        return new DailyCheckInService(checkIns, awardExperience, events, clock, zone);
    }

    @Bean
    SubmitDailyCheckInUseCase submitDailyCheckInUseCase() {
        return tx.wrap(SubmitDailyCheckInUseCase.class, dailyCheckInService());
    }

    @Bean
    GetTodayCheckInUseCase getTodayCheckInUseCase() {
        return tx.wrap(GetTodayCheckInUseCase.class, dailyCheckInService());
    }

    @Bean
    ListCheckInsUseCase listCheckInsUseCase() {
        return tx.wrap(ListCheckInsUseCase.class, dailyCheckInService());
    }

    // ---------------------------------------------------------------- WeeklyPlanService

    @Bean(autowireCandidate = false)
    WeeklyPlanService weeklyPlanService() {
        return new WeeklyPlanService(plans, sessions, clock);
    }

    @Bean
    SaveWeeklyPlanUseCase saveTrainingWeeklyPlanUseCase() {
        return tx.wrap(SaveWeeklyPlanUseCase.class, weeklyPlanService());
    }

    @Bean
    GetWeeklyPlanUseCase getWeeklyPlanUseCase() {
        return tx.wrap(GetWeeklyPlanUseCase.class, weeklyPlanService());
    }

    @Bean
    ListWeeklyPlansUseCase listWeeklyPlansUseCase() {
        return tx.wrap(ListWeeklyPlansUseCase.class, weeklyPlanService());
    }

    @Bean
    DeleteWeeklyPlanUseCase deleteWeeklyPlanUseCase() {
        return tx.wrap(DeleteWeeklyPlanUseCase.class, weeklyPlanService());
    }
}
