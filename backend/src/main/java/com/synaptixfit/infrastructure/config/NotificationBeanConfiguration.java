package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.notification.CountUnreadNotificationsUseCase;
import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.notification.DeleteNotificationUseCase;
import com.synaptixfit.application.port.input.notification.GetNotificationPreferencesUseCase;
import com.synaptixfit.application.port.input.notification.InitializeNotificationPreferencesUseCase;
import com.synaptixfit.application.port.input.notification.ListNotificationsUseCase;
import com.synaptixfit.application.port.input.notification.MarkAllNotificationsReadUseCase;
import com.synaptixfit.application.port.input.notification.MarkNotificationReadUseCase;
import com.synaptixfit.application.port.input.notification.NotifyAchievementUseCase;
import com.synaptixfit.application.port.input.notification.NotifyFatigueAlertUseCase;
import com.synaptixfit.application.port.input.notification.UpdateNotificationPreferencesUseCase;
import com.synaptixfit.application.service.notification.AutomaticNotificationService;
import com.synaptixfit.application.service.notification.NotificationPreferencesService;
import com.synaptixfit.application.service.notification.NotificationService;
import com.synaptixfit.domain.port.output.notification.ExamCalendarPort;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import com.synaptixfit.domain.port.output.notification.NotificationRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición del centro de notificaciones. La zona horaria de las horas de silencio y del límite
 * diario sale de {@code synaptixfit.notifications.zone} (por defecto Europe/Madrid).
 */
@Configuration
public class NotificationBeanConfiguration {

    private final ExamCalendarPort exams;
    private final TransactionalUseCaseFactory tx;
    private final NotificationRepositoryPort notifications;
    private final NotificationPreferencesRepositoryPort preferences;
    private final Clock clock;
    private final ZoneId zone;

    public NotificationBeanConfiguration(TransactionalUseCaseFactory tx, NotificationRepositoryPort notifications,
                                         NotificationPreferencesRepositoryPort preferences, ExamCalendarPort exams,
                                         Clock clock,
                                         @Value("${synaptixfit.notifications.zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.exams = exams;
        this.notifications = notifications;
        this.preferences = preferences;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    // ---------------------------------------------------------------- notificaciones

    @Bean(autowireCandidate = false)
    NotificationService notificationService() {
        return new NotificationService(notifications, preferences, exams, clock, zone);
    }

    @Bean
    CreateNotificationUseCase createNotificationUseCase() {
        return tx.wrap(CreateNotificationUseCase.class, notificationService());
    }

    @Bean(autowireCandidate = false)
    AutomaticNotificationService automaticNotificationService() {
        return new AutomaticNotificationService(createNotificationUseCase(), notifications, clock, zone);
    }

    @Bean
    NotifyAchievementUseCase notifyAchievementUseCase() {
        return tx.wrap(NotifyAchievementUseCase.class, automaticNotificationService());
    }

    @Bean
    NotifyFatigueAlertUseCase notifyFatigueAlertUseCase() {
        return tx.wrap(NotifyFatigueAlertUseCase.class, automaticNotificationService());
    }

    @Bean
    ListNotificationsUseCase listNotificationsUseCase() {
        return tx.wrap(ListNotificationsUseCase.class, notificationService());
    }

    @Bean
    CountUnreadNotificationsUseCase countUnreadNotificationsUseCase() {
        return tx.wrap(CountUnreadNotificationsUseCase.class, notificationService());
    }

    @Bean
    MarkNotificationReadUseCase markNotificationReadUseCase() {
        return tx.wrap(MarkNotificationReadUseCase.class, notificationService());
    }

    @Bean
    MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase() {
        return tx.wrap(MarkAllNotificationsReadUseCase.class, notificationService());
    }

    @Bean
    DeleteNotificationUseCase deleteNotificationUseCase() {
        return tx.wrap(DeleteNotificationUseCase.class, notificationService());
    }

    // ---------------------------------------------------------------- preferencias

    @Bean(autowireCandidate = false)
    NotificationPreferencesService notificationPreferencesService() {
        return new NotificationPreferencesService(preferences, clock);
    }

    @Bean
    GetNotificationPreferencesUseCase getNotificationPreferencesUseCase() {
        return tx.wrap(GetNotificationPreferencesUseCase.class, notificationPreferencesService());
    }

    @Bean
    UpdateNotificationPreferencesUseCase updateNotificationPreferencesUseCase() {
        return tx.wrap(UpdateNotificationPreferencesUseCase.class, notificationPreferencesService());
    }

    @Bean
    InitializeNotificationPreferencesUseCase initializeNotificationPreferencesUseCase() {
        return tx.wrap(InitializeNotificationPreferencesUseCase.class, notificationPreferencesService());
    }
}
