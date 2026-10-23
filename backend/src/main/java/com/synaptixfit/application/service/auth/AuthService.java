package com.synaptixfit.application.service.auth;

import com.synaptixfit.application.port.input.auth.AuthSession;
import com.synaptixfit.application.port.input.auth.ChangePasswordUseCase;
import com.synaptixfit.application.port.input.auth.LoginUseCase;
import com.synaptixfit.application.port.input.auth.LoginWithGoogleUseCase;
import com.synaptixfit.application.port.input.auth.LogoutUseCase;
import com.synaptixfit.application.port.input.auth.RefreshSessionUseCase;
import com.synaptixfit.application.port.input.auth.RegisterUserUseCase;
import com.synaptixfit.domain.exception.auth.AccountDisabledException;
import com.synaptixfit.domain.exception.auth.EmailAlreadyRegisteredException;
import com.synaptixfit.domain.exception.auth.InvalidCredentialsException;
import com.synaptixfit.domain.exception.auth.InvalidGoogleTokenException;
import com.synaptixfit.domain.exception.auth.InvalidRefreshTokenException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.event.user.UserRegistered;
import com.synaptixfit.domain.model.auth.AccessToken;
import com.synaptixfit.domain.model.auth.GoogleIdentity;
import com.synaptixfit.domain.model.auth.Password;
import com.synaptixfit.domain.model.auth.RefreshToken;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.auth.AccessTokenIssuerPort;
import com.synaptixfit.domain.port.output.auth.GoogleIdentityVerifierPort;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.platform.PlatformSettingsPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

/**
 * Autenticación propia: email y contraseña, Google y sesiones con token de refresco rotatorio.
 *
 * <p>El token de refresco se entrega una sola vez en claro; en base de datos solo queda su hash
 * SHA-256. Cada refresco revoca el token usado y emite uno nuevo.
 */
public class AuthService implements RegisterUserUseCase, LoginUseCase, LoginWithGoogleUseCase,
        RefreshSessionUseCase, LogoutUseCase, ChangePasswordUseCase {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepositoryPort users;
    private final PasswordHasherPort passwordHasher;
    private final AccessTokenIssuerPort accessTokens;
    private final RefreshTokenRepositoryPort refreshTokens;
    private final GoogleIdentityVerifierPort googleVerifier;
    private final PlatformSettingsPort platformSettings;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final Duration refreshTokenTtl;

    public AuthService(UserRepositoryPort users, PasswordHasherPort passwordHasher,
                       AccessTokenIssuerPort accessTokens, RefreshTokenRepositoryPort refreshTokens,
                       GoogleIdentityVerifierPort googleVerifier, PlatformSettingsPort platformSettings,
                       DomainEventPublisherPort events, Clock clock, Duration refreshTokenTtl) {
        this.users = users;
        this.passwordHasher = passwordHasher;
        this.accessTokens = accessTokens;
        this.refreshTokens = refreshTokens;
        this.googleVerifier = googleVerifier;
        this.platformSettings = platformSettings;
        this.events = events;
        this.clock = clock;
        this.refreshTokenTtl = refreshTokenTtl;
    }

    @Override
    public AuthSession register(RegisterUserUseCase.Command command) {
        String email = User.normalizeEmail(command.email());
        Password password = new Password(command.password());
        if (users.existsByEmail(email)) {
            throw new EmailAlreadyRegisteredException();
        }
        User user = User.builder()
                .id(UUID.randomUUID())
                .email(email)
                .fullName(command.fullName())
                .passwordHash(passwordHasher.hash(password))
                .shadowbanned(platformSettings.isLockdownActive())
                .createdAt(clock.instant())
                .build();
        return openSession(registered(users.save(user)));
    }

    @Override
    public AuthSession login(LoginUseCase.Command command) {
        String email = User.normalizeEmail(command.email());
        User user = users.findByEmail(email)
                .filter(User::hasPassword)
                .orElseThrow(InvalidCredentialsException::new);
        if (!passwordHasher.matches(command.password(), user.passwordHash())) {
            throw new InvalidCredentialsException();
        }
        ensureActive(user);
        return openSession(user);
    }

    @Override
    public AuthSession loginWithGoogle(String idToken) {
        GoogleIdentity identity = googleVerifier.verify(idToken);
        if (!identity.emailVerified() || identity.email() == null) {
            throw new InvalidGoogleTokenException();
        }
        User user = users.findByGoogleSubject(identity.subject())
                .or(() -> users.findByEmail(User.normalizeEmail(identity.email())).map(existing -> {
                    existing.linkGoogle(identity.subject());
                    if (existing.avatarUrl() == null) {
                        existing.changeAvatar(identity.pictureUrl());
                    }
                    return users.save(existing);
                }))
                .orElseGet(() -> registered(users.save(User.builder()
                        .id(UUID.randomUUID())
                        .email(identity.email())
                        .fullName(displayName(identity))
                        .avatarUrl(identity.pictureUrl())
                        .googleSubject(identity.subject())
                        .shadowbanned(platformSettings.isLockdownActive())
                        .createdAt(clock.instant())
                        .build())));
        ensureActive(user);
        return openSession(user);
    }

    @Override
    public AuthSession refresh(String refreshToken) {
        Instant now = clock.instant();
        RefreshToken stored = refreshTokens.findByHash(hash(refreshToken))
                .orElseThrow(InvalidRefreshTokenException::new);
        if (!stored.isUsableAt(now)) {
            if (stored.revokedAt() != null) {
                // Reutilizar un token revocado indica robo: se cierran todas las sesiones.
                refreshTokens.revokeAllForUser(stored.userId(), now);
            }
            throw new InvalidRefreshTokenException();
        }
        stored.revoke(now);
        refreshTokens.save(stored);
        User user = users.findById(stored.userId()).orElseThrow(InvalidRefreshTokenException::new);
        ensureActive(user);
        return openSession(user);
    }

    @Override
    public void logout(String refreshToken) {
        refreshTokens.findByHash(hash(refreshToken)).ifPresent(token -> {
            token.revoke(clock.instant());
            refreshTokens.save(token);
        });
    }

    @Override
    public void changePassword(ChangePasswordUseCase.Command command) {
        User user = users.findById(command.userId())
                .orElseThrow(() -> new UserNotFoundException(command.userId()));
        if (user.hasPassword() && (command.currentPassword() == null
                || !passwordHasher.matches(command.currentPassword(), user.passwordHash()))) {
            throw new InvalidCredentialsException();
        }
        user.changePasswordHash(passwordHasher.hash(new Password(command.newPassword())));
        users.save(user);
        refreshTokens.revokeAllForUser(user.id(), clock.instant());
    }

    private AuthSession openSession(User user) {
        AccessToken access = accessTokens.issue(user);
        String rawRefresh = newRandomToken();
        Instant now = clock.instant();
        refreshTokens.save(new RefreshToken(UUID.randomUUID(), user.id(), hash(rawRefresh),
                now.plus(refreshTokenTtl), null));
        return new AuthSession(user, access.value(), access.expiresAt(), rawRefresh);
    }

    private User registered(User user) {
        events.publish(new UserRegistered(user.id(), clock.instant()));
        return user;
    }

    private static void ensureActive(User user) {
        if (!user.isActive()) {
            throw new AccountDisabledException();
        }
    }

    private static String displayName(GoogleIdentity identity) {
        String name = identity.fullName();
        if (name != null && name.strip().length() >= 2) {
            return name.strip();
        }
        String local = identity.email().substring(0, identity.email().indexOf('@'));
        return local.length() >= 2 ? local : "Usuario";
    }

    private static String newRandomToken() {
        byte[] bytes = new byte[48];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    static String hash(String token) {
        if (token == null) {
            throw new InvalidRefreshTokenException();
        }
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
