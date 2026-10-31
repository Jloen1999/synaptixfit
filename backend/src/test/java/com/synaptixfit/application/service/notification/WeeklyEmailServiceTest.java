package com.synaptixfit.application.service.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.dashboard.GetDashboardUseCase;
import com.synaptixfit.application.port.input.notification.WeeklyEmailStatus;
import com.synaptixfit.domain.exception.notification.WeeklyEmailLinkInvalidException;
import com.synaptixfit.domain.model.dashboard.Dashboard;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels;
import com.synaptixfit.domain.model.notification.WeeklyEmailSubscription;
import com.synaptixfit.domain.model.notification.WeeklySummary;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailMailerPort;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailSubscriptionRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Resumen semanal por correo con dobles en memoria (sin Spring ni correo real). */
class WeeklyEmailServiceTest {

    /** Domingo 1 de noviembre de 2026, 19:00 en Madrid. */
    private static final Instant SUNDAY = Instant.parse("2026-11-01T18:00:00Z");
    private static final LocalDate MONDAY = LocalDate.of(2026, 10, 26);

    private final Map<UUID, WeeklyEmailSubscription> store = new HashMap<>();
    private final Map<UUID, User> users = new HashMap<>();
    private final List<String> confirmations = new ArrayList<>();
    private final List<WeeklySummary> summaries = new ArrayList<>();
    private final GetDashboardUseCase dashboard = mock(GetDashboardUseCase.class);
    private final DashboardReadPort reads = mock(DashboardReadPort.class);
    private boolean providerAccepts = true;
    private WeeklyEmailService service;

    @BeforeEach
    void setUp() {
        WeeklyEmailSubscriptionRepositoryPort repo = new WeeklyEmailSubscriptionRepositoryPort() {
            public WeeklyEmailSubscription save(WeeklyEmailSubscription s) { store.put(s.userId(), s); return s; }
            public Optional<WeeklyEmailSubscription> findByUser(UUID id) { return Optional.ofNullable(store.get(id)); }
            public Optional<WeeklyEmailSubscription> findByConfirmTokenHash(String h) {
                return store.values().stream().filter(s -> h.equals(s.confirmTokenHash())).findFirst();
            }
            public Optional<WeeklyEmailSubscription> findByUnsubscribeToken(String t) {
                return store.values().stream().filter(s -> t.equals(s.unsubscribeToken())).findFirst();
            }
            public List<WeeklyEmailSubscription> findActive() {
                return store.values().stream().filter(WeeklyEmailSubscription::isActive).toList();
            }
            public void deleteByUser(UUID id) { store.remove(id); }
            public void markSent(UUID id, LocalDate week, Instant now) {
                WeeklyEmailSubscription s = store.get(id);
                if (s != null && s.isActive()) {
                    s.markSent(week, now);
                }
            }
        };
        UserRepositoryPort userRepo = new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return Optional.ofNullable(users.get(id)); }
            public Optional<User> findByEmail(String e) { return Optional.empty(); }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return false; }
            public User save(User u) { users.put(u.id(), u); return u; }
        };
        WeeklyEmailMailerPort mailer = new WeeklyEmailMailerPort() {
            public void sendConfirmation(String email, String language, String token) { confirmations.add(token); }
            public boolean sendSummary(String email, String language, WeeklySummary s, String unsubscribe,
                                       String idempotencyKey) {
                if (providerAccepts) {
                    summaries.add(s);
                }
                return providerAccepts;
            }
        };
        service = new WeeklyEmailService(repo, userRepo, mailer, dashboard, reads, ZoneId.of("Europe/Madrid"),
                Clock.fixed(SUNDAY, ZoneOffset.UTC));
        when(reads.deadlines(any(), any(), any())).thenReturn(List.of(
                new DashboardReadModels.Deadline(UUID.randomUUID(), "Parcial", "examen",
                        SUNDAY.plusSeconds(86_400), false, "Cálculo")));
        Dashboard d = mock(Dashboard.class);
        when(d.week()).thenReturn(new Dashboard.WeekKpis(MONDAY, 2, 3, 1, 90, 400, 150));
        when(d.planWeek()).thenReturn(List.of(new Dashboard.PlanDay(MONDAY, 4, 3)));
        when(d.greeting()).thenReturn(new Dashboard.Greeting("Ana", null, 2, 10, 100, 4));
        when(dashboard.getDashboard(any(), anyString())).thenReturn(d);
    }

    private User user(String googleSubject) {
        User u = User.builder().id(UUID.randomUUID()).email("ana@example.com").fullName("Ana")
                .googleSubject(googleSubject).passwordHash(googleSubject == null ? "h" : null)
                .createdAt(SUNDAY).build();
        users.put(u.id(), u);
        return u;
    }

    @Test
    void anUnverifiedEmailMustConfirmBeforeGettingSummaries() {
        User ana = user(null);

        assertThat(service.enableWeeklyEmail(ana.id(), "fr")).isEqualTo(WeeklyEmailStatus.PENDING);
        assertThat(service.sendWeeklySummaries()).isZero();
        assertThat(service.confirmWeeklyEmail(confirmations.getFirst())).isEqualTo("fr");
        assertThat(service.getWeeklyEmailStatus(ana.id())).isEqualTo(WeeklyEmailStatus.ACTIVE);
        assertThatThrownBy(() -> service.confirmWeeklyEmail(confirmations.getFirst()))
                .isInstanceOf(WeeklyEmailLinkInvalidException.class);
    }

    @Test
    void pressingAgainRightAwayDoesNotSendAnotherConfirmation() {
        User ana = user(null);

        service.enableWeeklyEmail(ana.id(), "es");
        assertThat(service.enableWeeklyEmail(ana.id(), "es")).isEqualTo(WeeklyEmailStatus.PENDING);
        assertThat(confirmations).hasSize(1);
        assertThat(service.confirmWeeklyEmail(confirmations.getFirst())).isEqualTo("es");
    }

    @Test
    void aGoogleAccountIsActiveRightAway() {
        User eva = user("google-sub");

        assertThat(service.enableWeeklyEmail(eva.id(), "es")).isEqualTo(WeeklyEmailStatus.ACTIVE);
        assertThat(confirmations).isEmpty();
    }

    @Test
    void theSummaryGoesOncePerWeekWithTheWeekFiguresAndWhatComesNext() {
        User eva = user("google-sub");
        service.enableWeeklyEmail(eva.id(), "es");

        assertThat(service.sendWeeklySummaries()).isEqualTo(1);
        assertThat(service.sendWeeklySummaries()).isZero();
        WeeklySummary s = summaries.getFirst();
        assertThat(s.weekStart()).isEqualTo(MONDAY);
        assertThat(s.studyMinutes()).isEqualTo(150);
        assertThat(s.trainingSessions()).isEqualTo(2);
        assertThat(s.blocksCompleted()).isEqualTo(3);
        assertThat(s.upcoming()).singleElement().satisfies(u -> assertThat(u.exam()).isTrue());
    }

    @Test
    void ifTheProviderFailsItIsRetriedNextTime() {
        User eva = user("google-sub");
        service.enableWeeklyEmail(eva.id(), "es");
        providerAccepts = false;

        assertThat(service.sendWeeklySummaries()).isZero();
        providerAccepts = true;
        assertThat(service.sendWeeklySummaries()).isEqualTo(1);
    }

    @Test
    void theUnsubscribeLinkTurnsItOff() {
        User eva = user("google-sub");
        service.enableWeeklyEmail(eva.id(), "pt");

        assertThat(service.unsubscribeWeeklyEmail(store.get(eva.id()).unsubscribeToken())).isEqualTo("pt");
        assertThat(service.getWeeklyEmailStatus(eva.id())).isEqualTo(WeeklyEmailStatus.OFF);
        assertThatThrownBy(() -> service.unsubscribeWeeklyEmail("otro"))
                .isInstanceOf(WeeklyEmailLinkInvalidException.class);
    }
}
