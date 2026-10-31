package com.synaptixfit.application.service.auth;

import com.synaptixfit.application.port.input.auth.RequestPasswordResetUseCase;
import com.synaptixfit.application.port.input.auth.ResetPasswordUseCase;
import com.synaptixfit.domain.exception.auth.PasswordResetTokenInvalidException;
import com.synaptixfit.domain.model.auth.Password;
import com.synaptixfit.domain.model.auth.PasswordResetToken;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import com.synaptixfit.domain.port.output.auth.PasswordResetMailerPort;
import com.synaptixfit.domain.port.output.auth.PasswordResetTokenRepositoryPort;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;

/**
 * Recuperar la contraseña por correo: pide el enlace ({@link RequestPasswordResetUseCase}) y pone la nueva
 * ({@link ResetPasswordUseCase}). Envía con {@link PasswordResetMailerPort} y guarda solo la huella del token.
 *
 * <p>Las cuentas solo de Google también pueden usarlo: así se ponen una contraseña.
 */
public class PasswordResetService implements RequestPasswordResetUseCase, ResetPasswordUseCase {

    private final UserRepositoryPort users;
    private final PasswordResetTokenRepositoryPort resets;
    private final PasswordResetMailerPort mailer;
    private final PasswordHasherPort passwordHasher;
    private final RefreshTokenRepositoryPort refreshTokens;
    private final Clock clock;

    public PasswordResetService(UserRepositoryPort users, PasswordResetTokenRepositoryPort resets,
                                PasswordResetMailerPort mailer, PasswordHasherPort passwordHasher,
                                RefreshTokenRepositoryPort refreshTokens, Clock clock) {
        this.users = users;
        this.resets = resets;
        this.mailer = mailer;
        this.passwordHasher = passwordHasher;
        this.refreshTokens = refreshTokens;
        this.clock = clock;
    }

    @Override
    public void requestPasswordReset(String email) {
        if (email == null || email.isBlank()) {
            return;
        }
        Instant now = clock.instant();
        users.findByEmail(User.normalizeEmail(email))
                .filter(User::isActive)
                .filter(user -> resets.countCreatedSince(user.id(), now.minus(Duration.ofHours(1)))
                        < PasswordResetToken.MAX_PER_HOUR)
                .ifPresent(user -> {
                    resets.invalidateAllForUser(user.id(), now);
                    PasswordResetToken.Issued issued = PasswordResetToken.issue(user.id(), now);
                    resets.save(issued.token());
                    mailer.sendPasswordReset(user.email(), issued.rawToken(), issued.token().expiresAt());
                });
    }

    @Override
    public void resetPassword(ResetPasswordUseCase.Command command) {
        // La contraseña se valida antes de gastar el enlace: si es débil, el enlace sigue sirviendo.
        Password password = new Password(command.newPassword());
        if (command.token() == null || command.token().isBlank()) {
            throw new PasswordResetTokenInvalidException();
        }
        Instant now = clock.instant();
        PasswordResetToken token = resets.findByHash(PasswordResetToken.hash(command.token()))
                .filter(t -> t.isUsableAt(now))
                .orElseThrow(PasswordResetTokenInvalidException::new);
        User user = users.findById(token.userId())
                .filter(User::isActive)
                .orElseThrow(PasswordResetTokenInvalidException::new);
        user.changePasswordHash(passwordHasher.hash(password));
        users.save(user);
        token.markUsed(now);
        resets.save(token);
        resets.invalidateAllForUser(user.id(), now);
        // Quien pidió el enlace puede no ser quien tiene la sesión abierta: se cierran todas.
        refreshTokens.revokeAllForUser(user.id(), now);
    }
}
