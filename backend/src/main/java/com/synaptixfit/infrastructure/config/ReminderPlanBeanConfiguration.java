package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.application.port.input.notification.ChangeReminderOptionsUseCase;
import com.synaptixfit.application.port.input.notification.GetReminderOptionsUseCase;
import com.synaptixfit.application.port.input.training.GetTodayCheckInUseCase;
import com.synaptixfit.application.service.notification.ReminderOptionsService;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.application.port.input.notification.GetReminderPlanUseCase;
import com.synaptixfit.application.port.input.training.GetPendingTrainingDayUseCase;
import com.synaptixfit.application.port.input.training.ListOpenSessionsUseCase;
import com.synaptixfit.application.service.notification.ReminderPlanService;
import com.synaptixfit.domain.model.notification.ReminderPlanner;
import com.synaptixfit.domain.port.output.notification.ExamCalendarPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.DeadlineRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import com.synaptixfit.application.port.input.run.ListPlannedRunsUseCase;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición del plan de recordatorios del móvil. Usa la misma zona que las horas de silencio del
 * centro de notificaciones ({@code synaptixfit.notifications.zone}).
 */
@Configuration
public class ReminderPlanBeanConfiguration {

    private final ExamCalendarPort exams;
    private final TransactionalUseCaseFactory tx;
    private final NotificationPreferencesRepositoryPort preferences;
    private final UsageFocusPort focus;
    private final StudyMaterialRepositoryPort materials;
    private final CalendarBlockRepositoryPort blocks;
    private final DeadlineRepositoryPort deadlines;
    private final SubjectDirectoryPort subjects;
    private final Clock clock;
    private final ZoneId zone;
    private final ReminderOptionsRepositoryPort reminderOptions;

    public ReminderPlanBeanConfiguration(TransactionalUseCaseFactory tx,
                                         NotificationPreferencesRepositoryPort preferences, UsageFocusPort focus,
                                         StudyMaterialRepositoryPort materials, CalendarBlockRepositoryPort blocks,
                                         DeadlineRepositoryPort deadlines, SubjectDirectoryPort subjects,
                                         ExamCalendarPort exams, ReminderOptionsRepositoryPort reminderOptions,
                                         Clock clock,
                                         @Value("${synaptixfit.notifications.zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.preferences = preferences;
        this.focus = focus;
        this.materials = materials;
        this.blocks = blocks;
        this.deadlines = deadlines;
        this.subjects = subjects;
        this.exams = exams;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
        this.reminderOptions = reminderOptions;
    }

    /**
     * Los avisos de seguimiento leen entrenamiento, retos y carreras programadas con sus casos de uso; los de
     * bienestar, la racha y el registro diario de hoy; las opciones y el cumpleaños, sus puertos (ADR 0035 y 0036).
     */
    @Bean
    GetReminderPlanUseCase getReminderPlanUseCase(GetPendingTrainingDayUseCase pendingDay,
                                                  ListOpenSessionsUseCase openSessions,
                                                  ListMyChallengesUseCase challenges,
                                                  ListPlannedRunsUseCase plannedRuns,
                                                  UserRepositoryPort users,
                                                  GetStreakUseCase streak, GetTodayCheckInUseCase checkIn) {
        return tx.wrap(GetReminderPlanUseCase.class, new ReminderPlanService(
                new ReminderPlanService.Stores(preferences, reminderOptions, focus, users, materials, blocks,
                        deadlines, subjects, exams),
                new ReminderPlanner(), clock, zone,
                new ReminderPlanService.FollowUpSources(pendingDay, openSessions, challenges, plannedRuns),
                new ReminderPlanService.Wellbeing(streak, checkIn)));
    }

    /** Una sola instancia para leer y cambiar las opciones; cada contrato se expone envuelto en su transacción. */
    @Bean(autowireCandidate = false)
    ReminderOptionsService reminderOptionsService() {
        return new ReminderOptionsService(reminderOptions, clock);
    }

    @Bean
    GetReminderOptionsUseCase getReminderOptionsUseCase() {
        return tx.wrap(GetReminderOptionsUseCase.class, reminderOptionsService());
    }

    @Bean
    ChangeReminderOptionsUseCase changeReminderOptionsUseCase() {
        return tx.wrap(ChangeReminderOptionsUseCase.class, reminderOptionsService());
    }
}
