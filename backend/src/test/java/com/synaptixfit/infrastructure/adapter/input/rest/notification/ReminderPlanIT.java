package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * {@code GET /api/v1/notifications/reminder-plan} sobre la aplicación completa y PostgreSQL real: lee
 * bloques del planificador y preferencias y aplica el modo y la validación de la ventana.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ReminderPlanIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String token;
    private Instant tomorrow;

    @BeforeEach
    void register() throws Exception {
        String email = "reminders-" + UUID.randomUUID() + "@example.com";
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Reme\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        token = JsonPath.read(body, "$.accessToken");
        tomorrow = Instant.now().truncatedTo(ChronoUnit.DAYS).plus(Duration.ofDays(1)).plus(Duration.ofHours(10));
    }

    private MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON);
    }

    private void createBlock(String type, Instant start, String topics) throws Exception {
        mvc.perform(auth(post("/api/v1/planner/blocks")).content("""
                        {"start":"%s","end":"%s","type":"%s","topics":"%s"}
                        """.formatted(start, start.plus(Duration.ofHours(1)), type, topics)))
                .andExpect(status().isCreated());
    }

    /** Avisos de bloques (sin «Tu semana», que depende del día de la semana). */
    private static final String BLOCKS = "$.reminders[?(@.kind != 'WEEKLY_SUMMARY')]";

    @Test
    void plansBlocksAndAppliesModeAndWindow() throws Exception {
        createBlock("SPORT", tomorrow, "Pierna");
        createBlock("STUDY", tomorrow.plus(Duration.ofHours(2)), "Matrices");
        createBlock("CLASS", tomorrow.plus(Duration.ofHours(4)), "Teoría");

        // Preferencias por defecto (sin silencio, 10 al día) y enfoque «ambos»; sin repasos vencidos.
        mvc.perform(auth(get("/api/v1/notifications/reminder-plan")))
                .andExpect(status().isOk())
                // «Tu semana» (domingo) entra o no según el día en que se ejecute: se miran los bloques.
                .andExpect(jsonPath(BLOCKS + ".kind", contains("TRAINING", "STUDY")))
                .andExpect(jsonPath(BLOCKS + ".title", contains("Pierna", "Matrices")))
                .andExpect(jsonPath(BLOCKS + ".startsAt", hasItem(tomorrow.toString())))
                .andExpect(jsonPath(BLOCKS + ".at", hasItem(tomorrow.minus(Duration.ofMinutes(15)).toString())));

        // Modo exámenes: solo lo académico.
        mvc.perform(auth(put("/api/v1/notifications/preferences")).content("""
                        {"activeCategories":["ACADEMIC","MILESTONE"],"dailyLimit":10,"mode":"EXAMS"}
                        """))
                .andExpect(status().isOk());
        mvc.perform(auth(get("/api/v1/notifications/reminder-plan").param("days", "2")))
                .andExpect(status().isOk())
                .andExpect(jsonPath(BLOCKS + ".kind", contains("STUDY")));

        // Límite diario 0: solo pasarían las críticas, y un recordatorio no lo es.
        mvc.perform(auth(put("/api/v1/notifications/preferences")).content("""
                        {"activeCategories":["ACADEMIC","MILESTONE"],"dailyLimit":0,"mode":"NORMAL"}
                        """))
                .andExpect(status().isOk());
        mvc.perform(auth(get("/api/v1/notifications/reminder-plan")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reminders.length()").value(0));

        mvc.perform(auth(get("/api/v1/notifications/reminder-plan").param("days", "8")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void requiresAuthentication() throws Exception {
        mvc.perform(get("/api/v1/notifications/reminder-plan")).andExpect(status().isUnauthorized());
    }
}
