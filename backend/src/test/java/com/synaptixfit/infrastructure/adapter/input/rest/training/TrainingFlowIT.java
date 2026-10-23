package com.synaptixfit.infrastructure.adapter.input.rest.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Flujo completo del módulo de entrenamiento sobre PostgreSQL real: catálogo → rutina → sesión →
 * finalizar (XP) → desmarcar (resta XP) → check-in → plan semanal → generación → comunidad y
 * privacidad. Valida además el mapeo JPA (ddl-auto=validate) y la migración V150.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TrainingFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Atleta " + email.charAt(0) + "\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private static MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder b, String token) {
        return b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON);
    }

    private String body(MockHttpServletRequestBuilder b, String token, int expectedStatus) throws Exception {
        return mvc.perform(auth(b, token)).andExpect(status().is(expectedStatus)).andReturn().getResponse()
                .getContentAsString();
    }

    @Test
    void routineSessionFinishUnmarkAndWellbeing() throws Exception {
        String token = register("train1@example.com");

        // Catálogo
        String page = body(get("/api/v1/exercises").param("q", "press").param("size", "5"), token, 200);
        assertThat((List<?>) JsonPath.read(page, "$.items")).isNotEmpty();
        // Dos ejercicios medidos por repeticiones y peso (la progresión depende de ello).
        List<String> ids = jdbc.sql("SELECT CAST(id AS text) FROM ejercicios WHERE 'peso' = ANY (tipo_medicion)"
                + " AND 'repeticiones' = ANY (tipo_medicion) AND COALESCE(activo, true) ORDER BY nombre LIMIT 2")
                .query(String.class).list();
        Integer total = JsonPath.read(page, "$.totalItems");
        assertThat(total).isPositive();
        body(get("/api/v1/exercises/" + ids.getFirst()), token, 200);
        String filters = body(get("/api/v1/exercises/filters"), token, 200);
        assertThat((List<?>) JsonPath.read(filters, "$.muscles")).isNotEmpty();
        mvc.perform(auth(get("/api/v1/exercises/" + UUID.randomUUID()), token))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("EXERCISE_NOT_FOUND"));

        // Alta de rutina con 2 semanas
        String create = """
                {"name":"Rutina de prueba","goal":"HYPERTROPHY","visibility":"PRIVATE","weeks":[
                  {"days":[
                    {"dayNumber":1,"name":"Torso","exercises":[
                      {"exerciseId":"%1$s","sets":3,"reps":10,"restSeconds":90,"weightKg":40},
                      {"exerciseId":"%2$s","sets":3,"reps":12,"restSeconds":60}]},
                    {"dayNumber":3,"exercises":[{"exerciseId":"%1$s","sets":4,"reps":8,"restSeconds":120}]}]},
                  {"type":"DELOAD","days":[{"dayNumber":1,"exercises":[{"exerciseId":"%2$s","sets":2,"reps":10,"restSeconds":60}]}]}
                ]}""".formatted(ids.get(0), ids.get(1));
        String routine = body(post("/api/v1/routines").content(create), token, 201);
        String routineId = JsonPath.read(routine, "$.id");
        assertThat((Integer) JsonPath.read(routine, "$.exerciseCount")).isEqualTo(4);
        assertThat((Integer) JsonPath.read(routine, "$.durationWeeks")).isEqualTo(2);
        assertThat((String) JsonPath.read(routine, "$.weeks[0].type")).isEqualTo("ADAPTATION");
        assertThat((String) JsonPath.read(routine, "$.weeks[1].type")).isEqualTo("DELOAD");
        assertThat((String) JsonPath.read(routine, "$.weeks[0].days[1].name")).isEqualTo("Día 3");
        String day1 = JsonPath.read(routine, "$.weeks[0].days[0].id");
        String week1 = JsonPath.read(routine, "$.weeks[0].id");
        List<String> plannedDay1 = JsonPath.read(routine, "$.weeks[0].days[0].exercises[*].id");

        // Reordenar y editar
        String reordered = body(put("/api/v1/routines/" + routineId + "/days/" + day1 + "/exercises/order")
                .content("{\"plannedExerciseIds\":[\"" + plannedDay1.get(1) + "\",\"" + plannedDay1.get(0) + "\"]}"), token, 200);
        assertThat((String) JsonPath.read(reordered, "$.weeks[0].days[0].exercises[0].id")).isEqualTo(plannedDay1.get(1));
        body(put("/api/v1/routines/" + routineId + "/exercises/" + plannedDay1.get(0))
                .content("{\"sets\":4,\"reps\":8,\"restSeconds\":120,\"weightKg\":42.5}"), token, 200);

        // Añadir y borrar una semana (renumeración)
        String withWeek = body(post("/api/v1/routines/" + routineId + "/weeks").content("{\"name\":\"Extra\"}"), token, 201);
        assertThat((Integer) JsonPath.read(withWeek, "$.durationWeeks")).isEqualTo(3);
        String week2 = JsonPath.read(withWeek, "$.weeks[1].id");
        String afterDelete = body(delete("/api/v1/routines/" + routineId + "/weeks/" + week2), token, 200);
        assertThat((Integer) JsonPath.read(afterDelete, "$.weeks[1].number")).isEqualTo(2);
        assertThat((String) JsonPath.read(afterDelete, "$.weeks[1].name")).isEqualTo("Extra");
        assertThat((Integer) JsonPath.read(afterDelete, "$.exerciseCount")).isEqualTo(3);
        mvc.perform(auth(post("/api/v1/routines/" + routineId + "/weeks/" + week1 + "/days")
                        .content("{\"dayNumber\":1}"), token))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("ROUTINE_DAY_DUPLICATED"));

        // Día pendiente
        String pending = body(get("/api/v1/training/pending-day"), token, 200);
        assertThat((String) JsonPath.read(pending, "$.dayId")).isEqualTo(day1);

        // Sesión: empezar → series → finalizar
        String session = body(post("/api/v1/training/sessions")
                .content("{\"routineId\":\"" + routineId + "\",\"dayId\":\"" + day1 + "\"}"), token, 201);
        String sessionId = JsonPath.read(session, "$.id");
        assertThat((String) JsonPath.read(session, "$.status")).isEqualTo("IN_PROGRESS");
        String again = body(post("/api/v1/training/sessions")
                .content("{\"routineId\":\"" + routineId + "\",\"dayId\":\"" + day1 + "\"}"), token, 201);
        assertThat((String) JsonPath.read(again, "$.id")).isEqualTo(sessionId);
        String inProgress = body(get("/api/v1/routines/" + routineId), token, 200);
        assertThat((String) JsonPath.read(inProgress, "$.weeks[0].days[0].status")).isEqualTo("IN_PROGRESS");
        assertThat((String) JsonPath.read(inProgress, "$.weeks[0].status")).isEqualTo("IN_PROGRESS");

        body(post("/api/v1/training/sessions/" + sessionId + "/sets").content(
                "{\"plannedExerciseId\":\"" + plannedDay1.get(0) + "\",\"setNumber\":1,\"repsDone\":8,\"weightKg\":42.5}"), token, 200);
        String finish = body(post("/api/v1/training/sessions/" + sessionId + "/finish").content(
                "{\"durationSeconds\":2700,\"rpe\":6,\"realDurations\":{\"" + plannedDay1.get(0) + "\":600},"
                        + "\"sets\":[{\"plannedExerciseId\":\"" + plannedDay1.get(0) + "\",\"setNumber\":2,\"repsDone\":8,\"weightKg\":42.5}]}"),
                token, 200);
        assertThat((String) JsonPath.read(finish, "$.session.status")).isEqualTo("COMPLETED");
        assertThat((Integer) JsonPath.read(finish, "$.session.xpAwarded")).isEqualTo(50 + 45 + 30);
        assertThat((Integer) JsonPath.read(finish, "$.experience.xpDelta")).isEqualTo(125);
        assertThat((Double) JsonPath.read(finish, "$.session.calories")).isPositive();
        assertThat((List<?>) JsonPath.read(finish, "$.session.sets")).hasSize(2);
        assertThat((List<?>) JsonPath.read(finish, "$.recommendations")).hasSize(1);
        mvc.perform(auth(get("/api/v1/me"), token)).andExpect(jsonPath("$.level").value(2))
                .andExpect(jsonPath("$.levelXp").value(25));
        mvc.perform(auth(post("/api/v1/training/sessions/" + sessionId + "/finish")
                        .content("{\"durationSeconds\":60,\"rpe\":5}"), token))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("SESSION_ALREADY_COMPLETED"));

        String completed = body(get("/api/v1/routines/" + routineId), token, 200);
        assertThat((String) JsonPath.read(completed, "$.weeks[0].days[0].status")).isEqualTo("COMPLETED");
        assertThat((Integer) JsonPath.read(completed, "$.completedDays")).isEqualTo(1);
        assertThat((Integer) JsonPath.read(completed, "$.weeks[0].days[0].exercises[1].realDurationSeconds")).isEqualTo(600);
        String nextPending = body(get("/api/v1/training/pending-day"), token, 200);
        assertThat((Integer) JsonPath.read(nextPending, "$.dayNumber")).isEqualTo(3);

        // Historial con el día entrenado y récords: la primera vez marca la referencia, no un récord
        String named = body(get("/api/v1/training/history"), token, 200);
        assertThat((Integer) JsonPath.read(named, "$.totalItems")).isEqualTo(1);
        assertThat((String) JsonPath.read(named, "$.items[0].session.id")).isEqualTo(sessionId);
        assertThat((Integer) JsonPath.read(named, "$.items[0].dayNumber")).isEqualTo(1);
        assertThat((List<?>) JsonPath.read(named, "$.items[0].records")).isEmpty();
        String records = body(get("/api/v1/training/records"), token, 200);
        assertThat((List<?>) JsonPath.read(records, "$")).hasSize(1);
        assertThat((Double) JsonPath.read(records, "$[0].weightKg")).isEqualTo(42.5);
        assertThat((String) JsonPath.read(records, "$[0].kind")).isEqualTo("WEIGHT");

        // Sugerencia de progresión: aplicar copia los ajustes a la rutina
        String recs = body(get("/api/v1/training/recommendations").param("applied", "false"), token, 200);
        String recId = JsonPath.read(recs, "$.items[0].id");
        assertThat((String) JsonPath.read(recs, "$.items[0].type")).isEqualTo("PROGRESSION");
        String applied = body(post("/api/v1/training/recommendations/" + recId + "/apply"), token, 200);
        assertThat((Boolean) JsonPath.read(applied, "$.applied")).isTrue();
        mvc.perform(auth(post("/api/v1/training/recommendations/" + recId + "/apply"), token))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("TRAINING_RECOMMENDATION_APPLIED"));

        // Desmarcar: resta exactamente la XP otorgada y el día deja de estar completado
        String unmark = body(post("/api/v1/training/sessions/" + sessionId + "/unmark"), token, 200);
        assertThat((Integer) JsonPath.read(unmark, "$.experience.xpDelta")).isEqualTo(-125);
        assertThat((String) JsonPath.read(unmark, "$.session.status")).isEqualTo("IN_PROGRESS");
        mvc.perform(auth(get("/api/v1/me"), token)).andExpect(jsonPath("$.level").value(1))
                .andExpect(jsonPath("$.levelXp").value(0));
        String reverted = body(get("/api/v1/routines/" + routineId), token, 200);
        assertThat((String) JsonPath.read(reverted, "$.weeks[0].days[0].status")).isEqualTo("IN_PROGRESS");
        mvc.perform(auth(delete("/api/v1/training/sessions/" + sessionId), token)).andExpect(status().isNoContent());
        String cancelled = body(get("/api/v1/routines/" + routineId), token, 200);
        assertThat((String) JsonPath.read(cancelled, "$.weeks[0].days[0].status")).isEqualTo("PENDING");
        String history = body(get("/api/v1/training/sessions"), token, 200);
        assertThat((Integer) JsonPath.read(history, "$.totalItems")).isZero();

        // Sesión libre
        String free = body(post("/api/v1/training/sessions"), token, 201);
        String freeId = JsonPath.read(free, "$.id");
        String freeDone = body(post("/api/v1/training/sessions/" + freeId + "/finish")
                .content("{\"durationSeconds\":1800,\"rpe\":5}"), token, 200);
        assertThat((String) JsonPath.read(freeDone, "$.session.type")).isEqualTo("FREE");

        // Check-in: solo el primero del día da XP
        String checkIn = "{\"sleepQuality\":4,\"stress\":2,\"energy\":4,\"soreness\":2,\"painZones\":[\"piernas\"]}";
        String first = body(put("/api/v1/training/check-ins/today").content(checkIn), token, 200);
        assertThat((Boolean) JsonPath.read(first, "$.firstOfDay")).isTrue();
        assertThat((Integer) JsonPath.read(first, "$.xpAwarded")).isEqualTo(20);
        String second = body(put("/api/v1/training/check-ins/today").content(checkIn), token, 200);
        assertThat((Integer) JsonPath.read(second, "$.xpAwarded")).isZero();
        body(get("/api/v1/training/check-ins/today"), token, 200);

        // Plan semanal (se normaliza al lunes) con cumplimiento
        String plan = body(put("/api/v1/training/weekly-plans/" + LocalDate.now(ZoneOffset.UTC))
                .content("{\"plannedSessions\":3,\"minutesPerSession\":45,\"intensity\":\"HIGH\"}"), token, 200);
        assertThat((String) JsonPath.read(plan, "$.weekStart")).isEqualTo(LocalDate.now(ZoneOffset.UTC).with(java.time.DayOfWeek.MONDAY).toString());
        assertThat((Integer) JsonPath.read(plan, "$.completedSessions")).isEqualTo(1);
        body(get("/api/v1/training/weekly-plans/" + LocalDate.now(ZoneOffset.UTC)), token, 200);

        // Generación: sin perfil de bienestar → 422; con perfil → propuesta; sin clave de IA → fallback
        mvc.perform(auth(post("/api/v1/routines/generate").content("{\"durationWeeks\":2,\"useAi\":false}"), token))
                .andExpect(status().is(422)).andExpect(jsonPath("$.code").value("TRAINING_PROFILE_REQUIRED"));
        String me = body(get("/api/v1/me"), token, 200);
        UUID userId = UUID.fromString(JsonPath.read(me, "$.id"));
        jdbc.sql("INSERT INTO perfil_bienestar_usuario (usuario_id, edad, sexo, peso_kg, altura_cm, imc, nivel_actividad,"
                        + " objetivo_principal, equipamiento_disponible, dias_disponibles_semana, minutos_por_sesion)"
                        + " VALUES (:u, 22, 'hombre', 75, 178, 23.7, 'moderado', 'Hipertrofia Muscular',"
                        + " ARRAY['mancuerna','barra'], 3, 60)")
                .param("u", userId).update();
        String proposal = body(post("/api/v1/routines/generate").content("{\"durationWeeks\":4,\"useAi\":false}"), token, 200);
        assertThat((List<?>) JsonPath.read(proposal, "$.weeks")).hasSize(4);
        assertThat((String) JsonPath.read(proposal, "$.weeks[3].type")).isEqualTo("DELOAD");
        assertThat((List<?>) JsonPath.read(proposal, "$.weeks[0].days[0].exercises")).isNotEmpty();
        String withAi = body(post("/api/v1/routines/generate").content("{\"durationWeeks\":1}"), token, 200);
        assertThat((Boolean) JsonPath.read(withAi, "$.aiRefined")).isFalse();
        assertThat((String) JsonPath.read(withAi, "$.aiNotice")).isNotBlank();
        String saved = body(post("/api/v1/routines").content(proposal), token, 201);
        assertThat((Integer) JsonPath.read(saved, "$.durationWeeks")).isEqualTo(4);

        // Administración restringida
        mvc.perform(auth(get("/api/v1/admin/exercises"), token)).andExpect(status().isForbidden());

        // Borrado lógico
        mvc.perform(auth(delete("/api/v1/routines/" + routineId), token)).andExpect(status().isNoContent());
        mvc.perform(auth(get("/api/v1/routines/" + routineId), token))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("ROUTINE_NOT_FOUND"));
    }

    @Test
    void communityCloneAndPrivacy() throws Exception {
        String author = register("author@example.com");
        String viewer = register("viewer@example.com");
        String page = body(get("/api/v1/exercises").param("size", "1"), author, 200);
        String exerciseId = JsonPath.read(page, "$.items[0].id");
        String routine = body(post("/api/v1/routines").content("""
                {"name":"Rutina pública","visibility":"PUBLIC","goal":"MAX_STRENGTH","weeks":[{"days":[
                  {"dayNumber":2,"exercises":[{"exerciseId":"%s","sets":5,"reps":3,"restSeconds":180}]}]}]}
                """.formatted(exerciseId)), author, 201);
        String routineId = JsonPath.read(routine, "$.id");

        String community = body(get("/api/v1/routines/community"), viewer, 200);
        assertThat((List<String>) JsonPath.read(community, "$.items[*].id")).contains(routineId);
        String visible = body(get("/api/v1/routines/" + routineId), viewer, 200);
        assertThat((Boolean) JsonPath.read(visible, "$.owned")).isFalse();
        mvc.perform(auth(patch("/api/v1/routines/" + routineId).content("{\"name\":\"Robada\"}"), viewer))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("ROUTINE_NOT_FOUND"));

        String clone = body(post("/api/v1/routines/" + routineId + "/clone"), viewer, 201);
        assertThat((String) JsonPath.read(clone, "$.origin.routineId")).isEqualTo(routineId);
        assertThat((String) JsonPath.read(clone, "$.origin.ownerName")).isEqualTo("Atleta a");
        assertThat((String) JsonPath.read(clone, "$.visibility")).isEqualTo("PRIVATE");
        assertThat((Boolean) JsonPath.read(clone, "$.owned")).isTrue();

        // El autor pasa su perfil a público y luego a privado: sus rutinas dejan de verse.
        mvc.perform(auth(patch("/api/v1/me").content("{\"privacy\":\"PUBLIC\"}"), author)).andExpect(status().isOk());
        mvc.perform(auth(patch("/api/v1/me").content("{\"privacy\":\"PRIVATE\"}"), author)).andExpect(status().isOk());
        String after = body(get("/api/v1/routines/community"), viewer, 200);
        assertThat((List<String>) JsonPath.read(after, "$.items[*].id")).doesNotContain(routineId);
        mvc.perform(auth(get("/api/v1/routines/" + routineId), viewer)).andExpect(status().isNotFound());
    }
}
