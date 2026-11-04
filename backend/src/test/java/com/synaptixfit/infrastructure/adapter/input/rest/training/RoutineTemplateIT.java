package com.synaptixfit.infrastructure.adapter.input.rest.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.util.List;
import java.util.UUID;
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
 * Plantillas, plan por fases, evolución de un ejercicio y días de rutina vinculables (ADR 0032) sobre
 * PostgreSQL real: valida V1034-V1036 y el cableado de los endpoints.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RoutineTemplateIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Atleta T\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private String body(MockHttpServletRequestBuilder b, String token, int expected) throws Exception {
        return mvc.perform(b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().is(expected)).andReturn().getResponse().getContentAsString();
    }

    @Test
    void templateBecomesAPrivateRoutineWithPlanAndLinkableDays() throws Exception {
        String token = register("plantillas@example.com");

        String templates = body(get("/api/v1/training/templates").header("Accept-Language", "en"), token, 200);
        List<String> codes = JsonPath.read(templates, "$[*].code");
        assertThat(codes).contains("casa_2", "examenes_casa");
        List<String> ids = JsonPath.read(templates, "$[?(@.code == 'casa_2')].id");
        String id = ids.getFirst();
        List<String> names = JsonPath.read(templates, "$[?(@.code == 'casa_2')].name");
        assertThat(names.getFirst()).isEqualTo("At home · 2 days");

        String routine = body(post("/api/v1/training/templates/" + id + "/use"), token, 201);
        String routineId = JsonPath.read(routine, "$.id");
        assertThat((String) JsonPath.read(routine, "$.visibility")).isEqualTo("PRIVATE");
        assertThat((List<?>) JsonPath.read(routine, "$.weeks")).hasSize(4);
        assertThat((String) JsonPath.read(routine, "$.weeks[3].type")).isEqualTo("DELOAD");
        assertThat((Integer) JsonPath.read(routine, "$.currentWeek")).isEqualTo(1);
        assertThat((Integer) JsonPath.read(routine, "$.progressPercent")).isZero();
        assertThat((String) JsonPath.read(routine, "$.nextStep")).isEqualTo("REPEAT_STRONGER");

        String again = body(get("/api/v1/routines/" + routineId), token, 200);
        assertThat((Integer) JsonPath.read(again, "$.weeks[0].days[0].dayNumber")).isEqualTo(2);

        mvc.perform(post("/api/v1/training/templates/" + UUID.randomUUID() + "/use")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("ROUTINE_TEMPLATE_NOT_FOUND"));

        // La primera rutina queda en curso: sus días se pueden vincular a una tarea de reto.
        String targets = body(get("/api/v1/challenges/routine-day-targets"), token, 200);
        assertThat((List<?>) JsonPath.read(targets, "$")).hasSize(8);
        assertThat((Integer) JsonPath.read(targets, "$[0].weekNumber")).isEqualTo(1);

        // Sin series con peso, la evolución de un ejercicio está vacía.
        String exerciseId = JsonPath.read(again, "$.weeks[0].days[0].exercises[0].exerciseId");
        String progress = body(get("/api/v1/training/exercises/" + exerciseId + "/progress"), token, 200);
        assertThat((List<?>) JsonPath.read(progress, "$")).isEmpty();
    }
}
