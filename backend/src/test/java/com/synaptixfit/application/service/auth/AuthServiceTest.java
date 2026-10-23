package com.synaptixfit.application.service.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.auth.AuthSession;
import com.synaptixfit.application.port.input.auth.LoginUseCase;
import com.synaptixfit.application.port.input.auth.RegisterUserUseCase;
import com.synaptixfit.domain.exception.auth.EmailAlreadyRegisteredException;
import com.synaptixfit.domain.exception.auth.InvalidCredentialsException;
import com.synaptixfit.domain.exception.auth.InvalidRefreshTokenException;
import com.synaptixfit.domain.exception.auth.WeakPasswordException;
import com.synaptixfit.domain.model.auth.AccessToken;
import com.synaptixfit.domain.model.auth.GoogleIdentity;
import com.synaptixfit.domain.model.auth.RefreshToken;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Pruebas del servicio con dobles en memoria de los puertos (sin Spring). */
class AuthServiceTest {

    private final Map<UUID, User> userStore = new HashMap<>();
    private final Map<String, RefreshToken> tokenStore = new HashMap<>();
    private final java.util.List<com.synaptixfit.domain.event.DomainEvent> published = new java.util.ArrayList<>();
    private boolean lockdown;
    private AuthService service;

    @BeforeEach
    void setUp() {
        UserRepositoryPort users = new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return Optional.ofNullable(userStore.get(id)); }
            public Optional<User> findByEmail(String e) {
                return userStore.values().stream().filter(u -> u.email().equals(e)).findFirst();
            }
            public Optional<User> findByGoogleSubject(String s) {
                return userStore.values().stream().filter(u -> s.equals(u.googleSubject())).findFirst();
            }
            public boolean existsByEmail(String e) { return findByEmail(e).isPresent(); }
            public User save(User u) { userStore.put(u.id(), u); return u; }
        };
        RefreshTokenRepositoryPort tokens = new RefreshTokenRepositoryPort() {
            public RefreshToken save(RefreshToken t) { tokenStore.put(t.tokenHash(), t); return t; }
            public Optional<RefreshToken> findByHash(String h) { return Optional.ofNullable(tokenStore.get(h)); }
            public void revokeAllForUser(UUID userId, Instant when) {
                tokenStore.values().stream().filter(t -> t.userId().equals(userId)).forEach(t -> t.revoke(when));
            }
        };
        Clock clock = Clock.fixed(Instant.parse("2026-10-01T10:00:00Z"), ZoneOffset.UTC);
        service = new AuthService(users,
                new com.synaptixfit.domain.port.output.auth.PasswordHasherPort() {
                    public String hash(com.synaptixfit.domain.model.auth.Password p) { return "h:" + p.value(); }
                    public boolean matches(String raw, String hash) { return ("h:" + raw).equals(hash); }
                },
                user -> new AccessToken("access-" + user.id(), clock.instant().plusSeconds(900)),
                tokens,
                idToken -> new GoogleIdentity("sub-1", "g@example.com", true, "Gina", null),
                () -> lockdown,
                published::add,
                clock, Duration.ofDays(30));
    }

    @Test
    void registerCreatesUserAndSession() {
        AuthSession session = service.register(new RegisterUserUseCase.Command("New@Example.com", "secret123", "Nuevo"));
        assertThat(session.user().email()).isEqualTo("new@example.com");
        assertThat(session.refreshToken()).isNotBlank();
        assertThat(session.user().shadowbanned()).isFalse();
        assertThat(published).hasSize(1);
    }

    @Test
    void registerDuringLockdownShadowbans() {
        lockdown = true;
        AuthSession session = service.register(new RegisterUserUseCase.Command("x@example.com", "secret123", "Equis"));
        assertThat(session.user().shadowbanned()).isTrue();
    }

    @Test
    void registerRejectsDuplicatesAndWeakPasswords() {
        service.register(new RegisterUserUseCase.Command("a@example.com", "secret123", "Ana"));
        assertThatThrownBy(() -> service.register(new RegisterUserUseCase.Command("A@example.com", "secret123", "Ana")))
                .isInstanceOf(EmailAlreadyRegisteredException.class);
        assertThatThrownBy(() -> service.register(new RegisterUserUseCase.Command("b@example.com", "short", "Bea")))
                .isInstanceOf(WeakPasswordException.class);
    }

    @Test
    void loginChecksPassword() {
        service.register(new RegisterUserUseCase.Command("a@example.com", "secret123", "Ana"));
        assertThat(service.login(new LoginUseCase.Command("a@example.com", "secret123")).accessToken()).isNotBlank();
        assertThatThrownBy(() -> service.login(new LoginUseCase.Command("a@example.com", "wrong1234")))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void refreshRotatesAndDetectsReuse() {
        AuthSession first = service.register(new RegisterUserUseCase.Command("a@example.com", "secret123", "Ana"));
        AuthSession second = service.refresh(first.refreshToken());
        assertThat(second.refreshToken()).isNotEqualTo(first.refreshToken());
        // Reutilizar el token ya rotado invalida también el nuevo.
        assertThatThrownBy(() -> service.refresh(first.refreshToken())).isInstanceOf(InvalidRefreshTokenException.class);
        assertThatThrownBy(() -> service.refresh(second.refreshToken())).isInstanceOf(InvalidRefreshTokenException.class);
    }

    @Test
    void googleLoginLinksExistingAccountByEmail() {
        AuthSession registered = service.register(new RegisterUserUseCase.Command("g@example.com", "secret123", "Gina"));
        AuthSession google = service.loginWithGoogle("token");
        assertThat(google.user().id()).isEqualTo(registered.user().id());
        assertThat(google.user().googleSubject()).isEqualTo("sub-1");
    }
}
