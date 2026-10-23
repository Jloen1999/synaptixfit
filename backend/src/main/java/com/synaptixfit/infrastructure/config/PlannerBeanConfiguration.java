package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.planner.CompleteReviewBlockUseCase;
import com.synaptixfit.application.port.input.planner.DeleteSubjectBlocksUseCase;
import com.synaptixfit.application.port.input.planner.PrivatizeUserStudyPlansUseCase;
import com.synaptixfit.application.port.input.planner.SyncSportBlockWithSessionUseCase;
import com.synaptixfit.application.port.input.planner.CreateCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.CreateDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.CreateDeadlinesFromGuideUseCase;
import com.synaptixfit.application.port.input.planner.DeleteCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.DeleteDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.DeleteStudyPlanUseCase;
import com.synaptixfit.application.port.input.planner.DistributeRoutineUseCase;
import com.synaptixfit.application.port.input.planner.ExportIcsUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarBlocksUseCase;
import com.synaptixfit.application.port.input.planner.GetDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.GetDeadlinesUseCase;
import com.synaptixfit.application.port.input.planner.GetFocusPlanUseCase;
import com.synaptixfit.application.port.input.planner.GetFocusStatsUseCase;
import com.synaptixfit.application.port.input.planner.GetScheduleConflictsUseCase;
import com.synaptixfit.application.port.input.planner.GetStudyPlansUseCase;
import com.synaptixfit.application.port.input.planner.GetTimelineUseCase;
import com.synaptixfit.application.port.input.planner.GetWeekBalanceUseCase;
import com.synaptixfit.application.port.input.planner.GetWeeklyLoadsUseCase;
import com.synaptixfit.application.port.input.planner.ImportIcsUseCase;
import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.application.port.input.planner.RescheduleCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.SaveWeeklyPlanUseCase;
import com.synaptixfit.application.port.input.planner.ScanScheduleUseCase;
import com.synaptixfit.application.port.input.planner.ScheduleReviewBlockUseCase;
import com.synaptixfit.application.port.input.planner.SetBlockCompletionUseCase;
import com.synaptixfit.application.port.input.planner.SetDeadlineCompletionUseCase;
import com.synaptixfit.application.port.input.planner.SuggestWeekPlanUseCase;
import com.synaptixfit.application.port.input.planner.SyncDeadlineFromChallengeUseCase;
import com.synaptixfit.application.port.input.planner.SyncWeeklyLoadUseCase;
import com.synaptixfit.application.port.input.planner.UpdateCalendarBlockUseCase;
import com.synaptixfit.application.port.input.planner.UpdateDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.UpdateWeeklyWellbeingUseCase;
import com.synaptixfit.application.service.planner.BlockCompletionService;
import com.synaptixfit.application.service.planner.CalendarBlockService;
import com.synaptixfit.application.service.planner.DeadlineService;
import com.synaptixfit.application.service.planner.FocusPlanService;
import com.synaptixfit.application.service.planner.FocusService;
import com.synaptixfit.application.service.planner.IcsService;
import com.synaptixfit.application.service.planner.PlanningSuggestionService;
import com.synaptixfit.application.service.planner.ReviewBlockService;
import com.synaptixfit.application.service.planner.RoutineDistributionService;
import com.synaptixfit.application.service.planner.ScheduleScanService;
import com.synaptixfit.application.service.planner.StudyPlanService;
import com.synaptixfit.application.service.planner.TimelineService;
import com.synaptixfit.application.service.planner.WeeklyLoadService;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.ChallengeDirectoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.FocusSessionRepositoryPort;
import com.synaptixfit.domain.port.output.planner.IcsFeedPort;
import com.synaptixfit.domain.port.output.planner.PlannerProfilePort;
import com.synaptixfit.domain.port.output.planner.PlanningAssistantPort;
import com.synaptixfit.domain.port.output.planner.RoutineDirectoryPort;
import com.synaptixfit.domain.port.output.planner.ScheduleScannerPort;
import com.synaptixfit.domain.port.output.planner.StudyPlanRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.planner.WeeklyLoadRepositoryPort;
import java.time.Clock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Raíz de composición del planificador (calendario, entregas, plan y carga semanal, ICS, escaneo de
 * horarios, sugerencias con IA y Pomodoro). Mismo patrón que {@link BeanConfiguration}.
 *
 * <p>La zona horaria de referencia ({@code synaptixfit.planner.zone}, por defecto Europe/Madrid)
 * define los días y las semanas del calendario.
 */
@Configuration
public class PlannerBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final CalendarBlockRepositoryPort blocks;
    private final DeadlineRepositoryPort deadlines;
    private final StudyPlanRepositoryPort plans;
    private final WeeklyLoadRepositoryPort loads;
    private final FocusSessionRepositoryPort focusSessions;
    private final SubjectDirectoryPort subjects;
    private final PlannerProfilePort profiles;
    private final RoutineDirectoryPort routines;
    private final ChallengeDirectoryPort challenges;
    private final IcsFeedPort icsFeed;
    private final ScheduleScannerPort scheduleScanner;
    private final PlanningAssistantPort planningAssistant;
    private final AwardExperienceUseCase award;
    private final RevokeExperienceUseCase revoke;
    private final DomainEventPublisherPort events;
    private final GetCrossRegulationUseCase crossRegulation;
    private final Clock clock;
    private final PlannerZone zone;
    private final UsageFocusPort focus;

    public PlannerBeanConfiguration(TransactionalUseCaseFactory tx, CalendarBlockRepositoryPort blocks,
                                    DeadlineRepositoryPort deadlines, StudyPlanRepositoryPort plans,
                                    WeeklyLoadRepositoryPort loads, FocusSessionRepositoryPort focusSessions,
                                    SubjectDirectoryPort subjects, PlannerProfilePort profiles,
                                    RoutineDirectoryPort routines, ChallengeDirectoryPort challenges,
                                    IcsFeedPort icsFeed, ScheduleScannerPort scheduleScanner,
                                    PlanningAssistantPort planningAssistant, AwardExperienceUseCase award,
                                    RevokeExperienceUseCase revoke, DomainEventPublisherPort events,
                                    GetCrossRegulationUseCase crossRegulation, Clock clock,
                                    @Value("${synaptixfit.planner.zone:Europe/Madrid}") String zoneId,
                                    UsageFocusPort focus) {
        this.focus = focus;
        this.tx = tx;
        this.blocks = blocks;
        this.deadlines = deadlines;
        this.plans = plans;
        this.loads = loads;
        this.focusSessions = focusSessions;
        this.subjects = subjects;
        this.profiles = profiles;
        this.routines = routines;
        this.challenges = challenges;
        this.icsFeed = icsFeed;
        this.scheduleScanner = scheduleScanner;
        this.planningAssistant = planningAssistant;
        this.award = award;
        this.revoke = revoke;
        this.events = events;
        this.crossRegulation = crossRegulation;
        this.clock = clock;
        this.zone = PlannerZone.of(zoneId);
    }

    // ---------------------------------------------------------------- carga semanal

    @Bean(autowireCandidate = false)
    WeeklyLoadService weeklyLoadService() {
        return new WeeklyLoadService(loads, blocks, deadlines, profiles, award, revoke, zone);
    }

    @Bean
    SyncWeeklyLoadUseCase syncWeeklyLoadUseCase() {
        return tx.wrap(SyncWeeklyLoadUseCase.class, weeklyLoadService());
    }

    @Bean
    UpdateWeeklyWellbeingUseCase updateWeeklyWellbeingUseCase() {
        return tx.wrap(UpdateWeeklyWellbeingUseCase.class, weeklyLoadService());
    }

    @Bean
    GetWeeklyLoadsUseCase getWeeklyLoadsUseCase() {
        return tx.wrap(GetWeeklyLoadsUseCase.class, weeklyLoadService());
    }

    @Bean
    GetWeekBalanceUseCase getWeekBalanceUseCase() {
        return tx.wrap(GetWeekBalanceUseCase.class, weeklyLoadService());
    }

    // ---------------------------------------------------------------- bloques

    @Bean(autowireCandidate = false)
    CalendarBlockService calendarBlockService() {
        return new CalendarBlockService(blocks, deadlines, subjects, routines, challenges, revoke, events,
                weeklyLoadService(), zone, clock);
    }

    @Bean
    GetCalendarBlocksUseCase getCalendarBlocksUseCase() {
        return tx.wrap(GetCalendarBlocksUseCase.class, calendarBlockService());
    }

    @Bean
    GetCalendarBlockUseCase getCalendarBlockUseCase() {
        return tx.wrap(GetCalendarBlockUseCase.class, calendarBlockService());
    }

    @Bean
    CreateCalendarBlockUseCase createCalendarBlockUseCase() {
        return tx.wrap(CreateCalendarBlockUseCase.class, calendarBlockService());
    }

    @Bean
    UpdateCalendarBlockUseCase updateCalendarBlockUseCase() {
        return tx.wrap(UpdateCalendarBlockUseCase.class, calendarBlockService());
    }

    @Bean
    RescheduleCalendarBlockUseCase rescheduleCalendarBlockUseCase() {
        return tx.wrap(RescheduleCalendarBlockUseCase.class, calendarBlockService());
    }

    @Bean
    DeleteCalendarBlockUseCase deleteCalendarBlockUseCase() {
        return tx.wrap(DeleteCalendarBlockUseCase.class, calendarBlockService());
    }

    @Bean
    DeleteSubjectBlocksUseCase deleteSubjectBlocksUseCase() {
        return tx.wrap(DeleteSubjectBlocksUseCase.class, calendarBlockService());
    }

    @Bean
    GetScheduleConflictsUseCase getScheduleConflictsUseCase() {
        return tx.wrap(GetScheduleConflictsUseCase.class, calendarBlockService());
    }

    @Bean(autowireCandidate = false)
    BlockCompletionService blockCompletionService() {
        return new BlockCompletionService(blocks, subjects, profiles, award, revoke, events, weeklyLoadService(),
                zone, clock);
    }

    @Bean
    SetBlockCompletionUseCase setBlockCompletionUseCase() {
        return tx.wrap(SetBlockCompletionUseCase.class, blockCompletionService());
    }

    @Bean
    SyncSportBlockWithSessionUseCase syncSportBlockWithSessionUseCase() {
        return tx.wrap(SyncSportBlockWithSessionUseCase.class, blockCompletionService());
    }

    @Bean
    CompleteReviewBlockUseCase completeReviewBlockUseCase() {
        return tx.wrap(CompleteReviewBlockUseCase.class, blockCompletionService());
    }

    @Bean(autowireCandidate = false)
    RoutineDistributionService routineDistributionService() {
        return new RoutineDistributionService(blocks, routines, weeklyLoadService(), zone, clock);
    }

    @Bean
    DistributeRoutineUseCase distributeRoutineUseCase() {
        return tx.wrap(DistributeRoutineUseCase.class, routineDistributionService());
    }

    @Bean(autowireCandidate = false)
    ReviewBlockService reviewBlockService() {
        return new ReviewBlockService(blocks, subjects, zone, clock);
    }

    @Bean
    ScheduleReviewBlockUseCase scheduleReviewBlockUseCase() {
        return tx.wrap(ScheduleReviewBlockUseCase.class, reviewBlockService());
    }

    // ---------------------------------------------------------------- entregas

    @Bean(autowireCandidate = false)
    DeadlineService deadlineService() {
        return new DeadlineService(deadlines, subjects, award, revoke, events, weeklyLoadService(), zone, clock);
    }

    @Bean
    CreateDeadlineUseCase createDeadlineUseCase() {
        return tx.wrap(CreateDeadlineUseCase.class, deadlineService());
    }

    @Bean
    CreateDeadlinesFromGuideUseCase createDeadlinesFromGuideUseCase() {
        return tx.wrap(CreateDeadlinesFromGuideUseCase.class, deadlineService());
    }

    @Bean
    UpdateDeadlineUseCase updateDeadlineUseCase() {
        return tx.wrap(UpdateDeadlineUseCase.class, deadlineService());
    }

    @Bean
    DeleteDeadlineUseCase deleteDeadlineUseCase() {
        return tx.wrap(DeleteDeadlineUseCase.class, deadlineService());
    }

    @Bean
    GetDeadlineUseCase getDeadlineUseCase() {
        return tx.wrap(GetDeadlineUseCase.class, deadlineService());
    }

    @Bean
    GetDeadlinesUseCase getDeadlinesUseCase() {
        return tx.wrap(GetDeadlinesUseCase.class, deadlineService());
    }

    @Bean
    SetDeadlineCompletionUseCase setDeadlineCompletionUseCase() {
        return tx.wrap(SetDeadlineCompletionUseCase.class, deadlineService());
    }

    @Bean
    SyncDeadlineFromChallengeUseCase syncDeadlineFromChallengeUseCase() {
        return tx.wrap(SyncDeadlineFromChallengeUseCase.class, deadlineService());
    }

    // ---------------------------------------------------------------- plan semanal

    @Bean(autowireCandidate = false)
    StudyPlanService studyPlanService() {
        return new StudyPlanService(plans, blocks, deadlines, award, revoke, zone);
    }

    @Bean
    SaveWeeklyPlanUseCase saveWeeklyPlanUseCase() {
        return tx.wrap(SaveWeeklyPlanUseCase.class, studyPlanService());
    }

    @Bean
    GetStudyPlansUseCase getStudyPlansUseCase() {
        return tx.wrap(GetStudyPlansUseCase.class, studyPlanService());
    }

    @Bean
    DeleteStudyPlanUseCase deleteStudyPlanUseCase() {
        return tx.wrap(DeleteStudyPlanUseCase.class, studyPlanService());
    }

    @Bean
    PrivatizeUserStudyPlansUseCase privatizeUserStudyPlansUseCase() {
        return tx.wrap(PrivatizeUserStudyPlansUseCase.class, studyPlanService());
    }

    // ---------------------------------------------------------------- línea de tiempo e ICS

    @Bean(autowireCandidate = false)
    TimelineService timelineService() {
        return new TimelineService(blocks, deadlines, subjects);
    }

    @Bean
    GetTimelineUseCase getTimelineUseCase() {
        return tx.wrap(GetTimelineUseCase.class, timelineService());
    }

    @Bean(autowireCandidate = false)
    IcsService icsService() {
        return new IcsService(subjects, blocks, deadlines, icsFeed, timelineService(), weeklyLoadService(), zone, clock);
    }

    @Bean
    ImportIcsUseCase importIcsUseCase() {
        return tx.wrap(ImportIcsUseCase.class, icsService());
    }

    @Bean
    ExportIcsUseCase exportIcsUseCase() {
        return tx.wrap(ExportIcsUseCase.class, icsService());
    }

    // ---------------------------------------------------------------- IA

    @Bean(autowireCandidate = false)
    ScheduleScanService scheduleScanService() {
        return new ScheduleScanService(scheduleScanner, subjects, profiles, blocks, zone, clock);
    }

    @Bean
    ScanScheduleUseCase scanScheduleUseCase() {
        return tx.wrap(ScanScheduleUseCase.class, scheduleScanService());
    }

    @Bean(autowireCandidate = false)
    PlanningSuggestionService planningSuggestionService() {
        return new PlanningSuggestionService(planningAssistant, subjects, deadlines, routines, blocks, crossRegulation,
                zone, clock, focus);
    }

    @Bean
    SuggestWeekPlanUseCase suggestWeekPlanUseCase() {
        return tx.wrap(SuggestWeekPlanUseCase.class, planningSuggestionService());
    }

    // ---------------------------------------------------------------- pomodoro

    @Bean(autowireCandidate = false)
    FocusService focusService() {
        return new FocusService(focusSessions, blocks, subjects, award, events, zone, clock);
    }

    @Bean
    RecordFocusSessionUseCase recordFocusSessionUseCase() {
        return tx.wrap(RecordFocusSessionUseCase.class, focusService());
    }

    @Bean
    GetFocusStatsUseCase getFocusStatsUseCase() {
        return tx.wrap(GetFocusStatsUseCase.class, focusService());
    }

    @Bean
    GetFocusPlanUseCase getFocusPlanUseCase() {
        return tx.wrap(GetFocusPlanUseCase.class, new FocusPlanService(crossRegulation));
    }
}
