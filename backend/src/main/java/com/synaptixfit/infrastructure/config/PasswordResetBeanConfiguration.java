package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.auth.RequestPasswordResetUseCase;
import com.synaptixfit.application.port.input.auth.ResetPasswordUseCase;
import com.synaptixfit.application.service.auth.PasswordResetService;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import com.synaptixfit.domain.port.output.auth.PasswordResetMailerPort;
import com.synaptixfit.domain.port.output.auth.PasswordResetTokenRepositoryPort;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de «recuperar la contraseña» por correo (ADR 0021). */
@Configuration
public class PasswordResetBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final UserRepositoryPort users;
    private final PasswordResetTokenRepositoryPort resets;
    private final PasswordResetMailerPort mailer;
    private final PasswordHasherPort passwordHasher;
    private final RefreshTokenRepositoryPort refreshTokens;
    private final Clock clock;

    public PasswordResetBeanConfiguration(TransactionalUseCaseFactory tx, UserRepositoryPort users,
                                          PasswordResetTokenRepositoryPort resets, PasswordResetMailerPort mailer,
                                          PasswordHasherPort passwordHasher, RefreshTokenRepositoryPort refreshTokens,
                                          Clock clock) {
        this.tx = tx;
        this.users = users;
        this.resets = resets;
        this.mailer = mailer;
        this.passwordHasher = passwordHasher;
        this.refreshTokens = refreshTokens;
        this.clock = clock;
    }

    @Bean(autowireCandidate = false)
    PasswordResetService passwordResetService() {
        return new PasswordResetService(users, resets, mailer, passwordHasher, refreshTokens, clock);
    }

    @Bean
    RequestPasswordResetUseCase requestPasswordResetUseCase() {
        return tx.wrap(RequestPasswordResetUseCase.class, passwordResetService());
    }

    @Bean
    ResetPasswordUseCase resetPasswordUseCase() {
        return tx.wrap(ResetPasswordUseCase.class, passwordResetService());
    }
}
