package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.application.port.input.notification.SendWeeklySummariesUseCase;
import com.synaptixfit.domain.model.notification.WeeklySummary;
import com.synaptixfit.domain.port.output.notification.WeeklyEmailMailerPort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Resumen semanal por correo de punta a punta (V980, páginas públicas, envío sin duplicados). El correo se
 * sustituye por un doble que captura los tokens.
 */
@SpringBootTest
@AutoConfigureMockMvc
class WeeklyEmailIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private SendWeeklySummariesUseCase sendWeeklySummaries;

    @MockitoBean
    private WeeklyEmailMailerPort mailer;

    @Test
    void confirmReceiveOnceAndUnsubscribe() throws Exception {
        String email = "weekly-" + UUID.randomUUID() + "@example.com";
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Ana\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String auth = "Bearer " + JsonPath.read(body, "$.accessToken");
        Instant later = Instant.now().truncatedTo(ChronoUnit.HOURS).plus(Duration.ofHours(2));
        mvc.perform(post("/api/v1/planner/blocks").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"start\":\"%s\",\"end\":\"%s\",\"type\":\"STUDY\",\"topics\":\"Repaso\"}"
                                .formatted(later, later.plus(Duration.ofHours(1)))))
                .andExpect(status().isCreated());

        mvc.perform(put("/api/v1/notifications/weekly-email").header("Authorization", auth)
                        .header("Accept-Language", "fr"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PENDING"));
        ArgumentCaptor<String> confirmToken = ArgumentCaptor.forClass(String.class);
        verify(mailer).sendConfirmation(eq(email), eq("fr"), confirmToken.capture());
        assertThat(sendWeeklySummaries.sendWeeklySummaries()).isZero();

        // Sin sesión, como desde el correo; la página sale en el idioma de la suscripción.
        mvc.perform(get("/api/v1/notifications/weekly-email/confirm").param("token", confirmToken.getValue()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("method=\"post\"")));
        mvc.perform(get("/api/v1/notifications/weekly-email").header("Authorization", auth))
                .andExpect(jsonPath("$.status").value("PENDING"));
        mvc.perform(post("/api/v1/notifications/weekly-email/confirm").param("token", confirmToken.getValue()))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(containsString("Résumé hebdomadaire activé")));
        mvc.perform(get("/api/v1/notifications/weekly-email").header("Authorization", auth))
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        when(mailer.sendSummary(anyString(), anyString(), any(), anyString(), anyString())).thenReturn(true);
        sendWeeklySummaries.sendWeeklySummaries();
        sendWeeklySummaries.sendWeeklySummaries();
        ArgumentCaptor<String> unsubscribe = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<WeeklySummary> summary = ArgumentCaptor.forClass(WeeklySummary.class);
        verify(mailer, times(1)).sendSummary(eq(email), eq("fr"), summary.capture(), unsubscribe.capture(),
                anyString());
        assertThat(summary.getValue().blocksPlanned()).isPositive();

        // Baja con un clic (POST, como hacen los clientes de correo) y el enlace ya no sirve.
        mvc.perform(post("/api/v1/notifications/weekly-email/unsubscribe").param("token", unsubscribe.getValue()))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("désabonné")));
        mvc.perform(get("/api/v1/notifications/weekly-email").header("Authorization", auth))
                .andExpect(jsonPath("$.status").value("OFF"));
        // Idempotente: pedir la baja otra vez muestra lo mismo.
        mvc.perform(post("/api/v1/notifications/weekly-email/unsubscribe").param("token", unsubscribe.getValue()))
                .andExpect(status().isOk());
    }

    @Test
    void onlyTheEmailLinksArePublic() throws Exception {
        mvc.perform(get("/api/v1/notifications/weekly-email")).andExpect(status().isUnauthorized());
        mvc.perform(put("/api/v1/notifications/weekly-email")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/notifications/weekly-email/confirm").param("token", "nope"))
                .andExpect(status().isNotFound());
    }
}
