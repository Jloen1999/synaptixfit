package com.synaptixfit.infrastructure.adapter.output.external.mail;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

/** Texto del correo para restablecer la contraseña. */
class PasswordResetEmailTest {

    private static final String LINK = "https://app.example/#/reset-password?token=abc_-123";

    @Test
    void itIsWrittenInTheLanguageOfTheRequestWithTheLinkAndTheExpiry() {
        ResendEmailClient.Message es = PasswordResetEmail.compose("ana@example.com", LINK, 30, "es");
        ResendEmailClient.Message fr = PasswordResetEmail.compose("ana@example.com", LINK, 30, "fr");
        ResendEmailClient.Message other = PasswordResetEmail.compose("ana@example.com", LINK, 30, "de");

        assertThat(es.subject()).isEqualTo("Restablece tu contraseña de SynaptixFit");
        assertThat(es.text()).contains("Hola:", LINK, "30 minutos");
        assertThat(es.html()).contains("href=\"" + LINK + "\"", "lang=\"es\"", "background:#ffffff");
        assertThat(fr.subject()).contains("mot de passe");
        assertThat(fr.html()).contains("lang=\"fr\"");
        assertThat(other.subject()).isEqualTo(es.subject());
        assertThat(other.html()).contains("lang=\"es\"");
    }

    @Test
    void theContentNeverAppearsInLogs() {
        ResendEmailClient.Message m = PasswordResetEmail.compose("x@example.com", LINK, 30, "es");

        assertThat(m.toString()).doesNotContain(LINK).doesNotContain("x@example.com");
    }
}
