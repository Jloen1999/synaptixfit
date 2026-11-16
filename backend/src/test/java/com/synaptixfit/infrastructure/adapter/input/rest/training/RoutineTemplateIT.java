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
 * Plantillas, plan por fases y días de rutina vinculables (ADR 0032) sobre PostgreSQL real: valida V1034-V1036 y,
 * desde ADR 0054, las plantillas reales de V1072-V1073 (retiradas, nombres de sesión, rangos, peso de partida, salidas
 * por semana) y la calibración de la primera sesión.
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
    @SuppressWarnings("unchecked")
    void onlyTheRealTemplatesAreOfferedAndTheyBecomeAPrivateRoutineWithNamesRangesAndWeights() throws Exception {
        String token = register("plantillas@example.com");

        String templates = body(get("/api/v1/training/templates").header("Accept-Language", "en"), token, 200);
        List<String> codes = JsonPath.read(templates, "$[*].code");
        // ADR 0054: las 24 anteriores se retiran (activa = false) y quedan las 12 nuevas.
        assertThat(codes).containsExactly("maquinas_empezar", "pesas_libres", "poco_tiempo", "arriba_y_piernas",
                "empujar_tirar_piernas", "casa_sin_material", "casa_mancuernas", "calistenia_parque",
                "mantener_examenes_gimnasio", "mantener_examenes_casa", "empieza_a_correr", "espalda_movilidad");
        assertThat((List<String>) JsonPath.read(templates, "$[?(@.code == 'maquinas_empezar')].name"))
                .containsExactly("Machines to get started");
        assertThat((List<List<String>>) JsonPath.read(templates, "$[?(@.code == 'poco_tiempo')].dayNames"))
                .containsExactly(List.of("Legs, chest and back", "Glutes, shoulders and back"));
        List<String> ids = JsonPath.read(templates, "$[?(@.code == 'pesas_libres')].id");

        String routine = body(post("/api/v1/training/templates/" + ids.getFirst() + "/use"), token, 201);
        String routineId = JsonPath.read(routine, "$.id");
        assertThat((String) JsonPath.read(routine, "$.visibility")).isEqualTo("PRIVATE");
        assertThat((List<?>) JsonPath.read(routine, "$.weeks")).hasSize(8);
        assertThat((String) JsonPath.read(routine, "$.weeks[7].type")).isEqualTo("DELOAD");
        assertThat((Integer) JsonPath.read(routine, "$.currentWeek")).isEqualTo(1);

        String again = body(get("/api/v1/routines/" + routineId), token, 200);
        assertThat((String) JsonPath.read(again, "$.weeks[0].days[0].name")).isEqualTo("Sentadilla, pecho y espalda");
        // Sentadilla con barra: rango 6-8, te deben sobrar 3 y, sin consentimiento de salud, el peso por defecto.
        String squat = "$.weeks[0].days[0].exercises[0]";
        assertThat((Integer) JsonPath.read(again, squat + ".reps")).isEqualTo(6);
        assertThat((Integer) JsonPath.read(again, squat + ".repMin")).isEqualTo(6);
        assertThat((Integer) JsonPath.read(again, squat + ".repMax")).isEqualTo(8);
        assertThat((Integer) JsonPath.read(again, squat + ".repsInReserve")).isEqualTo(3);
        assertThat((Double) JsonPath.read(again, squat + ".weightKg")).isEqualTo(20.0);
        // La plancha es un aguante: sin rango ni kilos.
        assertThat((Object) JsonPath.read(again, "$.weeks[0].days[0].exercises[3].repMin")).isNull();
        assertThat((Integer) JsonPath.read(again, "$.weeks[0].days[0].exercises[3].isometricSeconds")).isEqualTo(30);

        // Una plantilla retirada ya no se puede usar (casa_2, de V1035).
        mvc.perform(post("/api/v1/training/templates/d4b0ddcd-6d91-5f4d-86b9-e62a36202c98/use")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("ROUTINE_TEMPLATE_NOT_FOUND"));
        mvc.perform(post("/api/v1/training/templates/" + UUID.randomUUID() + "/use")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("ROUTINE_TEMPLATE_NOT_FOUND"));

        // La primera rutina queda en curso: sus días se pueden vincular a una tarea de reto.
        String targets = body(get("/api/v1/challenges/routine-day-targets"), token, 200);
        assertThat((List<?>) JsonPath.read(targets, "$")).hasSize(24);
    }

    /** ADR 0054: «Empieza a correr» crea un entreno por salida distinta de las 9 semanas, una sola vez. */
    @Test
    @SuppressWarnings("unchecked")
    void startRunningAddsOneRunWorkoutPerOutingOnce() throws Exception {
        String token = register("plantillas-correr@example.com");

        String templates = body(get("/api/v1/training/templates"), token, 200);
        assertThat((List<Integer>) JsonPath.read(templates, "$[?(@.code == 'empieza_a_correr')].daysPerWeek"))
                .containsExactly(4);
        assertThat((List<Integer>) JsonPath.read(templates, "$[?(@.code == 'empieza_a_correr')].runDays[*].dayNumber"))
                .containsExactly(1, 3, 6);
        assertThat((List<String>) JsonPath.read(templates, "$[?(@.code == 'calistenia_parque')].place"))
                .containsExactly("OUTDOOR");
        assertThat((List<String>) JsonPath.read(templates, "$[?(@.code == 'arriba_y_piernas')].level"))
                .containsExactly("INTERMEDIATE");
        List<String> ids = JsonPath.read(templates, "$[?(@.code == 'empieza_a_correr')].id");

        body(post("/api/v1/training/templates/" + ids.getFirst() + "/use"), token, 201);
        body(post("/api/v1/training/templates/" + ids.getFirst() + "/use"), token, 201);

        String workouts = body(get("/api/v1/training/run-workouts"), token, 200);
        assertThat((List<String>) JsonPath.read(workouts, "$[*].templateCode")).containsExactlyInAnyOrder(
                "C25K_W1", "C25K_W2", "C25K_W3", "C25K_W4", "C25K_W5_1", "C25K_W5_2", "C25K_W5_3", "C25K_W6_1",
                "C25K_W6_2", "C25K_W6_3", "C25K_W7", "C25K_W8", "C25K_W9");
        assertThat((List<String>) JsonPath.read(workouts, "$[?(@.templateCode == 'C25K_W1')].name"))
                .containsExactly("Semana 1 · 8 veces: 1 min corriendo y 1,5 andando");
    }

    /** ADR 0054: la primera sesión de un ejercicio pregunta cuántas sobraron y el peso pasa a los días que quedan. */
    @Test
    void theFirstSessionCalibratesTheWeightAndTheRoutineKeepsIt() throws Exception {
        String token = register("plantillas-calibrar@example.com");
        String templates = body(get("/api/v1/training/templates"), token, 200);
        List<String> ids = JsonPath.read(templates, "$[?(@.code == 'pesas_libres')].id");
        String routine = body(post("/api/v1/training/templates/" + ids.getFirst() + "/use"), token, 201);
        String routineId = JsonPath.read(routine, "$.id");
        String dayId = JsonPath.read(routine, "$.weeks[0].days[0].id");
        String squatSlot = JsonPath.read(routine, "$.weeks[0].days[0].exercises[0].id");
        String squatId = JsonPath.read(routine, "$.weeks[0].days[0].exercises[0].exerciseId");

        String session = body(post("/api/v1/training/sessions")
                .content("{\"routineId\":\"" + routineId + "\",\"dayId\":\"" + dayId + "\"}"), token, 201);
        String sessionId = JsonPath.read(session, "$.id");
        String calibrations = body(get("/api/v1/training/sessions/" + sessionId + "/calibrations"), token, 200);
        List<String> asked = JsonPath.read(calibrations, "$[*].exerciseId");
        assertThat(asked).contains(squatId);

        mvc.perform(post("/api/v1/training/sessions/" + sessionId + "/calibrations")
                        .header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"plannedExerciseId\":\"" + squatSlot + "\",\"setNumber\":1,\"answer\":\"FOUR_PLUS\"}"))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("SESSION_SET_NOT_FOUND"));

        body(post("/api/v1/training/sessions/" + sessionId + "/sets").content(
                "{\"plannedExerciseId\":\"" + squatSlot + "\",\"setNumber\":1,\"repsDone\":6,\"weightKg\":20}"),
                token, 200);
        String answer = body(post("/api/v1/training/sessions/" + sessionId + "/calibrations").content(
                "{\"plannedExerciseId\":\"" + squatSlot + "\",\"setNumber\":1,\"answer\":\"FOUR_PLUS\"}"),
                token, 200);
        assertThat((String) JsonPath.read(answer, "$.step")).isEqualTo("UP");
        assertThat((Double) JsonPath.read(answer, "$.nextWeightKg")).isEqualTo(25.0);

        String after = body(get("/api/v1/routines/" + routineId), token, 200);
        // El viernes repite la sesión: la sentadilla ya pide 25 kg.
        assertThat((Double) JsonPath.read(after, "$.weeks[0].days[2].exercises[0].weightKg")).isEqualTo(25.0);
        String again = body(get("/api/v1/training/sessions/" + sessionId + "/calibrations"), token, 200);
        assertThat((List<String>) JsonPath.read(again, "$[?(@.answer == 'FOUR_PLUS')].plannedExerciseId"))
                .containsExactly(squatSlot);
    }
}
