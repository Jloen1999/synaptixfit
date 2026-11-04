package com.synaptixfit.application.service.privacy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.privacy.LegalDocumentNotFoundException;
import com.synaptixfit.domain.exception.privacy.LegalVersionOutdatedException;
import com.synaptixfit.domain.model.privacy.LegalAcceptance;
import com.synaptixfit.domain.model.privacy.LegalContact;
import com.synaptixfit.domain.model.privacy.LegalDocument;
import com.synaptixfit.domain.model.privacy.LegalDocumentKind;
import com.synaptixfit.domain.model.privacy.LegalTerms;
import com.synaptixfit.domain.port.output.privacy.LegalAcceptanceRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** {@link LegalService} con dobles: idioma de reserva, aceptación vigente y versión antigua. */
class LegalServiceTest {

    private static final Instant NOW = Instant.parse("2026-11-04T10:00:00Z");
    private final UUID user = UUID.randomUUID();
    private final FakeAcceptances acceptances = new FakeAcceptances();
    private final LegalService service = new LegalService(
            (kind, language) -> "es".equals(language) || "en".equals(language)
                    ? Optional.of("# " + kind.slug() + "-" + language + "\n\nTexto.")
                    : Optional.empty(),
            acceptances, new LegalContact("Responsable", "c@example.com"), "https://app.example.com",
            Clock.fixed(NOW, ZoneOffset.UTC));

    @Test
    void servesTheRequestedLanguageOrFallsBackToSpanish() {
        LegalDocument en = service.getLegalDocument("privacy", "en-GB");
        LegalDocument pt = service.getLegalDocument("terms", "pt");

        assertThat(en.language()).isEqualTo("en");
        assertThat(en.title()).isEqualTo("privacy-en");
        assertThat(pt.language()).isEqualTo("es");
        assertThat(pt.kind()).isEqualTo(LegalDocumentKind.TERMS);
    }

    @Test
    void unknownDocumentIsNotFound() {
        assertThatThrownBy(() -> service.getLegalDocument("cookies", "es"))
                .isInstanceOf(LegalDocumentNotFoundException.class);
    }

    @Test
    void acceptingTheCurrentVersionStopsAskingForIt() {
        assertThat(service.getLegalAcceptance(user).required()).isTrue();

        service.acceptLegalTerms(user, LegalTerms.CURRENT_VERSION);

        var status = service.getLegalAcceptance(user);
        assertThat(status.required()).isFalse();
        assertThat(status.acceptedVersion()).isEqualTo(LegalTerms.CURRENT_VERSION);
        assertThat(status.acceptedAt()).isEqualTo(NOW);
    }

    @Test
    void anOldVersionCannotBeAccepted() {
        assertThatThrownBy(() -> service.acceptLegalTerms(user, "2000-01-01"))
                .isInstanceOf(LegalVersionOutdatedException.class);
        assertThat(acceptances.saved).isEmpty();
    }

    private static final class FakeAcceptances implements LegalAcceptanceRepositoryPort {
        private final List<LegalAcceptance> saved = new ArrayList<>();

        @Override
        public Optional<LegalAcceptance> latest(UUID userId) {
            return saved.stream().filter(a -> a.userId().equals(userId))
                    .max(Comparator.comparing(LegalAcceptance::acceptedAt));
        }

        @Override
        public void save(LegalAcceptance acceptance) {
            saved.add(acceptance);
        }
    }
}
