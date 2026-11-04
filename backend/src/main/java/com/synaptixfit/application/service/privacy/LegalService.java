package com.synaptixfit.application.service.privacy;

import com.synaptixfit.application.port.input.privacy.AcceptLegalTermsUseCase;
import com.synaptixfit.application.port.input.privacy.GetLegalAcceptanceUseCase;
import com.synaptixfit.application.port.input.privacy.GetLegalDocumentUseCase;
import com.synaptixfit.domain.exception.privacy.LegalDocumentNotFoundException;
import com.synaptixfit.domain.exception.privacy.LegalVersionOutdatedException;
import com.synaptixfit.domain.model.privacy.LegalAcceptance;
import com.synaptixfit.domain.model.privacy.LegalContact;
import com.synaptixfit.domain.model.privacy.LegalDocument;
import com.synaptixfit.domain.model.privacy.LegalDocumentKind;
import com.synaptixfit.domain.model.privacy.LegalTerms;
import com.synaptixfit.domain.port.output.privacy.LegalAcceptanceRepositoryPort;
import com.synaptixfit.domain.port.output.privacy.LegalTextPort;
import java.time.Clock;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

/**
 * Textos legales y su aceptación (ADR 0034). Lee el texto con {@link LegalTextPort}, lo completa con el
 * responsable y el correo de la configuración ({@link LegalContact}) y guarda las aceptaciones con
 * {@link LegalAcceptanceRepositoryPort}.
 */
public class LegalService implements GetLegalDocumentUseCase, GetLegalAcceptanceUseCase, AcceptLegalTermsUseCase {

    static final String DEFAULT_LANGUAGE = "es";

    private final LegalTextPort texts;
    private final LegalAcceptanceRepositoryPort acceptances;
    private final LegalContact contact;
    private final String appUrl;
    private final Clock clock;

    public LegalService(LegalTextPort texts, LegalAcceptanceRepositoryPort acceptances, LegalContact contact,
                        String appUrl, Clock clock) {
        this.texts = texts;
        this.acceptances = acceptances;
        this.contact = contact;
        this.appUrl = appUrl;
        this.clock = clock;
    }

    @Override
    public LegalDocument getLegalDocument(String slug, String language) {
        LegalDocumentKind kind = LegalDocumentKind.fromSlug(slug)
                .orElseThrow(() -> new LegalDocumentNotFoundException(slug));
        String wanted = normalize(language);
        // Sin traducción a ese idioma, el texto en español: es la versión de referencia.
        Optional<String> translated = texts.load(kind, wanted);
        String used = translated.isPresent() ? wanted : DEFAULT_LANGUAGE;
        String source = translated.or(() -> texts.load(kind, DEFAULT_LANGUAGE))
                .orElseThrow(() -> new LegalDocumentNotFoundException(slug));
        return LegalDocument.compose(kind, used, source, contact, appUrl);
    }

    @Override
    public Status getLegalAcceptance(UUID userId) {
        Optional<LegalAcceptance> latest = acceptances.latest(userId);
        String accepted = latest.map(LegalAcceptance::version).orElse(null);
        return new Status(LegalTerms.CURRENT_VERSION, accepted, latest.map(LegalAcceptance::acceptedAt).orElse(null),
                LegalTerms.acceptanceRequired(accepted));
    }

    @Override
    public void acceptLegalTerms(UUID userId, String version) {
        if (!LegalTerms.CURRENT_VERSION.equals(version)) {
            throw new LegalVersionOutdatedException();
        }
        acceptances.save(new LegalAcceptance(userId, version, clock.instant()));
    }

    private static String normalize(String language) {
        if (language == null || language.isBlank()) {
            return DEFAULT_LANGUAGE;
        }
        // «pt-BR», «en_US»… → «pt», «en».
        return language.trim().toLowerCase(Locale.ROOT).split("[-_]")[0];
    }
}
