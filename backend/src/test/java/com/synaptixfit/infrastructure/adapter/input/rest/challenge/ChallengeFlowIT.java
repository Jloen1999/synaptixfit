package com.synaptixfit.infrastructure.adapter.input.rest.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.event.planner.DeadlineCompletionChanged;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.hamcrest.Matchers;
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
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Flujo completo de retos e insignias sobre PostgreSQL real: valida el mapeo JPA de
 * {@code retos}, {@code hitos_de_reto}, {@code progreso_de_reto}, {@code insignias} y
 * {@code usuario_insignias}, el XP con anti-farmeo y la sincronización por eventos.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ChallengeFlowIT {

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

    private String register(String email, String name) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"" + name + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private static MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder b, String token) {
        return b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON);
    }

    private String createChallenge(String token, String json) throws Exception {
        return mvc.perform(auth(post("/api/v1/challenges"), token).content(json))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
    }

    private int levelXp(String token) throws Exception {
        String me = mvc.perform(auth(get("/api/v1/me"), token)).andReturn().getResponse().getContentAsString();
        return JsonPath.read(me, "$.levelXp");
    }

    @Test
    void challengeWithTasksIsCompletedThroughItsTasksWithAntiFarmingXp() throws Exception {
        String token = register("retos-it@example.com", "Retadora");
        String end = Instant.now().plus(7, ChronoUnit.DAYS).toString();

        String created = createChallenge(token, """
                {"title":"Preparar el parcial","difficulty":"HIGH","visibility":"PRIVATE","endAt":"%s",
                 "milestones":[
                   {"title":"Leer el tema 1","difficulty":"MEDIUM"},
                   {"title":"Hacer ejercicios","difficulty":"MEDIUM","dependsOn":[0],"conditionType":"AND"}
                 ]}""".formatted(end));
        String id = JsonPath.read(created, "$.id");
        String first = JsonPath.read(created, "$.milestones[0].id");
        String second = JsonPath.read(created, "$.milestones[1].id");
        assertThat((Double) JsonPath.read(created, "$.milestones[0].weight")).isEqualTo(50.0);
        assertThat((String) JsonPath.read(created, "$.milestones[0].status")).isEqualTo("AVAILABLE");
        assertThat((String) JsonPath.read(created, "$.milestones[1].status")).isEqualTo("LOCKED");
        assertThat((String) JsonPath.read(created, "$.type")).isEqualTo("FITNESS");
        // Con tareas no avanza con los entrenamientos aunque sea de fitness.
        assertThat((Boolean) JsonPath.read(created, "$.tracksTrainingSessions")).isFalse();

        // Una tarea bloqueada no se puede completar.
        mvc.perform(auth(post("/api/v1/challenges/{id}/milestones/{m}/complete", id, second), token))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("MILESTONE_LOCKED"));

        mvc.perform(auth(post("/api/v1/challenges/{id}/milestones/{m}/complete", id, first), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.xpDelta").value(40))
                .andExpect(jsonPath("$.unlockedMilestoneIds[0]").value(second))
                .andExpect(jsonPath("$.challenge.progress").value(50.0));

        mvc.perform(auth(post("/api/v1/challenges/{id}/progress", id), token)
                        .content("{\"milestoneId\":\"" + second + "\",\"amount\":50}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.challenge.progress").value(75.0))
                .andExpect(jsonPath("$.challenge.currentStreak").value(1));

        mvc.perform(auth(post("/api/v1/challenges/{id}/milestones/{m}/complete", id, second), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.challengeCompleted").value(true))
                .andExpect(jsonPath("$.challenge.status").value("COMPLETED"))
                .andExpect(jsonPath("$.challenge.completedMilestoneCount").value(2));
        assertThat(levelXp(token)).isEqualTo(80);

        // Repetir no da más XP (idempotente).
        mvc.perform(auth(post("/api/v1/challenges/{id}/complete", id), token))
                .andExpect(jsonPath("$.xpDelta").value(0));

        // El servidor ya evaluó las insignias al completarse el reto (evento ChallengeCompleted): la
        // evaluación manual sigue funcionando pero no la vuelve a otorgar.
        mvc.perform(auth(post("/api/v1/badges/evaluate"), token).param("zone", "Europe/Madrid"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.newlyEarned[*].name", Matchers.not(Matchers.hasItem("Primer reto"))))
                .andExpect(jsonPath("$.streak.currentDays").value(0));
        mvc.perform(auth(get("/api/v1/badges/unnotified"), token))
                .andExpect(jsonPath("$[0].name").value("Primer reto"));
        String badgeId = JsonPath.read(mvc.perform(auth(get("/api/v1/badges/mine"), token))
                .andReturn().getResponse().getContentAsString(), "$[0].id");
        mvc.perform(auth(post("/api/v1/badges/notified"), token).content("{\"badgeIds\":[\"" + badgeId + "\"]}"))
                .andExpect(status().isNoContent());
        mvc.perform(auth(get("/api/v1/badges/unnotified"), token)).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(auth(get("/api/v1/badges"), token))
                .andExpect(jsonPath("$[?(@.name == 'Planificador Maestro')].criterionType").value("PLAN_ADHERENCE_WEEKS"));

        // Descompletar resta exactamente lo otorgado y el reto deja de estar completado.
        mvc.perform(auth(post("/api/v1/challenges/{id}/milestones/{m}/uncomplete", id, first), token))
                .andExpect(jsonPath("$.xpDelta").value(-40))
                .andExpect(jsonPath("$.challenge.completed").value(false));
        assertThat(levelXp(token)).isEqualTo(40);

        mvc.perform(auth(get("/api/v1/challenges/{id}/progress", id), token))
                .andExpect(jsonPath("$[0].milestoneId").value(second))
                .andExpect(jsonPath("$[0].amount").value(50.0));

        // Reordenar respeta la restricción única (reto_id, indice_orden).
        mvc.perform(auth(put("/api/v1/challenges/{id}/milestones/order", id), token)
                        .content("{\"milestoneIds\":[\"" + second + "\",\"" + first + "\"]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.milestones[0].id").value(second))
                .andExpect(jsonPath("$.milestones[0].order").value(1));

        // Reemplazar tareas: se conserva la primera (por id), se quita la otra (resta su XP) y se añade una.
        mvc.perform(auth(put("/api/v1/challenges/{id}/milestones", id), token).content("""
                        {"milestones":[
                          {"id":"%s","title":"Leer el tema 1","weight":40},
                          {"title":"Simulacro final","weight":60,"difficulty":"LOW","dependsOn":[0]}
                        ]}""".formatted(first)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.xpDelta").value(-40))
                .andExpect(jsonPath("$.challenge.milestones.length()").value(2));
        assertThat(levelXp(token)).isZero();

        // Los pesos ya no se eligen: los manda la dificultad y el campo antiguo se ignora (ADR 0028).
        mvc.perform(auth(put("/api/v1/challenges/{id}/milestones", id), token).content("""
                        {"milestones":[{"title":"Tarea A","weight":30},{"title":"Tarea B","weight":30,"difficulty":"HIGH"}]}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.challenge.milestones[0].weight").value(36.36))
                .andExpect(jsonPath("$.challenge.milestones[1].weight").value(63.64))
                .andExpect(jsonPath("$.challenge.milestones[1].xpReward").value(70));

        mvc.perform(auth(get("/api/v1/challenges"), token).param("status", "ACTIVE").param("tasks", "WITH"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1));
        mvc.perform(auth(get("/api/v1/challenges"), token).param("tasks", "WITHOUT"))
                .andExpect(jsonPath("$.totalItems").value(0));
        mvc.perform(auth(get("/api/v1/challenges/summary"), token))
                .andExpect(jsonPath("$.active").value(1));
        mvc.perform(auth(get("/api/v1/challenges/milestones/pending"), token))
                .andExpect(jsonPath("$.length()").value(2));
        // Los registros de progreso de la tarea quitada se borran en cascada con ella.
        mvc.perform(auth(get("/api/v1/challenges/{id}/progress", id), token))
                .andExpect(jsonPath("$.length()").value(0));

        mvc.perform(auth(delete("/api/v1/challenges/{id}", id), token)).andExpect(status().isNoContent());
        mvc.perform(auth(get("/api/v1/challenges/{id}", id), token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("CHALLENGE_NOT_FOUND"));
        mvc.perform(auth(get("/api/v1/streak"), token).param("zone", "Nowhere/City"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("STREAK_INVALID_ZONE"));
    }

    @Test
    void periodRuleUpcomingStatusAndLinksDueWithinThePeriod() throws Exception {
        String token = register("retos-periodo@example.com", "Periodo");
        String me = mvc.perform(auth(get("/api/v1/me"), token)).andReturn().getResponse().getContentAsString();
        UUID userId = UUID.fromString(JsonPath.read(me, "$.id"));
        UUID lateDeadline = UUID.randomUUID();
        UUID doneDeadline = UUID.randomUUID();
        jdbc.sql("""
                        insert into entregas_examenes (id, usuario_id, titulo, tipo, fecha_limite, esta_completado)
                        values (:late, :user, 'Entrega tardía', 'entrega', :lateDue, false),
                               (:done, :user, 'Entrega hecha', 'entrega', :doneDue, true)
                        """)
                .param("late", lateDeadline).param("done", doneDeadline).param("user", userId)
                .param("lateDue", OffsetDateTime.now(ZoneOffset.UTC).plusDays(20))
                .param("doneDue", OffsetDateTime.now(ZoneOffset.UTC).plusDays(2))
                .update();
        String end = Instant.now().plus(7, ChronoUnit.DAYS).toString();

        // Una entrega que vence después del fin del reto nunca podría completarlo a tiempo.
        mvc.perform(auth(post("/api/v1/challenges"), token).content("""
                        {"title":"Entregar a tiempo","endAt":"%s","milestones":[
                          {"title":"Entregar","linkedEntityType":"DELIVERY","linkedEntityId":"%s"}]}"""
                        .formatted(end, lateDeadline)))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("CHALLENGE_LINK_OUTSIDE_PERIOD"));

        // Vincular una entrega ya hecha deja la tarea completada al crearla; no se desmarca a mano.
        String created = createChallenge(token, """
                {"title":"Entregar a tiempo","endAt":"%s","milestones":[
                  {"title":"Entregar","linkedEntityType":"DELIVERY","linkedEntityId":"%s"},
                  {"title":"Repasar"}]}""".formatted(end, doneDeadline));
        String id = JsonPath.read(created, "$.id");
        String linked = JsonPath.read(created, "$.milestones[0].id");
        assertThat((Boolean) JsonPath.read(created, "$.milestones[0].completed")).isTrue();
        assertThat((Boolean) JsonPath.read(created, "$.milestones[0].completedByLink")).isTrue();
        assertThat((String) JsonPath.read(created, "$.milestones[0].linkTitle")).isEqualTo("Entrega hecha");
        mvc.perform(auth(post("/api/v1/challenges/{id}/milestones/{m}/uncomplete", id, linked), token))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("MILESTONE_LINKED"));

        // Un reto que aún no empieza se ve como UPCOMING y no se puede completar.
        String upcoming = createChallenge(token, """
                {"title":"Reto de la semana que viene","startAt":"%s","endAt":"%s"}"""
                .formatted(Instant.now().plus(3, ChronoUnit.DAYS), Instant.now().plus(9, ChronoUnit.DAYS)));
        assertThat((String) JsonPath.read(upcoming, "$.status")).isEqualTo("UPCOMING");
        mvc.perform(auth(post("/api/v1/challenges/{id}/complete", (String) JsonPath.read(upcoming, "$.id")), token))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("CHALLENGE_NOT_STARTED"));
        mvc.perform(auth(get("/api/v1/challenges"), token).param("status", "UPCOMING"))
                .andExpect(jsonPath("$.totalItems").value(1));
        mvc.perform(auth(get("/api/v1/challenges/summary"), token))
                .andExpect(jsonPath("$.active").value(2))
                .andExpect(jsonPath("$.upcoming").value(1));

        // «Registrar progreso» como valor absoluto: «llevas 40 % → pon 60 %».
        String plain = createChallenge(token, """
                {"title":"Leer un libro","endAt":"%s"}""".formatted(end));
        String plainId = JsonPath.read(plain, "$.id");
        mvc.perform(auth(post("/api/v1/challenges/{id}/progress", plainId), token).content("{\"value\":40}"))
                .andExpect(jsonPath("$.challenge.progress").value(40.0));
        mvc.perform(auth(post("/api/v1/challenges/{id}/progress", plainId), token).content("{\"value\":60}"))
                .andExpect(jsonPath("$.challenge.progress").value(60.0));
    }

    @Test
    void deadlineEventCompletesLinkedChallengeAndCommunityCanClone() throws Exception {
        String owner = register("retos-owner@example.com", "Propietaria");
        String viewer = register("retos-viewer@example.com", "Visitante");
        // Un perfil privado no comparte nada: la propietaria abre su perfil.
        mvc.perform(auth(patch("/api/v1/me"), owner).content("{\"privacy\":\"PUBLIC\"}")).andExpect(status().isOk());
        String me = mvc.perform(auth(get("/api/v1/me"), owner)).andReturn().getResponse().getContentAsString();
        UUID ownerId = UUID.fromString(JsonPath.read(me, "$.id"));
        UUID deadlineId = UUID.randomUUID();
        jdbc.sql("""
                        insert into entregas_examenes (id, usuario_id, titulo, tipo, fecha_limite)
                        values (:id, :user, 'Entrega practica 1', 'entrega', :limit)
                        """)
                .param("id", deadlineId).param("user", ownerId)
                .param("limit", OffsetDateTime.now(ZoneOffset.UTC).plusDays(3))
                .update();
        String end = Instant.now().plus(7, ChronoUnit.DAYS).toString();

        // Un vínculo a una entrega ajena o inexistente se rechaza.
        mvc.perform(auth(post("/api/v1/challenges"), viewer).content("""
                        {"title":"Entregar la practica","endAt":"%s","linkedEntityType":"DELIVERY","linkedEntityId":"%s"}"""
                        .formatted(end, deadlineId)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("CHALLENGE_LINK_NOT_FOUND"));

        String created = createChallenge(owner, """
                {"title":"Entregar la practica","difficulty":"MEDIUM","visibility":"PUBLIC","endAt":"%s",
                 "linkedEntityType":"DELIVERY","linkedEntityId":"%s"}""".formatted(end, deadlineId));
        String id = JsonPath.read(created, "$.id");

        // Sin tareas y vinculado, lo completa su entrega, no un toque; la respuesta trae la entrega.
        mvc.perform(auth(post("/api/v1/challenges/{id}/complete", id), owner))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("CHALLENGE_LINKED"));
        mvc.perform(auth(get("/api/v1/challenges/{id}", id), owner))
                .andExpect(jsonPath("$.completedByLink").value(true))
                .andExpect(jsonPath("$.linkTitle").value("Entrega practica 1"))
                .andExpect(jsonPath("$.linkCompleted").value(false));

        // El planificador publica el evento; el reto se completa con su XP, una sola vez.
        publisher.publishEvent(new DeadlineCompletionChanged(ownerId, deadlineId, true, Instant.now()));
        publisher.publishEvent(new DeadlineCompletionChanged(ownerId, deadlineId, true, Instant.now()));
        mvc.perform(auth(get("/api/v1/challenges/{id}", id), owner))
                .andExpect(jsonPath("$.completed").value(true))
                .andExpect(jsonPath("$.xpAwarded").value(40));
        assertThat(levelXp(owner)).isEqualTo(40);

        publisher.publishEvent(new DeadlineCompletionChanged(ownerId, deadlineId, false, Instant.now()));
        assertThat(levelXp(owner)).isZero();

        // Comunidad: el reto público es visible y clonable por otro usuario.
        mvc.perform(auth(get("/api/v1/challenges/community"), viewer))
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].id").value(id))
                .andExpect(jsonPath("$.items[0].ownerName").value("Propietaria"))
                .andExpect(jsonPath("$.items[0].owned").value(false));
        mvc.perform(auth(get("/api/v1/challenges/{id}", id), viewer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.owned").value(false))
                .andExpect(jsonPath("$.linkTitle").doesNotExist());
        mvc.perform(auth(post("/api/v1/challenges/{id}/clone", id), viewer))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.originId").value(id))
                .andExpect(jsonPath("$.originOwnerName").value("Propietaria"))
                .andExpect(jsonPath("$.visibility").value("PRIVATE"))
                .andExpect(jsonPath("$.linkedEntityId").doesNotExist());

        // Al pasar el perfil a privado, sus retos dejan de ser visibles (evento UserPrivacyChanged).
        mvc.perform(auth(patch("/api/v1/me"), owner).content("{\"privacy\":\"PUBLIC\"}")).andExpect(status().isOk());
        mvc.perform(auth(patch("/api/v1/me"), owner).content("{\"privacy\":\"PRIVATE\"}")).andExpect(status().isOk());
        mvc.perform(auth(get("/api/v1/challenges/{id}", id), owner))
                .andExpect(jsonPath("$.visibility").value("PRIVATE"));
        mvc.perform(auth(get("/api/v1/challenges/{id}", id), viewer))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("CHALLENGE_NOT_FOUND"));
    }
}
