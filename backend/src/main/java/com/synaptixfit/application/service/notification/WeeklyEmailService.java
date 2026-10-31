package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.dashboard.GetDashboardUseCase;
import com.synaptixfit.application.port.input.notification.ConfirmWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.DisableWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.EnableWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.GetWeeklyEmailStatusUseCase;
import com.synaptixfit.application.port.input.notification.SendWeeklySummariesUseCase;
import com.synaptixfit.application.port.input.notification.UnsubscribeWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.WeeklyEmailStatus;
import com.synaptixfit.domain.exception.notification.WeeklyEmailLinkInvalidException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.dashboard.Dashboard;
import com.synaptixfit.domain.model.insights.TimeZones;
import com.synaptixfit.domain.model.notification.WeeklyEmailSubscription;
import com.synaptixfit.domain.model.notification.WeeklySummary;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailMailerPort;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailSubscriptionRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

/**
 * Resumen semanal por correo (ADR 0022): suscribirse con doble confirmación, darse de baja y el envío del
 * domingo. Las cifras de la semana salen de {@link GetDashboardUseCase} (las mismas que ve en Inicio) y las
 * fechas próximas de {@link DashboardReadPort}; el correo lo compone {@link WeeklyEmailMailerPort}.
 */
public class WeeklyEmailService implements GetWeeklyEmailStatusUseCase, EnableWeeklyEmailUseCase,
        DisableWeeklyEmailUseCase, ConfirmWeeklyEmailUseCase, UnsubscribeWeeklyEmailUseCase,
        SendWeeklySummariesUseCase {

    /** Entregas y exámenes que se citan como «lo que viene». */
    static final int MAX_UPCOMING = 5;

    private final WeeklyEmailSubscriptionRepositoryPort subscriptions;
    private final UserRepositoryPort users;
    private final WeeklyEmailMailerPort mailer;
    private final GetDashboardUseCase dashboard;
    private final DashboardReadPort reads;
    private final ZoneId zone;
    private final Clock clock;

    /** Personas con las que falló el último envío (para el registro del programador). */
    private int failures;

    public WeeklyEmailService(WeeklyEmailSubscriptionRepositoryPort subscriptions, UserRepositoryPort users,
                              WeeklyEmailMailerPort mailer, GetDashboardUseCase dashboard, DashboardReadPort reads,
                              ZoneId zone, Clock clock) {
        this.subscriptions = subscriptions;
        this.users = users;
        this.mailer = mailer;
        this.dashboard = dashboard;
        this.reads = reads;
        this.zone = zone;
        this.clock = clock;
    }

    @Override
    public WeeklyEmailStatus getWeeklyEmailStatus(UUID userId) {
        return subscriptions.findByUser(userId)
                .map(s -> s.isActive() ? WeeklyEmailStatus.ACTIVE : WeeklyEmailStatus.PENDING)
                .orElse(WeeklyEmailStatus.OFF);
    }

    @Override
    public WeeklyEmailStatus enableWeeklyEmail(UUID userId, String language) {
        Instant now = clock.instant();
        var existing = subscriptions.findByUser(userId);
        if (existing.isPresent() && existing.get().isActive()) {
            WeeklyEmailSubscription active = existing.get();
            active.changeLanguage(language, now);
            subscriptions.save(active);
            return WeeklyEmailStatus.ACTIVE;
        }
        // Pendiente con un correo de confirmación reciente: no se manda otro (ni cambian los enlaces).
        if (existing.isPresent() && !existing.get().canResendConfirmation(now)) {
            return WeeklyEmailStatus.PENDING;
        }
        User user = users.findById(userId).orElseThrow(() -> new UserNotFoundException(userId));
        // Google ya verificó el correo; si no, hay que demostrar que el buzón es de quien se suscribe.
        WeeklyEmailSubscription.Started started = WeeklyEmailSubscription.start(userId, language,
                user.googleSubject() != null, now);
        subscriptions.save(started.subscription());
        if (started.confirmToken() != null) {
            mailer.sendConfirmation(user.email(), language, started.confirmToken());
            return WeeklyEmailStatus.PENDING;
        }
        return WeeklyEmailStatus.ACTIVE;
    }

    @Override
    public void disableWeeklyEmail(UUID userId) {
        subscriptions.deleteByUser(userId);
    }

    @Override
    public String confirmWeeklyEmail(String token) {
        if (token == null || token.isBlank()) {
            throw new WeeklyEmailLinkInvalidException();
        }
        WeeklyEmailSubscription subscription = subscriptions
                .findByConfirmTokenHash(WeeklyEmailSubscription.hash(token))
                .filter(s -> s.confirmationValidAt(clock.instant()))
                .orElseThrow(WeeklyEmailLinkInvalidException::new);
        subscription.confirm(clock.instant());
        subscriptions.save(subscription);
        return subscription.language();
    }

    @Override
    public String unsubscribeWeeklyEmail(String token) {
        if (token == null || token.isBlank()) {
            throw new WeeklyEmailLinkInvalidException();
        }
        WeeklyEmailSubscription subscription = subscriptions.findByUnsubscribeToken(token)
                .orElseThrow(WeeklyEmailLinkInvalidException::new);
        subscriptions.deleteByUser(subscription.userId());
        return subscription.language();
    }

    @Override
    public int sendWeeklySummaries() {
        Instant now = clock.instant();
        LocalDate monday = TimeZones.weekStart(LocalDate.ofInstant(now, zone));
        failures = 0;
        int sent = 0;
        for (WeeklyEmailSubscription listed : subscriptions.findActive()) {
            // Un fallo con una persona no deja sin resumen a las demás.
            try {
                if (sendOne(listed.userId(), monday, now)) {
                    sent++;
                }
            } catch (RuntimeException e) {
                failures++;
            }
        }
        return sent;
    }

    @Override
    public int lastFailures() {
        return failures;
    }

    private boolean sendOne(UUID userId, LocalDate monday, Instant now) {
        // Se vuelve a leer: si se dio de baja mientras sale el envío, ya no está.
        WeeklyEmailSubscription subscription = subscriptions.findByUser(userId)
                .filter(WeeklyEmailSubscription::isActive).orElse(null);
        if (subscription == null || subscription.wasSentFor(monday)) {
            return false;
        }
        User user = users.findById(userId).filter(User::isActive).orElse(null);
        if (user == null) {
            return false;
        }
        WeeklySummary summary = summarize(user, monday, now);
        // Una semana sin nada que contar no merece un correo (y no cuenta como enviado).
        if (summary.isEmpty()) {
            return false;
        }
        if (!mailer.sendSummary(user.email(), subscription.language(), summary, subscription.unsubscribeToken(),
                "weekly/" + userId + "/" + monday)) {
            return false;
        }
        subscriptions.markSent(userId, monday, now);
        return true;
    }

    private WeeklySummary summarize(User user, LocalDate monday, Instant now) {
        UUID userId = user.id();
        // Sin enfoque elegido todavía, como en el resto de la app: estudio y deporte.
        UsageFocus focus = user.usageFocus() == null ? UsageFocus.BOTH : user.usageFocus();
        Dashboard d = dashboard.getDashboard(userId, zone.getId());
        int planned = d.planWeek().stream().mapToInt(Dashboard.PlanDay::planned).sum();
        int completed = d.planWeek().stream().mapToInt(Dashboard.PlanDay::completed).sum();
        List<WeeklySummary.Upcoming> upcoming = reads.deadlines(userId, now, now.plus(Duration.ofDays(7))).stream()
                .filter(dl -> !dl.completed())
                .limit(MAX_UPCOMING)
                .map(dl -> new WeeklySummary.Upcoming(dl.title(), dl.dueAt(), "examen".equals(dl.type())))
                .toList();
        return new WeeklySummary(monday, d.week().studyMinutesCompleted(), d.week().sessions(),
                d.week().plannedSessions(), completed, planned, d.greeting().streak(),
                focus.includesAcademic() ? upcoming : List.of(), focus.includesAcademic(),
                focus.includesFitness());
    }
}
