package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
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
 * Visibilidad efectiva del contenido compartido (apuntes, rutinas y retos) sobre PostgreSQL real: la
 * más restrictiva entre el contenido y el perfil del autor, y nunca con un bloqueo en cualquier sentido.
 */
@SpringBootTest
@AutoConfigureMockMvc
class SharedContentVisibilityIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private record Account(UUID id, String token) {}

    private final String suffix = UUID.randomUUID().toString().substring(0, 8);

    private Account register(String name, String privacy) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + name.toLowerCase() + suffix + "@example.com\","
                                + "\"password\":\"secret123\",\"fullName\":\"" + name + suffix + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        Account account = new Account(UUID.fromString(JsonPath.read(body, "$.user.id")),
                JsonPath.read(body, "$.accessToken"));
        setPrivacy(account, privacy);
        return account;
    }

    private void setPrivacy(Account a, String privacy) throws Exception {
        mvc.perform(as(a, patch("/api/v1/me")).content("{\"privacy\":\"" + privacy + "\"}"))
                .andExpect(status().isOk());
    }

    private static MockHttpServletRequestBuilder as(Account a, MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + a.token()).contentType(MediaType.APPLICATION_JSON);
    }

    private String body(Account a, MockHttpServletRequestBuilder request, int status) throws Exception {
        return mvc.perform(as(a, request)).andExpect(status().is(status))
                .andReturn().getResponse().getContentAsString();
    }

    private String note(Account a, String title, String visibility) throws Exception {
        String created = body(a, post("/api/v1/notes").content("""
                {"title":"%s","content":"# %s\\nTexto **importante** del tema","visibility":"%s"}"""
                .formatted(title, title, visibility)), 201);
        return JsonPath.read(created, "$.id");
    }

    private List<String> sharedIds(Account a, String query) throws Exception {
        return JsonPath.read(body(a, get("/api/v1/notes/shared" + query), 200), "$.items[*].id");
    }

    private void befriend(Account from, Account to) throws Exception {
        String request = body(from, post("/api/v1/social/friends/requests")
                .content("{\"userId\":\"" + to.id() + "\"}"), 201);
        body(to, post("/api/v1/social/friends/" + JsonPath.read(request, "$.id") + "/accept"), 200);
    }

    @Test
    void notesRoutinesAndChallengesFollowTheProfileAndBlocks() throws Exception {
        Account ana = register("Ana", "PUBLIC");
        Account bea = register("Bea", "PUBLIC");
        Account carl = register("Carl", "PUBLIC");
        Account dani = register("Dani", "PUBLIC");
        befriend(bea, ana);

        // Ana comparte en público y después pasa su perfil a «solo amigos».
        String anaNote = note(ana, "Normalizacion", "PUBLIC");
        String exerciseId = JsonPath.read(body(ana, get("/api/v1/exercises").param("size", "1"), 200),
                "$.items[0].id");
        String routineId = JsonPath.read(body(ana, post("/api/v1/routines").content("""
                {"name":"Rutina de Ana","visibility":"PUBLIC","goal":"MAX_STRENGTH","weeks":[{"days":[
                  {"dayNumber":2,"exercises":[{"exerciseId":"%s","sets":5,"reps":3,"restSeconds":180}]}]}]}
                """.formatted(exerciseId)), 201), "$.id");
        String challengeId = JsonPath.read(body(ana, post("/api/v1/challenges").content("""
                {"title":"Reto de Ana","visibility":"PUBLIC","endAt":"%s"}"""
                .formatted(Instant.now().plus(7, ChronoUnit.DAYS))), 201), "$.id");
        setPrivacy(ana, "FRIENDS");

        // Carl (no es amigo) ya no ve nada de Ana: ni listado, ni detalle, ni copia, ni rutina, ni reto.
        assertThat(sharedIds(carl, "")).doesNotContain(anaNote);
        assertThat(sharedIds(carl, "?scope=PUBLIC")).doesNotContain(anaNote);
        mvc.perform(as(carl, get("/api/v1/notes/shared/" + anaNote)))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("NOTE_NOT_FOUND"));
        mvc.perform(as(carl, post("/api/v1/notes/shared/" + anaNote + "/copy")))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("NOTE_NOT_FOUND"));
        assertThat((List<String>) JsonPath.read(body(carl, get("/api/v1/routines/community"), 200), "$.items[*].id"))
                .doesNotContain(routineId);
        mvc.perform(as(carl, get("/api/v1/routines/" + routineId))).andExpect(status().isNotFound());
        assertThat((List<String>) JsonPath.read(body(carl, get("/api/v1/challenges/community"), 200),
                "$.items[*].id")).doesNotContain(challengeId);
        mvc.perform(as(carl, get("/api/v1/challenges/" + challengeId))).andExpect(status().isNotFound());

        // Bea (amiga) lo ve en «Amigos», no en «Comunidad»; el resumen no trae el contenido.
        assertThat(sharedIds(bea, "?scope=FRIENDS")).contains(anaNote);
        assertThat(sharedIds(bea, "?scope=PUBLIC")).doesNotContain(anaNote);
        mvc.perform(as(bea, get("/api/v1/notes/shared").param("authorId", ana.id().toString())))
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].authorId").value(ana.id().toString()))
                .andExpect(jsonPath("$.items[0].visibility").value("FRIENDS"))
                .andExpect(jsonPath("$.items[0].excerpt").value("Normalizacion Texto importante del tema"))
                .andExpect(jsonPath("$.items[0].content").doesNotExist());
        mvc.perform(as(bea, get("/api/v1/notes/shared/" + anaNote)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").value("# Normalizacion\nTexto **importante** del tema"))
                .andExpect(jsonPath("$.mine").value(false));
        mvc.perform(as(bea, post("/api/v1/notes/shared/" + anaNote + "/copy")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.visibility").value("PRIVATE"))
                .andExpect(jsonPath("$.title").value("Normalizacion"));
        assertThat((List<String>) JsonPath.read(body(bea, get("/api/v1/routines/community"), 200), "$.items[*].id"))
                .contains(routineId);
        assertThat((List<String>) JsonPath.read(body(bea, get("/api/v1/challenges/community"), 200),
                "$.items[*].id")).contains(challengeId);

        // Ana ve lo suyo que otros pueden ver; con el perfil «solo amigos» no puede publicar en abierto.
        assertThat(sharedIds(ana, "?authorId=" + ana.id())).containsExactly(anaNote);
        mvc.perform(as(ana, post("/api/v1/notes")).content("{\"title\":\"Otro\",\"visibility\":\"PUBLIC\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.visibility").value("FRIENDS"));

        // Bloqueo: Carl bloquea a Dani y ninguno de los dos ve lo público del otro.
        String daniNote = note(dani, "Apunte de Dani", "PUBLIC");
        String carlNote = note(carl, "Apunte de Carl", "PUBLIC");
        assertThat(sharedIds(carl, "?scope=PUBLIC")).contains(daniNote);
        body(carl, post("/api/v1/social/friends/blocks").content("{\"userId\":\"" + dani.id() + "\"}"), 200);
        assertThat(sharedIds(carl, "?scope=PUBLIC")).doesNotContain(daniNote);
        assertThat(sharedIds(dani, "")).doesNotContain(carlNote);
        mvc.perform(as(dani, get("/api/v1/notes/shared/" + carlNote))).andExpect(status().isNotFound());
        assertThat(sharedIds(bea, "?scope=PUBLIC")).contains(daniNote, carlNote);
    }
}
