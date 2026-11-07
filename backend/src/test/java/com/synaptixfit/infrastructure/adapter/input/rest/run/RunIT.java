package com.synaptixfit.infrastructure.adapter.input.rest.run;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.UUID;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Carreras con GPS de punta a punta (ADR 0037): subir una ruta (idempotente), ver su detalle, que salga como
 * actividad «GPS de la app», la semana, borrarla y los entrenos de carrera puestos en el calendario.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RunIT {

    private static final double METERS_PER_DEGREE = Math.toRadians(1) * 6_371_008.8;

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String auth;

    @BeforeEach
    void register() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"run-" + UUID.randomUUID()
                                + "@example.com\",\"password\":\"secret123\",\"fullName\":\"Ana\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        auth = "Bearer " + JsonPath.read(body, "$.accessToken");
    }

    /** {@code minutes} corriendo a 3 m/s con un punto cada 2 s. */
    private static String run(UUID key, Instant startedAt, int minutes, String extra) {
        StringBuilder points = new StringBuilder();
        for (int s = 0; s <= minutes * 60; s += 2) {
            if (!points.isEmpty()) {
                points.append(',');
            }
            points.append(String.format(Locale.ROOT, "[%.7f,-3.7038,650.0,5.0,%d,0]",
                    40.4168 + 3.0 * s / METERS_PER_DEGREE, s));
        }
        return "{\"clientKey\":\"%s\",\"kind\":\"RUN\",\"startedAt\":\"%s\",\"effort\":6,\"points\":[%s]%s}"
                .formatted(key, startedAt, points, extra);
    }

    @Test
    void aGpsRunIsAnActivityWithItsFiguresAndCanBeDeleted() throws Exception {
        UUID key = UUID.randomUUID();
        Instant startedAt = Instant.now().minus(Duration.ofHours(2)).truncatedTo(ChronoUnit.SECONDS);
        String body = mvc.perform(post("/api/v1/training/runs").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(run(key, startedAt, 20, "")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.run.kind").value("RUN"))
                .andExpect(jsonPath("$.run.distanceMeters").value(Matchers.allOf(
                        Matchers.greaterThan(3580), Matchers.lessThan(3620))))
                .andExpect(jsonPath("$.run.paceSecondsPerKm").value(Matchers.allOf(
                        Matchers.greaterThan(330), Matchers.lessThan(337))))
                .andExpect(jsonPath("$.run.splits.length()").value(4))
                .andExpect(jsonPath("$.run.route.length()").value(Matchers.greaterThan(100)))
                .andExpect(jsonPath("$.xpDelta").isNumber())
                .andReturn().getResponse().getContentAsString();
        String blockId = JsonPath.read(body, "$.run.blockId");

        // La cola del móvil reintenta: misma clave, misma carrera.
        mvc.perform(post("/api/v1/training/runs").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(run(key, startedAt, 20, "")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.run.blockId").value(blockId))
                .andExpect(jsonPath("$.xpDelta").value(0));

        mvc.perform(get("/api/v1/planner/past-activities").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].source").value("GPS"))
                .andExpect(jsonPath("$.items[0].kind").value("RUN"))
                .andExpect(jsonPath("$.items[0].minutes").value(20));

        mvc.perform(get("/api/v1/training/runs/week").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dailyDistanceMeters.length()").value(7));

        mvc.perform(get("/api/v1/training/runs/" + blockId).header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.effort").value(6));

        mvc.perform(delete("/api/v1/training/runs/" + blockId).header("Authorization", auth))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/training/runs/" + blockId).header("Authorization", auth))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RUN_NOT_FOUND"));
    }

    @Test
    void tooShortOrTooOldRunsAreRejectedWithTheirCode() throws Exception {
        mvc.perform(post("/api/v1/training/runs").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(run(UUID.randomUUID(), Instant.now().minus(Duration.ofHours(1)), 5, "")))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("RUN_TOO_SHORT"));
        mvc.perform(post("/api/v1/training/runs").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(run(UUID.randomUUID(), Instant.now().minus(Duration.ofDays(40)), 20, "")))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("RUN_OUT_OF_RANGE"));
    }

    @Test
    void aRunWorkoutGoesToTheCalendarAndRecordingItLeavesNoPendingEvent() throws Exception {
        mvc.perform(get("/api/v1/training/run-workouts/templates").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.code == 'INTERVALS_6X800')].groups[1].repeat").value(6));

        String created = mvc.perform(post("/api/v1/training/run-workouts").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Rodaje suave 30 min\",\"templateCode\":\"EASY_30\",\"groups\":["
                                + "{\"repeat\":1,\"steps\":[{\"type\":\"RUN\",\"measure\":\"TIME\",\"value\":1800}]}]}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.estimatedSeconds").value(1800))
                .andReturn().getResponse().getContentAsString();
        String workoutId = JsonPath.read(created, "$.id");

        Instant later = Instant.now().plus(Duration.ofHours(3)).truncatedTo(ChronoUnit.MINUTES);
        String scheduled = mvc.perform(post("/api/v1/training/run-workouts/" + workoutId + "/schedule")
                        .header("Authorization", auth).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"start\":\"" + later + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String eventId = JsonPath.read(scheduled, "$.blockId");
        mvc.perform(get("/api/v1/training/run-workouts/planned").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].blockId").value(eventId))
                .andExpect(jsonPath("$[0].workoutName").value("Rodaje suave 30 min"));

        // Se corre antes de la hora: la carrera se apunta en su hora real y el evento ya no queda por hacer.
        mvc.perform(post("/api/v1/training/runs").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(run(UUID.randomUUID(), Instant.now().minus(Duration.ofHours(1)), 30,
                                ",\"plannedBlockId\":\"" + eventId + "\"")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.run.title").value("Rodaje suave 30 min"))
                .andExpect(jsonPath("$.run.workoutId").value(workoutId));
        mvc.perform(get("/api/v1/training/run-workouts/planned").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }
}
