package com.synaptixfit.infrastructure.adapter.output.external.mail;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.notification.WeeklySummary;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Correo del resumen semanal: solo lo que la persona usa, con baja con un clic y títulos escapados. */
class WeeklyEmailTextsTest {

    private static final String UNSUBSCRIBE = "https://app.example/api/v1/notifications/weekly-email/unsubscribe?token=t";

    private static WeeklySummary summary(boolean academic, boolean fitness) {
        return new WeeklySummary(LocalDate.of(2026, 10, 26), 150, 2, 3, 3, 4, 5,
                List.of(new WeeklySummary.Upcoming("<b>Parcial</b>", Instant.parse("2026-11-03T09:00:00Z"), true)),
                academic, fitness);
    }

    @Test
    void itTalksOnlyAboutWhatThePersonUses() {
        ResendEmailClient.Message study = WeeklyEmailTexts.summary("a@example.com", "es", summary(true, false),
                "https://app.example", UNSUBSCRIBE, ZoneId.of("Europe/Madrid"));
        ResendEmailClient.Message training = WeeklyEmailTexts.summary("a@example.com", "es", summary(false, true),
                "https://app.example", UNSUBSCRIBE, ZoneId.of("Europe/Madrid"));

        assertThat(study.text()).contains("Estudio: 2 h 30 min", "Racha: 5 días", "Examen")
                .doesNotContain("Entrenamientos");
        assertThat(training.text()).contains("Entrenamientos: 2 de 3").doesNotContain("Estudio", "próximos 7 días");
    }

    @Test
    void oneClickUnsubscribeAndEscapedTitles() {
        ResendEmailClient.Message m = WeeklyEmailTexts.summary("a@example.com", "fr", summary(true, true),
                "https://app.example", UNSUBSCRIBE, ZoneId.of("Europe/Madrid"));

        assertThat(m.headers()).containsEntry("List-Unsubscribe", "<" + UNSUBSCRIBE + ">")
                .containsEntry("List-Unsubscribe-Post", "List-Unsubscribe=One-Click");
        assertThat(m.html()).contains("lang=\"fr\"", "&lt;b&gt;Parcial&lt;/b&gt;").doesNotContain("<b>Parcial</b>");
        assertThat(m.subject()).isEqualTo("Ta semaine sur SynaptixFit");
    }
}
