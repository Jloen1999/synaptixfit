package com.synaptixfit.application.service.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.auth.ResetPasswordUseCase;
import com.synaptixfit.domain.exception.auth.PasswordResetTokenInvalidException;
import com.synaptixfit.domain.exception.auth.WeakPasswordException;
import com.synaptixfit.domain.model.auth.Password;
import com.synaptixfit.domain.model.auth.PasswordResetToken;
import com.synaptixfit.domain.model.auth.RefreshToken;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import com.synaptixfit.domain.port.output.auth.PasswordResetTokenRepositoryPort;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Recuperar la contraseña con dobles en memoria de los puertos (sin Spring ni correo real). */
class PasswordResetServiceTest {

    private static final Instant START = Instant.parse("2026-10-31T10:00:00Z");

    private final Map<UUID, User> userStore = new HashMap<>();
    private final Map<UUID, PasswordResetToken> resetStore = new HashMap<>();
    private final Map<String, RefreshToken> sessionStore = new HashMap<>();
    /** Tokens en claro «enviados» por correo. */
    private final List<String> sent = new ArrayList<>();
    private Instant now = START;
    private PasswordResetService service;
    private User ana;

    @BeforeEach
    void setUp() {
        UserRepositoryPort users = new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return Optional.ofNullable(userStore.get(id)); }
            public Optional<User> findByEmail(String e) {
                return userStore.values().stream().filter(u -> u.email().equals(e)).findFirst();
            }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return findByEmail(e).isPresent(); }
            public User save(User u) { userStore.put(u.id(), u); return u; }
        };
        PasswordResetTokenRepositoryPort resets = new PasswordResetTokenRepositoryPort() {
            public PasswordResetToken save(PasswordResetToken t) { resetStore.put(t.id(), t); return t; }
            public Optional<PasswordResetToken> findByHash(String h) {
                return resetStore.values().stream().filter(t -> t.tokenHash().equals(h)).findFirst();
            }
            public int countCreatedSince(UUID userId, Instant since) {
                return (int) resetStore.values().stream()
                        .filter(t -> t.userId().equals(userId) && t.createdAt().isAfter(since)).count();
            }
            public void invalidateAllForUser(UUID userId, Instant when) {
                resetStore.values().stream().filter(t -> t.userId().equals(userId)).forEach(t -> t.markUsed(when));
            }
        };
        RefreshTokenRepositoryPort sessions = new RefreshTokenRepositoryPort() {
            public RefreshToken save(RefreshToken t) { sessionStore.put(t.tokenHash(), t); return t; }
            public Optional<RefreshToken> findByHash(String h) { return Optional.ofNullable(sessionStore.get(h)); }
            public void revokeAllForUser(UUID userId, Instant when) {
                sessionStore.values().stream().filter(t -> t.userId().equals(userId)).forEach(t -> t.revoke(when));
            }
        };
        PasswordHasherPort hasher = new PasswordHasherPort() {
            public String hash(Password p) { return "h:" + p.value(); }
            public boolean matches(String raw, String hash) { return ("h:" + raw).equals(hash); }
        };
        Clock clock = new Clock() {
            public ZoneId getZone() { return ZoneId.of("UTC"); }
            public Clock withZone(ZoneId zone) { return this; }
            public Instant instant() { return now; }
        };
        service = new PasswordResetService(users, resets, (email, token, expires) -> sent.add(token),
                hasher, sessions, clock);
        ana = users.save(User.builder().id(UUID.randomUUID()).email("ana@example.com").fullName("Ana")
                .passwordHash("h:vieja123").createdAt(START).build());
        sessions.save(new RefreshToken(UUID.randomUUID(), ana.id(), "sesion", START.plus(Duration.ofDays(30)), null));
    }

    @Test
    void theLinkChangesThePasswordOnceAndClosesEverySession() {
        service.requestPasswordReset("  ANA@example.com ");
        assertThat(sent).hasSize(1);

        service.resetPassword(new ResetPasswordUseCase.Command(sent.getFirst(), "nueva1234"));

        assertThat(userStore.get(ana.id()).passwordHash()).isEqualTo("h:nueva1234");
        assertThat(sessionStore.get("sesion").revokedAt()).isEqualTo(START);
        assertThatThrownBy(() -> service.resetPassword(new ResetPasswordUseCase.Command(sent.getFirst(), "otra12345")))
                .isInstanceOf(PasswordResetTokenInvalidException.class);
    }

    @Test
    void unknownOrDeletedAccountsGetNoEmailAndNoError() {
        service.requestPasswordReset("nadie@example.com");
        userStore.put(ana.id(), User.builder().id(ana.id()).email(ana.email()).fullName("Ana")
                .createdAt(START).deletedAt(START).build());
        service.requestPasswordReset("ana@example.com");

        assertThat(sent).isEmpty();
    }

    @Test
    void onlyTheLatestLinkWorksAndAtMostThreePerHour() {
        for (int i = 0; i < 5; i++) {
            now = START.plus(Duration.ofMinutes(i));
            service.requestPasswordReset("ana@example.com");
        }
        assertThat(sent).hasSize(PasswordResetToken.MAX_PER_HOUR);
        assertThatThrownBy(() -> service.resetPassword(new ResetPasswordUseCase.Command(sent.getFirst(), "nueva1234")))
                .isInstanceOf(PasswordResetTokenInvalidException.class);

        now = START.plus(Duration.ofMinutes(61));
        service.requestPasswordReset("ana@example.com");
        assertThat(sent).hasSize(PasswordResetToken.MAX_PER_HOUR + 1);
    }

    @Test
    void anExpiredLinkFailsAndAWeakPasswordDoesNotSpendIt() {
        service.requestPasswordReset("ana@example.com");
        String token = sent.getFirst();

        assertThatThrownBy(() -> service.resetPassword(new ResetPasswordUseCase.Command(token, "corta")))
                .isInstanceOf(WeakPasswordException.class);
        now = START.plus(PasswordResetToken.TTL).plusSeconds(1);
        assertThatThrownBy(() -> service.resetPassword(new ResetPasswordUseCase.Command(token, "nueva1234")))
                .isInstanceOf(PasswordResetTokenInvalidException.class);
        assertThat(userStore.get(ana.id()).passwordHash()).isEqualTo("h:vieja123");
    }
}
