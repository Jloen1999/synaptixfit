package com.synaptixfit.domain.model.privacy;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

/** Composición de los textos legales: marcadores rellenos, «pendiente» sin configuración y bloques (ADR 0034). */
class LegalDocumentTest {

    private static final String SOURCE = """
            # Política

            Responsable: {{RESPONSABLE}}. Correo {{CORREO}}.
            Segunda línea del mismo párrafo.

            ## Derechos
            - Borra en {{APP_URL}}/eliminar-cuenta
            - Versión {{VERSION}}
            """;

    @Test
    void fillsMarkersAndSplitsBlocks() {
        LegalDocument doc = LegalDocument.compose(LegalDocumentKind.PRIVACY, "es", SOURCE,
                new LegalContact("Ana Pérez", "privacidad@example.com"), "https://app.example.com/");

        assertThat(doc.title()).isEqualTo("Política");
        assertThat(doc.contactConfigured()).isTrue();
        assertThat(doc.blocks()).extracting(LegalBlock::type).containsExactly(LegalBlock.Type.PARAGRAPH,
                LegalBlock.Type.HEADING, LegalBlock.Type.BULLET, LegalBlock.Type.BULLET);
        assertThat(doc.blocks().get(0).text())
                .isEqualTo("Responsable: Ana Pérez. Correo privacidad@example.com. Segunda línea del mismo párrafo.");
        assertThat(doc.blocks().get(2).text()).isEqualTo("Borra en https://app.example.com/eliminar-cuenta");
        assertThat(doc.blocks().get(3).text()).isEqualTo("Versión " + LegalTerms.CURRENT_VERSION);
    }

    @Test
    void writesPendingInsteadOfInventingTheContact() {
        LegalDocument es = LegalDocument.compose(LegalDocumentKind.PRIVACY, "es", SOURCE,
                new LegalContact(" ", null), "");
        LegalDocument en = LegalDocument.compose(LegalDocumentKind.PRIVACY, "en", SOURCE,
                new LegalContact(null, null), "");

        assertThat(es.contactConfigured()).isFalse();
        assertThat(es.blocks().get(0).text()).contains("(pendiente de indicar)").doesNotContain("{{");
        assertThat(en.blocks().get(0).text()).contains("(to be provided)");
        // Sin dirección pública, la frase que la cita se quita entera en vez de quedar rota.
        assertThat(es.blocks()).extracting(LegalBlock::text).noneMatch(t -> t.contains("eliminar-cuenta"));
        assertThat(es.blocks()).extracting(LegalBlock::text).contains("Versión " + LegalTerms.CURRENT_VERSION);
    }

    @Test
    void acceptanceIsRequiredUntilTheCurrentVersionIsAccepted() {
        assertThat(LegalTerms.acceptanceRequired(null)).isTrue();
        assertThat(LegalTerms.acceptanceRequired("2000-01-01")).isTrue();
        assertThat(LegalTerms.acceptanceRequired(LegalTerms.CURRENT_VERSION)).isFalse();
    }

    @Test
    void findsKindsByUrlName() {
        assertThat(LegalDocumentKind.fromSlug("account-deletion")).contains(LegalDocumentKind.ACCOUNT_DELETION);
        assertThat(LegalDocumentKind.fromSlug("../etc")).isEmpty();
    }
}
