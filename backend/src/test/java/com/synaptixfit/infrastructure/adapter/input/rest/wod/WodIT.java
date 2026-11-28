package com.synaptixfit.infrastructure.adapter.input.rest.wod;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
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
 * WOD de punta a punta (ADR 0069): plantillas, la pizarra de hoy, crear y cambiar mi WOD, guardar marcas (la mejor la
 * decide el servidor), que cada marca salga como actividad con deporte WOD, y borrar.
 */
@SpringBootTest
@AutoConfigureMockMvc
class WodIT {

    private static final String WOD = """
            {"title":"Lunes","strength":"Sentadilla 5x5","format":"FOR_TIME","timeCapSeconds":900,"rounds":3,
             "movements":[{"name":"Sentadillas","quantity":20,"unit":"REPS"},
                          {"name":"Balanceos con pesa rusa","quantity":15,"unit":"REPS","rxKg":16,"scaledKg":8},
                          {"name":"Carrera","quantity":200,"unit":"METERS"}]}
            """;

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String auth;

    @BeforeEach
    void register() throws Exception {
        auth = newUser();
    }

    private String newUser() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"wod-" + UUID.randomUUID()
                                + "@example.com\",\"password\":\"secret123\",\"fullName\":\"Ana\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return "Bearer " + JsonPath.read(body, "$.accessToken");
    }

    @Test
    void myWodItsMarksTheBestOneAndItsActivity() throws Exception {
        mvc.perform(get("/api/v1/training/wods/templates").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(Matchers.allOf(
                        Matchers.greaterThanOrEqualTo(6), Matchers.lessThanOrEqualTo(8))))
                .andExpect(jsonPath("$[0].code").value("TRIPLE_TEN"))
                .andExpect(jsonPath("$[0].movements[0].code").value("AIR_SQUAT"));

        // Sin WOD mío, la pizarra enseña uno de ejemplo.
        mvc.perform(get("/api/v1/training/wods/today").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.example").value(true))
                .andExpect(jsonPath("$.wodId").doesNotExist())
                .andExpect(jsonPath("$.templateCode").isString());

        String created = mvc.perform(post("/api/v1/training/wods").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(WOD))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.format").value("FOR_TIME"))
                .andExpect(jsonPath("$.movements[1].rxKg").value(16.0))
                .andReturn().getResponse().getContentAsString();
        String wodId = JsonPath.read(created, "$.id");

        mvc.perform(put("/api/v1/training/wods/" + wodId).header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(WOD.replace("Lunes", "Lunes fuerte")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Lunes fuerte"));

        String first = mvc.perform(post("/api/v1/training/wods/results").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"wodId\":\"%s\",\"division\":\"RX\",\"value\":600,\"durationSeconds\":600}"
                                .formatted(wodId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.best").value(true))
                .andExpect(jsonPath("$.result.scoreType").value("TIME"))
                .andExpect(jsonPath("$.result.blockId").isString())
                .andReturn().getResponse().getContentAsString();
        String blockId = JsonPath.read(first, "$.result.blockId");

        mvc.perform(post("/api/v1/training/wods/results").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"wodId\":\"%s\",\"division\":\"RX\",\"value\":540,\"durationSeconds\":540}"
                                .formatted(wodId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.best").value(true));
        mvc.perform(post("/api/v1/training/wods/results").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"wodId\":\"%s\",\"division\":\"SCALED\",\"value\":96,\"capped\":true}"
                                .formatted(wodId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.result.scoreType").value("REPS"))
                .andExpect(jsonPath("$.best").value(true));

        // La pizarra ya es la mía, con la mejor marca de cada división y la de hoy.
        mvc.perform(get("/api/v1/training/wods/today").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.example").value(false))
                .andExpect(jsonPath("$.wodId").value(wodId))
                .andExpect(jsonPath("$.title").value("Lunes fuerte"))
                .andExpect(jsonPath("$.bestRx.value").value(540))
                .andExpect(jsonPath("$.bestScaled.capped").value(true))
                .andExpect(jsonPath("$.todayResult.wodId").value(wodId));

        mvc.perform(get("/api/v1/training/wods/results").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[?(@.result.value == 600)].best").value(Matchers.contains(false)))
                .andExpect(jsonPath("$[?(@.result.value == 540)].best").value(Matchers.contains(true)))
                .andExpect(jsonPath("$[0].title").value("Lunes fuerte"));

        // Cada marca es una actividad apuntada con deporte WOD: cuenta como cualquier otra.
        mvc.perform(get("/api/v1/planner/past-activities").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(3))
                .andExpect(jsonPath("$.items[?(@.blockId == '%s')].sport".formatted(blockId))
                        .value(Matchers.contains("WOD")))
                .andExpect(jsonPath("$.items[0].title").value("Lunes fuerte"))
                .andExpect(jsonPath("$.items[0].minutes").value(Matchers.greaterThanOrEqualTo(10)));

        // Un WOD ajeno no existe; un tiempo por encima del límite no vale.
        String other = newUser();
        mvc.perform(delete("/api/v1/training/wods/" + wodId).header("Authorization", other))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("WOD_NOT_FOUND"));
        mvc.perform(post("/api/v1/training/wods/results").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"wodId\":\"%s\",\"division\":\"RX\",\"value\":2000}".formatted(wodId)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        mvc.perform(delete("/api/v1/training/wods/" + wodId).header("Authorization", auth))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/training/wods/results").header("Authorization", auth))
                .andExpect(jsonPath("$.length()").value(0));
        mvc.perform(get("/api/v1/planner/past-activities").header("Authorization", auth))
                .andExpect(jsonPath("$.items.length()").value(3));
    }

    @Test
    void aMarkOfAnExampleWodCreatesMine() throws Exception {
        String body = """
                {"wod":{"templateCode":"TWELVE_NONSTOP","title":"Doce sin parar","format":"AMRAP",
                        "timeCapSeconds":720,
                        "movements":[{"code":"BURPEE","quantity":5,"unit":"REPS"},
                                     {"code":"AIR_SQUAT","quantity":10,"unit":"REPS"},
                                     {"code":"SIT_UP","quantity":15,"unit":"REPS"}]},
                 "division":"SCALED","value":6,"extraReps":4,"durationSeconds":720,"effort":8}
                """;
        mvc.perform(post("/api/v1/training/wods/results").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.templateCode").value("TWELVE_NONSTOP"))
                .andExpect(jsonPath("$.format").value("AMRAP"))
                .andExpect(jsonPath("$.result.scoreType").value("ROUNDS_REPS"))
                .andExpect(jsonPath("$.result.extraReps").value(4))
                .andExpect(jsonPath("$.best").value(true));

        mvc.perform(get("/api/v1/training/wods/today").header("Authorization", auth))
                .andExpect(jsonPath("$.example").value(false))
                .andExpect(jsonPath("$.templateCode").value("TWELVE_NONSTOP"))
                .andExpect(jsonPath("$.movements[0].code").value("BURPEE"))
                .andExpect(jsonPath("$.bestScaled.value").value(6));
        // Esa plantilla, pedida como ejemplo, ya enseña la mejor marca: es el mismo WOD.
        mvc.perform(get("/api/v1/training/wods/today").param("templateCode", "TWELVE_NONSTOP")
                        .header("Authorization", auth))
                .andExpect(jsonPath("$.example").value(true))
                .andExpect(jsonPath("$.bestScaled.extraReps").value(4))
                .andExpect(jsonPath("$.bestRx").doesNotExist());
        mvc.perform(get("/api/v1/training/wods/today").param("templateCode", "NOPE").header("Authorization", auth))
                .andExpect(status().isBadRequest());
    }
}
