package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.dashboard.GetDashboardUseCase;
import com.synaptixfit.application.port.input.notification.ConfirmWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.DisableWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.EnableWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.GetWeeklyEmailStatusUseCase;
import com.synaptixfit.application.port.input.notification.SendWeeklySummariesUseCase;
import com.synaptixfit.application.port.input.notification.UnsubscribeWeeklyEmailUseCase;
import com.synaptixfit.application.service.notification.WeeklyEmailService;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailMailerPort;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailSubscriptionRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Composición del resumen semanal por correo (ADR 0022) y activación de las tareas programadas
 * ({@code WeeklySummaryEmailScheduler}).
 */
@Configuration
@EnableScheduling
public class WeeklyEmailBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final WeeklyEmailSubscriptionRepositoryPort subscriptions;
    private final UserRepositoryPort users;
    private final WeeklyEmailMailerPort mailer;
    private final GetDashboardUseCase dashboard;
    private final DashboardReadPort reads;
    private final ZoneId zone;
    private final Clock clock;

    public WeeklyEmailBeanConfiguration(TransactionalUseCaseFactory tx,
                                        WeeklyEmailSubscriptionRepositoryPort subscriptions,
                                        UserRepositoryPort users, WeeklyEmailMailerPort mailer,
                                        GetDashboardUseCase dashboard, DashboardReadPort reads,
                                        @Value("${synaptixfit.planner.zone:Europe/Madrid}") String zoneId,
                                        Clock clock) {
        this.tx = tx;
        this.subscriptions = subscriptions;
        this.users = users;
        this.mailer = mailer;
        this.dashboard = dashboard;
        this.reads = reads;
        this.zone = ZoneId.of(zoneId);
        this.clock = clock;
    }

    @Bean(autowireCandidate = false)
    WeeklyEmailService weeklyEmailService() {
        return new WeeklyEmailService(subscriptions, users, mailer, dashboard, reads, zone, clock);
    }

    @Bean
    GetWeeklyEmailStatusUseCase getWeeklyEmailStatusUseCase() {
        return tx.wrap(GetWeeklyEmailStatusUseCase.class, weeklyEmailService());
    }

    @Bean
    EnableWeeklyEmailUseCase enableWeeklyEmailUseCase() {
        return tx.wrap(EnableWeeklyEmailUseCase.class, weeklyEmailService());
    }

    @Bean
    DisableWeeklyEmailUseCase disableWeeklyEmailUseCase() {
        return tx.wrap(DisableWeeklyEmailUseCase.class, weeklyEmailService());
    }

    @Bean
    ConfirmWeeklyEmailUseCase confirmWeeklyEmailUseCase() {
        return tx.wrap(ConfirmWeeklyEmailUseCase.class, weeklyEmailService());
    }

    @Bean
    UnsubscribeWeeklyEmailUseCase unsubscribeWeeklyEmailUseCase() {
        return tx.wrap(UnsubscribeWeeklyEmailUseCase.class, weeklyEmailService());
    }

    /**
     * Sin transacción que lo envuelva: recorre a todos los suscritos llamando a Resend, y cada usuario se guarda
     * por su cuenta (el panel se lee con su propio caso de uso). Así un fallo con uno no deshace a los demás ni
     * retiene una conexión de la BD durante todo el envío.
     */
    @Bean
    SendWeeklySummariesUseCase sendWeeklySummariesUseCase() {
        // Envoltorio y no el servicio: el servicio también implementa los otros contratos y se inyectaría por ellos.
        WeeklyEmailService service = weeklyEmailService();
        return new SendWeeklySummariesUseCase() {
            @Override
            public int sendWeeklySummaries() {
                return service.sendWeeklySummaries();
            }

            @Override
            public int lastFailures() {
                return service.lastFailures();
            }
        };
    }
}
