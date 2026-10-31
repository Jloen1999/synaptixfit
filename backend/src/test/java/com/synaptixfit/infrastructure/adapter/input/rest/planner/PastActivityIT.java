package com.synaptixfit.infrastructure.adapter.input.rest.planner;

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
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/** Apuntar una actividad pasada: bloque de deporte completado con su esfuerzo, solo de los últimos 7 días. */
@SpringBootTest
@AutoConfigureMockMvc
class PastActivityIT {

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
                        .contentType(MediaType.APPLICATION_JSON).content(body(now.minus(Duration.ofDays(1)), 10)))
                .andExpect(status().isBadRequest());
    }
}
