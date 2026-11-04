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

    public ReminderPlanBeanConfiguration(TransactionalUseCaseFactory tx,
                                         NotificationPreferencesRepositoryPort preferences, UsageFocusPort focus,
                                         StudyMaterialRepositoryPort materials, CalendarBlockRepositoryPort blocks,
                                         DeadlineRepositoryPort deadlines, SubjectDirectoryPort subjects,
                                         ExamCalendarPort exams, Clock clock,
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
    }

    /**
     * Los avisos de seguimiento leen entrenamiento y retos con sus casos de uso; los de bienestar, sus opciones, la
     * racha y el registro diario de hoy.
     */
    @Bean
    GetReminderPlanUseCase getReminderPlanUseCase(GetPendingTrainingDayUseCase pendingDay,
                                                  ListOpenSessionsUseCase openSessions,
                                                  ListMyChallengesUseCase challenges,
                                                  ReminderOptionsRepositoryPort reminderOptions,
                                                  GetStreakUseCase streak, GetTodayCheckInUseCase checkIn) {
        return tx.wrap(GetReminderPlanUseCase.class, new ReminderPlanService(preferences, focus, materials, blocks,
                deadlines, subjects, new ReminderPlanner(), exams, clock, zone, pendingDay, openSessions,
                challenges, new ReminderPlanService.Wellbeing(reminderOptions, streak, checkIn)));
    }

    @Bean
    GetReminderOptionsUseCase getReminderOptionsUseCase(ReminderOptionsRepositoryPort reminderOptions) {
        return tx.wrap(GetReminderOptionsUseCase.class, new ReminderOptionsService(reminderOptions, clock));
    }

    @Bean
    ChangeReminderOptionsUseCase changeReminderOptionsUseCase(ReminderOptionsRepositoryPort reminderOptions) {
        return tx.wrap(ChangeReminderOptionsUseCase.class, new ReminderOptionsService(reminderOptions, clock));
    }
}
