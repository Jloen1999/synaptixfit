package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.auth.ChangePasswordUseCase;
import com.synaptixfit.application.port.input.auth.LoginUseCase;
import com.synaptixfit.application.port.input.auth.LoginWithGoogleUseCase;
import com.synaptixfit.application.port.input.auth.LogoutUseCase;
import com.synaptixfit.application.port.input.auth.RefreshSessionUseCase;
import com.synaptixfit.application.port.input.auth.RegisterUserUseCase;
import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.port.input.user.GetCurrentUserUseCase;
import com.synaptixfit.application.port.input.user.UpdateAccountUseCase;
import com.synaptixfit.application.service.auth.AuthService;
import com.synaptixfit.application.service.gamification.ExperienceService;
import com.synaptixfit.application.service.user.AccountService;
import com.synaptixfit.domain.port.output.auth.AccessTokenIssuerPort;
import com.synaptixfit.domain.port.output.auth.GoogleIdentityVerifierPort;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.platform.PlatformSettingsPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Raíz de composición del núcleo (autenticación, cuenta y experiencia).
 *
 * <p>Patrón común a todas las {@code <Feature>BeanConfiguration} de este paquete:
 * <ol>
 *   <li>Los puertos de salida llegan por el constructor de la configuración.</li>
 *   <li>El servicio se declara con {@code autowireCandidate = false}: existe una sola instancia,
 *       pero nadie puede inyectarlo directamente.</li>
 *   <li>Cada contrato de caso de uso es un bean propio, envuelto en una transacción con
 *       {@link TransactionalUseCaseFactory}. Es lo único que ven los controllers y otros servicios.</li>
 * </ol>
 */
@Configuration
public class BeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final UserRepositoryPort users;
    private final PasswordHasherPort passwordHasher;
    private final AccessTokenIssuerPort accessTokens;
    private final RefreshTokenRepositoryPort refreshTokens;
    private final GoogleIdentityVerifierPort googleVerifier;
    private final PlatformSettingsPort platformSettings;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final AppProperties properties;

    public BeanConfiguration(TransactionalUseCaseFactory tx, UserRepositoryPort users,
                             PasswordHasherPort passwordHasher, AccessTokenIssuerPort accessTokens,
                             RefreshTokenRepositoryPort refreshTokens, GoogleIdentityVerifierPort googleVerifier,
                             PlatformSettingsPort platformSettings, DomainEventPublisherPort events,
                             Clock clock, AppProperties properties) {
        this.tx = tx;
        this.users = users;
        this.passwordHasher = passwordHasher;
        this.accessTokens = accessTokens;
        this.refreshTokens = refreshTokens;
        this.googleVerifier = googleVerifier;
        this.platformSettings = platformSettings;
        this.events = events;
        this.clock = clock;
        this.properties = properties;
    }

    // ---------------------------------------------------------------- auth

    @Bean(autowireCandidate = false)
    AuthService authService() {
        return new AuthService(users, passwordHasher, accessTokens, refreshTokens, googleVerifier,
                platformSettings, events, clock, properties.jwt().refreshTokenTtl());
    }

    @Bean
    RegisterUserUseCase registerUserUseCase() {
        return tx.wrap(RegisterUserUseCase.class, authService());
    }

    @Bean
    LoginUseCase loginUseCase() {
        return tx.wrap(LoginUseCase.class, authService());
    }

    @Bean
    LoginWithGoogleUseCase loginWithGoogleUseCase() {
        return tx.wrap(LoginWithGoogleUseCase.class, authService());
    }

    @Bean
    RefreshSessionUseCase refreshSessionUseCase() {
        return tx.wrap(RefreshSessionUseCase.class, authService());
    }

    @Bean
    LogoutUseCase logoutUseCase() {
        return tx.wrap(LogoutUseCase.class, authService());
    }

    @Bean
    ChangePasswordUseCase changePasswordUseCase() {
        return tx.wrap(ChangePasswordUseCase.class, authService());
    }

    // ---------------------------------------------------------------- cuenta

    @Bean(autowireCandidate = false)
    AccountService accountService() {
        return new AccountService(users, events, clock);
    }

    @Bean
    GetCurrentUserUseCase getCurrentUserUseCase() {
        return tx.wrap(GetCurrentUserUseCase.class, accountService());
    }

    @Bean
    UpdateAccountUseCase updateAccountUseCase() {
        return tx.wrap(UpdateAccountUseCase.class, accountService());
    }

    // ---------------------------------------------------------------- experiencia

    @Bean(autowireCandidate = false)
    ExperienceService experienceService() {
        return new ExperienceService(users, events, clock);
    }

    @Bean
    AwardExperienceUseCase awardExperienceUseCase() {
        return tx.wrap(AwardExperienceUseCase.class, experienceService());
    }

    @Bean
    RevokeExperienceUseCase revokeExperienceUseCase() {
        return tx.wrap(RevokeExperienceUseCase.class, experienceService());
    }
}
