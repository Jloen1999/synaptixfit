package com.synaptixfit.infrastructure.adapter.input.rest.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
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
 * Bienestar sobre PostgreSQL real (V1040–V1042): seguimiento del ciclo con consentimiento, registro rápido y su
 * explicación, carrera apuntada a mano con ritmo en el historial, opciones de avisos y exportación RGPD.
 */
@SpringBootTest
@AutoConfigureMockMvc
class WellbeingFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Ana\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private String body(MockHttpServletRequestBuilder b, String token, int expected) throws Exception {
        return mvc.perform(b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().is(expected)).andReturn().getResponse().getContentAsString();
    }

    @Test
    void cicloRegistroRapidoActividadYAvisos() throws Exception {
        String token = register("wellbeing1@example.com");
        String other = register("wellbeing2@example.com");
        String today = LocalDate.now(ZoneId.of("Europe/Madrid")).toString();

        // Ciclo: apagado por defecto, sin consentimiento no se activa y sin activar no se apunta.
        assertThat((Boolean) JsonPath.read(body(get("/api/v1/training/cycle"), token, 200), "$.enabled")).isFalse();
        String noConsent = body(put("/api/v1/training/cycle/settings").content("{\"enabled\":true}"), token, 422);
        assertThat((String) JsonPath.read(noConsent, "$.code")).isEqualTo("CYCLE_CONSENT_REQUIRED");
        String off = body(put("/api/v1/training/cycle/days/" + today).content("{\"period\":true}"), token, 409);
        assertThat((String) JsonPath.read(off, "$.code")).isEqualTo("CYCLE_TRACKING_OFF");

        body(put("/api/v1/training/cycle/settings").content("{\"enabled\":true,\"consent\":true}"), token, 200);
        String logged = body(put("/api/v1/training/cycle/days/" + today)
                .content("{\"period\":true,\"energy\":\"LOW\",\"symptoms\":[\"CRAMPS\",\"HEADACHE\"]}"), token, 200);
        assertThat((String) JsonPath.read(logged, "$.phase")).isEqualTo("PERIOD");
        assertThat((List<?>) JsonPath.read(logged, "$.today.symptoms")).hasSize(2);
        String days = body(get("/api/v1/training/cycle/days").param("from", today).param("to", today), token, 200);
        assertThat((List<?>) JsonPath.read(days, "$.days")).hasSize(1);
        // Otra persona no ve nada.
        String foreign = body(get("/api/v1/training/cycle/days").param("from", today).param("to", today), other, 200);
        assertThat((List<?>) JsonPath.read(foreign, "$.days")).isEmpty();

        // Registro rápido (sin estrés) y la explicación de hoy: dormir mal + ciclo con molestias. Antes hace falta
        // el consentimiento expreso para datos de salud (ADR 0034), aparte de la política.
        String refused = body(put("/api/v1/training/check-ins/today")
                .content("{\"sleepQuality\":1,\"energy\":1,\"soreness\":4}"), token, 422);
        assertThat((String) JsonPath.read(refused, "$.code")).isEqualTo("HEALTH_CONSENT_REQUIRED");
        body(put("/api/v1/me/health-consent"), token, 204);
        assertThat((Boolean) JsonPath.read(body(get("/api/v1/me/health-consent"), token, 200), "$.given")).isTrue();
        body(put("/api/v1/training/check-ins/today")
                .content("{\"sleepQuality\":1,\"energy\":1,\"soreness\":4}"), token, 200);
        String adaptation = body(get("/api/v1/training/adaptation/today").param("tz", "Europe/Madrid"), token, 200);
        assertThat((Boolean) JsonPath.read(adaptation, "$.checkInDone")).isTrue();
        assertThat((List<String>) JsonPath.read(adaptation, "$.reasons"))
                .contains("HIGH_FATIGUE", "CYCLE_DISCOMFORT");
        assertThat((String) JsonPath.read(adaptation, "$.fatigueCause")).isEqualTo("POOR_SLEEP");

        // Exportación RGPD con los días del ciclo; desactivar borrando el historial los elimina.
        String export = body(get("/api/v1/me/export"), token, 200);
        assertThat(export).contains("cycleDays").contains("CRAMPS");
        body(put("/api/v1/training/cycle/settings").content("{\"enabled\":false,\"deleteHistory\":true}"), token, 200);
        String empty = body(get("/api/v1/training/cycle/days").param("from", today).param("to", today), token, 200);
        assertThat((List<?>) JsonPath.read(empty, "$.days")).isEmpty();

        // Retirar el consentimiento del registro diario borrando los registros: ya no queda el de hoy.
        body(delete("/api/v1/me/health-consent").param("deleteRecords", "true"), token, 204);
        body(get("/api/v1/training/check-ins/today"), token, 204);
        assertThat((Boolean) JsonPath.read(body(get("/api/v1/me/health-consent"), token, 200), "$.given")).isFalse();

        // Carrera corta apuntada a mano: 25 min y 5 km → 5:00 por km, en el historial de actividades.
        Instant start = Instant.now().minus(3, ChronoUnit.HOURS).truncatedTo(ChronoUnit.MINUTES);
        body(post("/api/v1/planner/past-activities").content("{\"start\":\"" + start + "\",\"minutes\":25,"
                + "\"title\":\"Correr\",\"effort\":7,\"kind\":\"RUN\",\"distanceMeters\":5000}"), token, 201);
        String activities = body(get("/api/v1/planner/past-activities"), token, 200);
        assertThat((Integer) JsonPath.read(activities, "$.totalItems")).isEqualTo(1);
        assertThat((Integer) JsonPath.read(activities, "$.items[0].minutes")).isEqualTo(25);
        assertThat((Integer) JsonPath.read(activities, "$.items[0].paceSecondsPerKm")).isEqualTo(300);
        assertThat((String) JsonPath.read(activities, "$.items[0].kind")).isEqualTo("RUN");
        assertThat((Integer) JsonPath.read(activities, "$.items[0].effort")).isEqualTo(7);

        // Avisos opcionales: todos encendidos por defecto; apagar el registro diario lo quita del plan.
        String options = body(get("/api/v1/notifications/reminder-options"), token, 200);
        assertThat((Boolean) JsonPath.read(options, "$.checkIn")).isTrue();
        body(put("/api/v1/notifications/reminder-options")
                .content("{\"streak\":true,\"checkIn\":false,\"classes\":true}"), token, 200);
        String plan = body(get("/api/v1/notifications/reminder-plan"), token, 200);
        assertThat((List<String>) JsonPath.read(plan, "$.reminders[*].kind")).doesNotContain("CHECK_IN");
        body(delete("/api/v1/training/cycle/days"), token, 204);
    }
}
