package com.synaptixfit.infrastructure.adapter.input.rest.insights;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.event.planner.StudyBlockCompletionChanged;
import com.synaptixfit.domain.event.training.TrainingSessionCompletionChanged;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Flujo completo de los indicadores sobre PostgreSQL real: registro (estado cognitivo inicial),
 * sesión completada (carga física + ACWR corregido), bloque de estudio completado (carga cognitiva),
 * inicio, analítica y errores.
 */
@SpringBootTest
@AutoConfigureMockMvc
class InsightsFlowIT {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;
    @Autowired
    private ApplicationEventPublisher events;
    @Autowired
    private JdbcClient jdbc;

    @Test
    void trainingSessionDrivesCrossRegulationAndDashboard() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"insights@example.com\",\"password\":\"secret123\",\"fullName\":\"Indi Cadores\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String bearer = "Bearer " + JsonPath.read(body, "$.accessToken");
        UUID userId = UUID.fromString(JsonPath.read(body, "$.user.id"));

        // UserRegistered → estado cognitivo inicial.
        assertThat(jdbc.sql("SELECT count(*) FROM estado_cognitivo_usuario WHERE usuario_id = :u")
                .param("u", userId).query(Long.class).single()).isEqualTo(1L);
        mvc.perform(get("/api/v1/insights/cognitive-state").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cognitiveLoad").value(0.0))
                .andExpect(jsonPath("$.attentionCapacity").value(1.0));

        // Historial: una carga de hace 20 días (420 AU) da línea base al ACWR; sin ella, la primera
        // semana no tiene ACWR (zona NO_DATA) para no alarmar a un usuario nuevo.
        jdbc.sql("""
                        INSERT INTO registros_carga_fisica (usuario_id, fecha_registro, rpe_sesion, duracion_minutos)
                        VALUES (:u, :d, 7, 60)
                        """)
                .param("u", userId).param("d", LocalDate.now(MADRID).minusDays(20)).update();

        // Sesión de entrenamiento completada hoy: RPE 7 x 60 min = 420 AU.
        UUID sessionId = UUID.randomUUID();
        Instant now = Instant.now();
        jdbc.sql("""
                        INSERT INTO sesiones_registradas (id, usuario_id, duracion_minutos, calorias_quemadas, rpe, completada_en, tipo)
                        VALUES (:id, :u, 60, 400, 7, :at, 'libre')
                        """)
                .param("id", sessionId).param("u", userId).param("at", now.atOffset(ZoneOffset.UTC)).update();
        LocalDate today = LocalDate.now(MADRID);
        TrainingSessionCompletionChanged completed =
                new TrainingSessionCompletionChanged(userId, sessionId, today, 7, 60, null, true, now);
        events.publishEvent(completed);
        events.publishEvent(completed); // idempotente

        assertThat(jdbc.sql("SELECT count(*) FROM registros_carga_fisica WHERE usuario_id = :u")
                .param("u", userId).query(Long.class).single()).isEqualTo(2L);
        // Columna generada con el criterio corregido: (420/7) / (840/28) = 60 / 30 = 2.
        assertThat(jdbc.sql("SELECT acwr_actual FROM estado_regulacion_cruzada WHERE usuario_id = :u")
                .param("u", userId).query(BigDecimal.class).single()).isEqualByComparingTo("2.00");

        mvc.perform(get("/api/v1/insights/cross-regulation").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.acwr").value(2.0))
                .andExpect(jsonPath("$.zone").value("OVERTRAINING"))
                .andExpect(jsonPath("$.acuteDailyLoad").value(60.0))
                .andExpect(jsonPath("$.chronicDailyLoad").value(30.0))
                .andExpect(jsonPath("$.maxStudyMinutes").value(71))
                .andExpect(jsonPath("$.recommendedVolumeFactor").value(1.0));

        mvc.perform(get("/api/v1/insights/physical-load").param("tz", "Europe/Madrid").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.todayLoad").value(420.0))
                .andExpect(jsonPath("$.maxDailyLoad").value(420.0))
                .andExpect(jsonPath("$.last28Days.length()").value(28));

        // Bloque de estudio completado hoy (90 min) → carga cognitiva.
        UUID blockId = UUID.randomUUID();
        OffsetDateTime blockStart = today.atStartOfDay(MADRID).plusHours(1).toOffsetDateTime();
        jdbc.sql("""
                        INSERT INTO horarios_academicos (id, usuario_id, hora_inicio, hora_fin, tipo_actividad, completado)
                        VALUES (:id, :u, :start, :end, 'estudio', true)
                        """)
                .param("id", blockId).param("u", userId).param("start", blockStart)
                .param("end", blockStart.plusMinutes(90)).update();
        events.publishEvent(new StudyBlockCompletionChanged(userId, blockId, "estudio", null, null,
                blockStart.toInstant(), blockStart.plusMinutes(90).toInstant(), true, now));

        BigDecimal load = jdbc.sql("SELECT carga_cognitiva_actual FROM estado_cognitivo_usuario WHERE usuario_id = :u")
                .param("u", userId).query(BigDecimal.class).single();
        // Fórmula 2 v2 (ADR 0011): 90 min con μ = 1 → C = 1 − e^(−90/τ), τ = 240/ln 5 ≈ 149 min.
        assertThat(load).isEqualByComparingTo("0.4531");
        mvc.perform(get("/api/v1/insights/study-calories/today").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completedBlocks").value(1))
                .andExpect(jsonPath("$.studyMinutes").value(90));

        mvc.perform(get("/api/v1/dashboard").param("tz", "Europe/Madrid").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.greeting.fullName").value("Indi Cadores"))
                .andExpect(jsonPath("$.greeting.level").value(1))
                .andExpect(jsonPath("$.today.sessions").value(1))
                .andExpect(jsonPath("$.today.trainingCalories").value(400.0))
                .andExpect(jsonPath("$.today.studyMinutesCompleted").value(90))
                .andExpect(jsonPath("$.crossRegulation.zone").value("OVERTRAINING"))
                .andExpect(jsonPath("$.wellbeing.checkInDone").value(false))
                .andExpect(jsonPath("$.planWeek.length()").value(7))
                .andExpect(jsonPath("$.todayEvents[0].type").value("STUDY"))
                .andExpect(jsonPath("$.banner.type").value("PHYSICAL_OVERLOAD"))
                .andExpect(jsonPath("$.banner.params.maxStudyMinutes").value(71));

        mvc.perform(get("/api/v1/analytics/weekly").param("period", "WEEKLY").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.weeks.length()").value(4))
                .andExpect(jsonPath("$.totalSessions").value(1))
                .andExpect(jsonPath("$.averageRpe").value(7.0));
        mvc.perform(get("/api/v1/analytics/correlation").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sufficientData").value(false));
        mvc.perform(get("/api/v1/analytics/insights").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].type").value("STREAK"));
        mvc.perform(get("/api/v1/analytics/rpe-trend").header("Authorization", bearer))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/analytics/volume").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.points.length()").value(12));
        mvc.perform(get("/api/v1/insights/wellbeing").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.energy").value(org.hamcrest.Matchers.nullValue()));

        // Sesión desmarcada → se borra su carga; queda solo el historial: semana sin carga = ACWR 0.
        events.publishEvent(new TrainingSessionCompletionChanged(userId, sessionId, today, 7, 60, null, false, now));
        mvc.perform(get("/api/v1/insights/cross-regulation").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.acwr").value(0.0))
                .andExpect(jsonPath("$.zone").value("UNDERTRAINING"))
                .andExpect(jsonPath("$.maxStudyMinutes").value(90));
    }

    @Test
    void invalidParametersReturnModuleCodes() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"insights-errors@example.com\",\"password\":\"secret123\",\"fullName\":\"Err Ores\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String bearer = "Bearer " + JsonPath.read(body, "$.accessToken");

        mvc.perform(get("/api/v1/dashboard").param("tz", "Mars/Olympus").header("Authorization", bearer))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INSIGHTS_INVALID_TIME_ZONE"));
        mvc.perform(get("/api/v1/analytics/weekly").param("period", "YEARLY").header("Authorization", bearer))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("ANALYTICS_INVALID_PERIOD"));
        mvc.perform(get("/api/v1/analytics/correlation").param("metric", "CALORIES").header("Authorization", bearer))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("ANALYTICS_INVALID_METRIC"));
        mvc.perform(get("/api/v1/insights/cross-regulation"))
                .andExpect(status().isUnauthorized());
    }
}
