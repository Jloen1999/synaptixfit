package com.synaptixfit.infrastructure.adapter.input.rest.privacy;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.privacy.LegalContact;
import com.synaptixfit.domain.model.privacy.LegalDocument;
import com.synaptixfit.domain.model.privacy.LegalDocumentKind;
import org.junit.jupiter.api.Test;

/** La página pública escapa el texto y los datos de entorno: nada de ellos puede inyectar HTML (ADR 0034). */
class LegalHtmlPageTest {

    @Test
    void contactAndTextAreEscaped() {
        String source = """
                # Política
                Responsable: {{RESPONSABLE}}. Correo: {{CORREO}}.
                - <img src=x onerror=alert(1)> "comillas"
                """;
        LegalDocument doc = LegalDocument.compose(LegalDocumentKind.PRIVACY, "es", source,
                new LegalContact("<script>x</script>", "a\"@b.com"), "https://synaptixfit.jloenit.dev");

        String html = LegalHtmlPage.render(doc);

        assertThat(html).doesNotContain("<script").doesNotContain("<img").doesNotContain("a\"@b.com");
        assertThat(html).contains("&lt;script&gt;x&lt;/script&gt;").contains("&lt;img src=x");
    }

    @Test
    void notFoundPageIsPlainHtml() {
        assertThat(LegalHtmlPage.notFound("en")).contains("Page not found").contains("/privacidad?lang=en");
        assertThat(LegalHtmlPage.notFound(null)).contains("Página no encontrada");
    }
}
