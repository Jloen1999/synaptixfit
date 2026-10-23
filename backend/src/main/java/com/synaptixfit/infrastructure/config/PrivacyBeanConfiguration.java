package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.privacy.DeleteMyAccountUseCase;
import com.synaptixfit.application.port.input.privacy.ExportMyDataUseCase;
import com.synaptixfit.application.service.privacy.PrivacyService;
import com.synaptixfit.application.service.privacy.UserDataEraser;
import com.synaptixfit.domain.port.output.admin.AdminAuditPort;
import com.synaptixfit.domain.port.output.admin.AdminUserQueryPort;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.privacy.UserDataErasurePort;
import com.synaptixfit.domain.port.output.privacy.UserDataExportPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Raíz de composición del RGPD: el procedimiento de borrado compartido con el panel y el
 * autoservicio del usuario (exportar y darse de baja).
 */
@Configuration
public class PrivacyBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final UserRepositoryPort users;
    private final PasswordHasherPort passwordHasher;
    private final AdminUserQueryPort userQueries;
    private final AdminAuditPort audit;
    private final UserDataErasurePort erasure;
    private final UserDataExportPort exporter;
    private final FileStoragePort storage;
    private final DomainEventPublisherPort events;
    private final Clock clock;

    public PrivacyBeanConfiguration(TransactionalUseCaseFactory tx, UserRepositoryPort users,
                                    PasswordHasherPort passwordHasher, AdminUserQueryPort userQueries,
                                    AdminAuditPort audit, UserDataErasurePort erasure, UserDataExportPort exporter,
                                    FileStoragePort storage, DomainEventPublisherPort events, Clock clock) {
        this.tx = tx;
        this.users = users;
        this.passwordHasher = passwordHasher;
        this.userQueries = userQueries;
        this.audit = audit;
        this.erasure = erasure;
        this.exporter = exporter;
        this.storage = storage;
        this.events = events;
        this.clock = clock;
    }

    /**
     * Procedimiento interno (no es un caso de uso): solo lo usan los servicios del panel y del
     * autoservicio, que ya se ejecutan dentro de su transacción.
     */
    @Bean
    UserDataEraser userDataEraser() {
        return new UserDataEraser(erasure, storage, events, clock);
    }

    @Bean(autowireCandidate = false)
    PrivacyService privacyService() {
        return new PrivacyService(users, passwordHasher, userQueries, userDataEraser(), exporter, audit, clock);
    }

    @Bean
    ExportMyDataUseCase exportMyDataUseCase() {
        return tx.wrap(ExportMyDataUseCase.class, privacyService());
    }

    @Bean
    DeleteMyAccountUseCase deleteMyAccountUseCase() {
        return tx.wrap(DeleteMyAccountUseCase.class, privacyService());
    }
}
