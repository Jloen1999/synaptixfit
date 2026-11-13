package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/** Apuntar una actividad pasada (deporte con su esfuerzo o estudio), como bloque hecho, solo de los últimos 7 días. */
@SpringBootTest
@AutoConfigureMockMvc
class PastActivityIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    private String auth;

    @BeforeEach
    void register() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"past-" + UUID.randomUUID()
                                + "@example.com\",\"password\":\"secret123\",\"fullName\":\"Ana\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        auth = "Bearer " + JsonPath.read(body, "$.accessToken");
    }

    private String body(Instant start, int minutes) {
        return "{\"start\":\"%s\",\"minutes\":%d,\"title\":\"Fútbol\",\"effort\":6}".formatted(start, minutes);
    }

    @Test
    void yesterdaysMatchIsSavedAsACompletedSportBlock() throws Exception {
        Instant yesterday = Instant.now().truncatedTo(ChronoUnit.HOURS).minus(Duration.ofDays(1));

        mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(body(yesterday, 60)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.block.type").value("SPORT"))
                .andExpect(jsonPath("$.block.completed").value(true))
                .andExpect(jsonPath("$.block.topics").value("Fútbol"))
                .andExpect(jsonPath("$.xpDelta").isNumber());
    }

    @Test
    void routineTrainingIsNotListedAsAnActivity() throws Exception {
        Instant yesterday = Instant.now().truncatedTo(ChronoUnit.HOURS).minus(Duration.ofDays(1));
        String match = mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(body(yesterday, 60)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String gym = mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(body(yesterday.minus(Duration.ofHours(3)), 60)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        // El segundo pasa a ser el reflejo de un día de rutina: es gimnasio, no una actividad de Correr (ADR 0039).
        UUID gymBlock = UUID.fromString(JsonPath.read(gym, "$.block.id"));
        UUID owner = jdbc.sql("select usuario_id from horarios_academicos where id = :id").param("id", gymBlock)
                .query(UUID.class).single();
        UUID routine = jdbc.sql("insert into rutinas (usuario_id, nombre, objetivo) values (:u, 'Rutina IT', "
                        + "'Fuerza Máxima') returning id").param("u", owner).query(UUID.class).single();
        UUID week = jdbc.sql("insert into semanas_rutina (rutina_id, numero_semana) values (:r, 1) returning id")
                .param("r", routine).query(UUID.class).single();
        UUID day = jdbc.sql("insert into dias_rutina (semana_id, numero_dia, nombre) values (:w, 1, 'Pierna') "
                        + "returning id").param("w", week).query(UUID.class).single();
        jdbc.sql("update horarios_academicos set rutina_id = :r, semana_rutina_id = :w, dia_rutina_id = :d "
                        + "where id = :id")
                .param("r", routine).param("w", week).param("d", day).param("id", gymBlock).update();

        String list = mvc.perform(get("/api/v1/planner/past-activities").header("Authorization", auth))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat((Integer) JsonPath.read(list, "$.totalItems")).isEqualTo(1);
        assertThat((String) JsonPath.read(list, "$.items[0].blockId"))
                .isEqualTo(JsonPath.read(match, "$.block.id"));
    }

    @Test
    void notFinishedOrTooOldIsRejected() throws Exception {
        Instant now = Instant.now();
        mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(body(now.minus(Duration.ofMinutes(20)), 60)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("PLANNER_PAST_ACTIVITY_OUT_OF_RANGE"));
        mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(body(now.minus(Duration.ofDays(8)), 60)))
                .andExpect(status().isUnprocessableEntity());
        mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        // Menos de 10 minutos no es una actividad (ADR 0033).
                        .contentType(MediaType.APPLICATION_JSON).content(body(now.minus(Duration.ofDays(1)), 9)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void studyAlreadyDoneIsSavedAsACompletedStudyBlockWithoutEffort() throws Exception {
        Instant yesterday = Instant.now().truncatedTo(ChronoUnit.HOURS).minus(Duration.ofDays(1));

        mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"start\":\"%s\",\"minutes\":90,\"title\":\"Temas 3 y 4\",\"type\":\"STUDY\"}"
                                .formatted(yesterday)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.block.type").value("STUDY"))
                .andExpect(jsonPath("$.block.completed").value(true))
                .andExpect(jsonPath("$.xpDelta").isNumber());
    }

    @Test
    void onlySportAndStudyAndAKnownSubject() throws Exception {
        Instant yesterday = Instant.now().truncatedTo(ChronoUnit.HOURS).minus(Duration.ofDays(1));
        mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"start\":\"%s\",\"minutes\":60,\"type\":\"CLASS\"}".formatted(yesterday)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("PLANNER_PAST_ACTIVITY_TYPE_NOT_ALLOWED"));
        mvc.perform(post("/api/v1/planner/past-activities").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"start\":\"%s\",\"minutes\":60,\"type\":\"STUDY\",\"subjectId\":\"%s\"}"
                                .formatted(yesterday, UUID.randomUUID())))
                .andExpect(status().isNotFound());
    }
}
