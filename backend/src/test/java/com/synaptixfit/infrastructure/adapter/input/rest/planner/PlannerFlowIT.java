package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.event.academic.ReviewScheduled;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Flujo del planificador sobre la aplicación completa y PostgreSQL real: valida el mapeo JPA de las
 * cinco tablas, las lecturas con JdbcClient de otros módulos, la migración V250 y los oyentes.
 * Sin llamadas a la IA (sin clave: las sugerencias usan el plan heurístico).
 */
@SpringBootTest
@AutoConfigureMockMvc
class PlannerFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;
    @Autowired
    private JdbcClient jdbc;
    @Autowired
    private ApplicationEventPublisher publisher;

    private String token;
    private UUID userId;
    private Instant tomorrow;

    @BeforeEach
    void register() throws Exception {
        String email = "planner-" + UUID.randomUUID() + "@example.com";
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Plani\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        token = JsonPath.read(body, "$.accessToken");
        userId = UUID.fromString(JsonPath.read(body, "$.user.id"));
        tomorrow = Instant.now().truncatedTo(ChronoUnit.DAYS).plus(Duration.ofDays(1)).plus(Duration.ofHours(10));
    }

    private MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + token);
    }

    private String json(MockHttpServletRequestBuilder request, String body, int status) throws Exception {
        return mvc.perform(auth(request).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().is(status))
                .andReturn().getResponse().getContentAsString();
    }

    @Test
    void blockLifecycleTimelineAndXp() throws Exception {
        Instant start = tomorrow;
        String created = json(post("/api/v1/planner/blocks"), """
                {"start":"%s","end":"%s","type":"STUDY","topics":"Matrices","priority":"HIGH","privateBlock":true}
                """.formatted(start, start.plus(Duration.ofMinutes(90))), 201);
        String blockId = JsonPath.read(created, "$.block.id");
        assertThat((Boolean) JsonPath.read(created, "$.block.privateBlock")).isTrue();
        assertThat((Integer) JsonPath.read(created, "$.block.xpReward")).isEqualTo(30);

        String overlapping = json(post("/api/v1/planner/blocks"), """
                {"start":"%s","end":"%s","type":"SPORT"}
                """.formatted(start.plus(Duration.ofHours(1)), start.plus(Duration.ofHours(2))), 201);
        assertThat((List<?>) JsonPath.read(overlapping, "$.conflicts")).hasSize(1);
        assertThat((Boolean) JsonPath.read(overlapping, "$.block.hasConflict")).isTrue();

        // Aún no ha empezado: no se puede marcar como hecho.
        mvc.perform(auth(put("/api/v1/planner/blocks/" + blockId + "/completion"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"completed\":true}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("BLOCK_IN_FUTURE"));
        // Se lleva a hace dos horas (ya pasó sin hacerse) y entonces sí.
        Instant past = Instant.now().minus(Duration.ofHours(2)).truncatedTo(ChronoUnit.MINUTES);
        jdbc.sql("UPDATE horarios_academicos SET hora_inicio = :s, hora_fin = :e WHERE id = :id")
                .param("s", java.sql.Timestamp.from(past))
                .param("e", java.sql.Timestamp.from(past.plus(Duration.ofMinutes(90))))
                .param("id", java.util.UUID.fromString(blockId)).update();
        mvc.perform(auth(get("/api/v1/planner/blocks/" + blockId)))
                .andExpect(jsonPath("$.timeStatus").value("MISSED"));
        String done = json(put("/api/v1/planner/blocks/" + blockId + "/completion"), "{\"completed\":true}", 200);
        assertThat((Integer) JsonPath.read(done, "$.xpDelta")).isEqualTo(30);
        assertThat((Double) JsonPath.read(done, "$.block.metValue")).isEqualTo(1.3);
        assertThat((Object) JsonPath.read(done, "$.block.caloriesBurned")).isNull();
        mvc.perform(auth(get("/api/v1/me"))).andExpect(jsonPath("$.levelXp").value(30));

        mvc.perform(auth(get("/api/v1/planner/timeline")
                        .param("from", past.minus(Duration.ofHours(1)).toString())
                        .param("to", start.plus(Duration.ofDays(1)).toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].kind").value("BLOCK"))
                .andExpect(jsonPath("$[0].title").value("Matrices"))
                .andExpect(jsonPath("$[0].completed").value(true));

        mvc.perform(auth(patch("/api/v1/planner/blocks/" + blockId + "/schedule")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"start\":\"" + start.plus(Duration.ofHours(5)) + "\"}")))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("BLOCK_COMPLETED_LOCKED"));

        json(put("/api/v1/planner/blocks/" + blockId + "/completion"), "{\"completed\":false}", 200);
        mvc.perform(auth(get("/api/v1/me"))).andExpect(jsonPath("$.levelXp").value(0));

        String moved = json(patch("/api/v1/planner/blocks/" + blockId + "/schedule"),
                "{\"start\":\"" + start.plus(Duration.ofHours(5)) + "\"}", 200);
        assertThat((List<?>) JsonPath.read(moved, "$.conflicts")).isEmpty();

        mvc.perform(auth(get("/api/v1/planner/blocks/" + UUID.randomUUID())))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("BLOCK_NOT_FOUND"));
        mvc.perform(auth(post("/api/v1/planner/blocks")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"start\":\"2020-01-01T10:00:00Z\",\"end\":\"2020-01-01T11:00:00Z\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("BLOCK_IN_PAST"));

        mvc.perform(auth(delete("/api/v1/planner/blocks/" + blockId))).andExpect(status().isNoContent());
    }

    @Test
    void deadlineCompletionChallengeSyncAndExamBlocks() throws Exception {
        String created = json(post("/api/v1/planner/deadlines"), """
                {"title":"Práctica 3","type":"ASSIGNMENT","dueAt":"%s","difficulty":"HIGH"}
                """.formatted(tomorrow.plus(Duration.ofDays(2))), 201);
        String deadlineId = JsonPath.read(created, "$.id");

        String done = json(put("/api/v1/planner/deadlines/" + deadlineId + "/completion"), "{\"completed\":true}", 200);
        assertThat((Integer) JsonPath.read(done, "$.xpDelta")).isEqualTo(30);
        assertThat((Boolean) JsonPath.read(done, "$.deadline.completed")).isTrue();

        mvc.perform(auth(get("/api/v1/planner/deadlines").param("upcoming", "true")))
                .andExpect(jsonPath("$.totalItems").value(0));
        mvc.perform(auth(get("/api/v1/planner/deadlines")))
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].difficulty").value("HIGH"));

        // La entrega es la fuente de verdad de los retos vinculados: nada del reto la desmarca (ADR 0028).
        mvc.perform(auth(get("/api/v1/planner/deadlines/" + deadlineId))).andExpect(jsonPath("$.completed").value(true));

        String exam = json(post("/api/v1/planner/blocks"), """
                {"start":"%s","end":"%s","type":"EXAM","deadlineTitle":"Parcial","location":"Aula 1"}
                """.formatted(tomorrow.plus(Duration.ofDays(3)), tomorrow.plus(Duration.ofDays(3)).plus(Duration.ofHours(2))), 201);
        String linked = JsonPath.read(exam, "$.block.deadlineId");
        mvc.perform(auth(get("/api/v1/planner/deadlines/" + linked)))
                .andExpect(jsonPath("$.type").value("EXAM"))
                .andExpect(jsonPath("$.title").value("Parcial"));
        mvc.perform(auth(get("/api/v1/planner/timeline")
                        .param("from", tomorrow.toString())
                        .param("to", tomorrow.plus(Duration.ofDays(5)).toString())))
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[*].kind", Matchers.everyItem(Matchers.is("DEADLINE"))));

        mvc.perform(auth(get("/api/v1/planner/ics/export")))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("text/calendar"))
                .andExpect(content().string(Matchers.containsString("SUMMARY:Parcial")));

        mvc.perform(auth(delete("/api/v1/planner/deadlines/" + deadlineId))).andExpect(status().isNoContent());
    }

    @Test
    void weeklyPlanLoadsRoutinesReviewsSuggestionsAndFocus() throws Exception {
        LocalDate day = tomorrow.atZone(ZoneId.of("Europe/Madrid")).toLocalDate();
        UUID subjectId = jdbc.sql("insert into asignaturas (usuario_id, nombre, codigo, dificultad_percibida) "
                        + "values (:u, 'Física', 'FIS', 4) returning id")
                .param("u", userId).query(UUID.class).single();
        UUID materialId = jdbc.sql("insert into materiales_estudio (usuario_id, asignatura_id, tipo_origen, origen_id, titulo) "
                        + "values (:u, :s, 'apunte', :o, 'Tema 1') returning id")
                .param("u", userId).param("s", subjectId).param("o", UUID.randomUUID()).query(UUID.class).single();
        UUID routineId = jdbc.sql("insert into rutinas (usuario_id, nombre, objetivo) values (:u, 'Rutina IT', 'Fuerza Máxima') "
                        + "returning id").param("u", userId).query(UUID.class).single();
        UUID weekId = jdbc.sql("insert into semanas_rutina (rutina_id, numero_semana) values (:r, 1) returning id")
                .param("r", routineId).query(UUID.class).single();
        jdbc.sql("insert into dias_rutina (semana_id, numero_dia, nombre) values (:w, 1, 'Empuje'), (:w, 2, 'Tirón')")
                .param("w", weekId).update();
        // Solo se reparten los días que se pueden entrenar (con ejercicios).
        jdbc.sql("insert into seleccion_de_ejercicios (rutina_id, dia_id, ejercicio_id, indice_orden) "
                        + "select :r, d.id, (select id from ejercicios order by nombre limit 1), 1 "
                        + "from dias_rutina d where d.semana_id = :w")
                .param("r", routineId).param("w", weekId).update();

        String distributed = json(post("/api/v1/planner/blocks/routine-distribution"), """
                {"routineId":"%s","weekdays":[1,2,3,4,5,6,7],"startDate":"%s","preferredStart":"19:00","durationMinutes":60}
                """.formatted(routineId, day), 201);
        assertThat((List<?>) JsonPath.read(distributed, "$")).hasSize(2);
        assertThat((String) JsonPath.read(distributed, "$[0].routineWeekId")).isEqualTo(weekId.toString());
        assertThat((String) JsonPath.read(distributed, "$[1].topics")).isEqualTo("Semana 1 · Tirón");

        publisher.publishEvent(new ReviewScheduled(userId, materialId, subjectId, "Repaso Tema 1",
                tomorrow.plus(Duration.ofHours(2)), Instant.now()));
        publisher.publishEvent(new ReviewScheduled(userId, materialId, subjectId, "Repaso Tema 1",
                tomorrow.plus(Duration.ofHours(4)), Instant.now()));
        mvc.perform(auth(get("/api/v1/planner/blocks")
                        .param("from", tomorrow.minus(Duration.ofHours(10)).toString())
                        .param("to", tomorrow.plus(Duration.ofDays(3)).toString())
                        .param("subjectId", subjectId.toString())))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].type").value("REVIEW"))
                .andExpect(jsonPath("$[0].studyMaterialId").value(materialId.toString()));

        // La experiencia de planificar llega sola al tener la semana 3 eventos planificados (ADR 0038); la
        // ruta antigua de «Cerrar semana» sigue respondiendo a las apps viejas y no la da otra vez.
        for (int i = 0; i < 3; i++) {
            Instant at = tomorrow.plus(Duration.ofHours(6 + i));
            json(post("/api/v1/planner/blocks"), """
                    {"start":"%s","end":"%s","type":"STUDY","topics":"Plan %d"}
                    """.formatted(at, at.plus(Duration.ofMinutes(45)), i), 201);
        }
        mvc.perform(auth(get("/api/v1/planner/plans/week/" + day))).andExpect(jsonPath("$.closed").value(true))
                .andExpect(jsonPath("$.xpAwarded").value(Matchers.greaterThanOrEqualTo(115)));
        String again = json(put("/api/v1/planner/plans/" + day), "{\"name\":\"Semana IT\",\"visibility\":\"FRIENDS\"}", 200);
        assertThat((Integer) JsonPath.read(again, "$.xpAwarded")).isZero();
        mvc.perform(auth(get("/api/v1/planner/plans"))).andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].visibility").value("FRIENDS"));

        String load = json(patch("/api/v1/planner/weekly-loads/" + day), "{\"stressLevel\":7,\"sleepHours\":6.5}", 200);
        assertThat((Integer) JsonPath.read(load, "$.stressLevel")).isEqualTo(7);
        json(post("/api/v1/planner/weekly-loads/" + day + "/sync"), "", 200);
        mvc.perform(auth(get("/api/v1/planner/weekly-loads").param("from", day.minusDays(14).toString())
                        .param("to", day.plusDays(7).toString())))
                .andExpect(jsonPath("$.length()").value(Matchers.greaterThanOrEqualTo(1)));
        mvc.perform(auth(get("/api/v1/planner/balance").param("weekStart", day.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.state").exists());
        mvc.perform(auth(get("/api/v1/planner/blocks/conflicts").param("weekStart", day.toString())))
                .andExpect(status().isOk());

        mvc.perform(auth(post("/api/v1/planner/suggestions")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"weekStart\":\"" + day.plusDays(7) + "\",\"studyHours\":8,\"sportSessions\":2}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.source").value("HEURISTIC"))
                .andExpect(jsonPath("$.sportSessions").value(2));

        json(post("/api/v1/planner/focus-sessions"), "{\"phase\":\"FOCUS\",\"durationMinutes\":25}", 201);
        mvc.perform(auth(get("/api/v1/planner/focus-sessions/stats")))
                .andExpect(jsonPath("$.today.focusMinutes").value(25))
                .andExpect(jsonPath("$.days.length()").value(7));
        // La recomendación del Pomodoro: sin carga física registrada, el ciclo de atención completo.
        mvc.perform(auth(get("/api/v1/planner/focus-sessions/plan")))
                .andExpect(jsonPath("$.focusMinutes").value(52))
                .andExpect(jsonPath("$.shortBreakMinutes").value(17))
                .andExpect(jsonPath("$.limitedByFatigue").value(false));
        // «Tu estudio» cuenta la concentración de la semana (la consulta corre sobre PostgreSQL).
        mvc.perform(auth(get("/api/v1/analytics/study-week")))
                .andExpect(jsonPath("$.focusMinutes").value(25))
                .andExpect(jsonPath("$.focusSessions").value(1))
                .andExpect(jsonPath("$.empty").value(false));

        // Sin fechas de semestre en el perfil académico, el escaneo de horario no se puede hacer.
        mvc.perform(multipart("/api/v1/planner/schedule-scan")
                        .file(new MockMultipartFile("file", "horario.pdf", "application/pdf", new byte[]{1, 2}))
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("SCHEDULE_SEMESTER_DATES_MISSING"));
    }
}
