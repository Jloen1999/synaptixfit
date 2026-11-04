package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.privacy.AcceptLegalTermsUseCase;
import com.synaptixfit.application.port.input.privacy.GetLegalAcceptanceUseCase;
import com.synaptixfit.application.port.input.privacy.GetLegalDocumentUseCase;
import com.synaptixfit.application.service.privacy.LegalService;
import com.synaptixfit.domain.model.privacy.LegalContact;
import com.synaptixfit.domain.port.output.privacy.LegalAcceptanceRepositoryPort;
import com.synaptixfit.domain.port.output.privacy.LegalTextPort;
import java.time.Clock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Raíz de composición de los textos legales (ADR 0034). El responsable y el correo de privacidad salen de
 * {@code LEGAL_CONTROLLER_NAME} y {@code LEGAL_CONTACT_EMAIL}: nunca se escriben en el código.
 */
@Configuration
public class LegalBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final LegalTextPort texts;
    private final LegalAcceptanceRepositoryPort acceptances;
    private final Clock clock;
    private final LegalContact contact;
    private final String appUrl;

    public LegalBeanConfiguration(TransactionalUseCaseFactory tx, LegalTextPort texts,
                                  LegalAcceptanceRepositoryPort acceptances, Clock clock,
                                  @Value("${synaptixfit.legal.controller-name:}") String controllerName,
                                  @Value("${synaptixfit.legal.contact-email:}") String contactEmail,
                                  @Value("${synaptixfit.mail.app-url:}") String appUrl) {
        this.tx = tx;
        this.texts = texts;
        this.acceptances = acceptances;
        this.clock = clock;
        this.contact = new LegalContact(controllerName, contactEmail);
        this.appUrl = appUrl;
    }

    @Bean(autowireCandidate = false)
    LegalService legalService() {
        return new LegalService(texts, acceptances, contact, appUrl, clock);
    }

    @Bean
    GetLegalDocumentUseCase getLegalDocumentUseCase() {
        return tx.wrap(GetLegalDocumentUseCase.class, legalService());
    }

    @Bean
    GetLegalAcceptanceUseCase getLegalAcceptanceUseCase() {
        return tx.wrap(GetLegalAcceptanceUseCase.class, legalService());
    }

    @Bean
    AcceptLegalTermsUseCase acceptLegalTermsUseCase() {
        return tx.wrap(AcceptLegalTermsUseCase.class, legalService());
    }
}
