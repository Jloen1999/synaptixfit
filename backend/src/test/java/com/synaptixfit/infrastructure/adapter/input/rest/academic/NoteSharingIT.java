package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
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
 * «Compartir» un apunte y la lista «Material» sobre PostgreSQL real (ADR 0064): pasar a un amigo, publicar en el muro
 * (el tipo «apunte» de la migración), el PDF y la disponibilidad de documentos de una asignatura en una petición.
 */
@SpringBootTest
@AutoConfigureMockMvc
class NoteSharingIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private record Account(UUID id, String token) {}

    private final String suffix = UUID.randomUUID().toString().substring(0, 8);

    private Account register(String name) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + name.toLowerCase() + suffix + "@example.com\","
                                + "\"password\":\"secret123\",\"fullName\":\"" + name + suffix + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        Account account = new Account(UUID.fromString(JsonPath.read(body, "$.user.id")),
                JsonPath.read(body, "$.accessToken"));
        mvc.perform(as(account, patch("/api/v1/me")).content("{\"privacy\":\"PUBLIC\"}")).andExpect(status().isOk());
        return account;
    }

    private static MockHttpServletRequestBuilder as(Account a, MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + a.token()).contentType(MediaType.APPLICATION_JSON);
    }

    private String body(Account a, MockHttpServletRequestBuilder request, int status) throws Exception {
        return mvc.perform(as(a, request)).andExpect(status().is(status))
                .andReturn().getResponse().getContentAsString();
    }

    @Test
    void aPrivateNoteGoesToAFriendToTheWallAndToPdf() throws Exception {
        Account ana = register("Ana");
        Account bea = register("Bea");
        Account carl = register("Carl");
        String friendshipId = befriend(bea, ana);

        String subjectId = JsonPath.read(body(ana, post("/api/v1/subjects")
                .content("{\"name\":\"Bases de datos\",\"credits\":6}"), 201), "$.id");
        String noteId = JsonPath.read(body(ana, post("/api/v1/notes").content("""
                {"subjectId":"%s","title":"Normalización","content":"# 1FN\\nValores **atómicos**",
                 "visibility":"PRIVATE"}""".formatted(subjectId)), 201), "$.id");

        // Una sola petición con los documentos de IA de toda la asignatura (sin documentos todavía).
        mvc.perform(as(ana, get("/api/v1/study/subjects/" + subjectId + "/documents")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(as(bea, get("/api/v1/study/subjects/" + subjectId + "/documents")))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("SUBJECT_NOT_FOUND"));

        // Con un amigo: Bea lo lee aunque sea privado; Carl (no amigo) ni lo recibe ni lo lee.
        mvc.perform(as(bea, get("/api/v1/notes/shared/" + noteId))).andExpect(status().isNotFound());
        mvc.perform(as(ana, post("/api/v1/notes/" + noteId + "/recipients")
                        .content("{\"friendId\":\"" + carl.id() + "\"}")))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("NOTE_RECIPIENT_NOT_FRIEND"));
        mvc.perform(as(ana, post("/api/v1/notes/" + noteId + "/recipients")
                        .content("{\"friendId\":\"" + bea.id() + "\"}")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.friendId").value(bea.id().toString()))
                .andExpect(jsonPath("$.friendName").value("Bea" + suffix));
        mvc.perform(as(ana, post("/api/v1/notes/" + noteId + "/recipients")
                .content("{\"friendId\":\"" + bea.id() + "\"}"))).andExpect(status().isOk());
        mvc.perform(as(bea, get("/api/v1/notes/shared/" + noteId)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.title").value("Normalización"));
        mvc.perform(as(carl, get("/api/v1/notes/shared/" + noteId))).andExpect(status().isNotFound());

        // Un apunte ajeno no existe para quien intenta compartirlo.
        for (String action : new String[] {"/recipients", "/wall"}) {
            mvc.perform(as(bea, post("/api/v1/notes/" + noteId + action)
                            .content("{\"friendId\":\"" + carl.id() + "\"}")))
                    .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("NOTE_NOT_FOUND"));
        }

        // Dejar de ser amigas quita el acceso para siempre: volver a serlo no lo devuelve.
        body(ana, delete("/api/v1/social/friends/" + friendshipId), 204);
        mvc.perform(as(bea, get("/api/v1/notes/shared/" + noteId))).andExpect(status().isNotFound());
        befriend(ana, bea);
        mvc.perform(as(bea, get("/api/v1/notes/shared/" + noteId))).andExpect(status().isNotFound());

        // En el muro: el apunte pasa a público, se publica una vez y Carl ya puede abrirlo.
        mvc.perform(as(ana, post("/api/v1/notes/" + noteId + "/wall").content("{}")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.alreadyShared").value(false))
                .andExpect(jsonPath("$.visibility").value("PUBLIC"));
        mvc.perform(as(ana, post("/api/v1/notes/" + noteId + "/wall").content("{\"comment\":\"Otra vez\"}")))
                .andExpect(jsonPath("$.alreadyShared").value(true));
        mvc.perform(as(carl, get("/api/v1/social/posts").param("authorId", ana.id().toString())))
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].type").value("NOTE"))
                .andExpect(jsonPath("$.items[0].description").value("Normalización"));
        mvc.perform(as(carl, get("/api/v1/notes/shared/" + noteId))).andExpect(status().isOk());

        // En PDF, solo para su autora.
        byte[] pdf = mvc.perform(as(ana, get("/api/v1/notes/" + noteId + "/pdf")))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "application/pdf"))
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString(".pdf")))
                .andReturn().getResponse().getContentAsByteArray();
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        mvc.perform(as(bea, get("/api/v1/notes/" + noteId + "/pdf")))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("NOTE_NOT_FOUND"));

        // Al borrar el apunte, su publicación sale del muro.
        body(ana, delete("/api/v1/notes/" + noteId), 204);
        mvc.perform(as(carl, get("/api/v1/social/posts").param("authorId", ana.id().toString())))
                .andExpect(jsonPath("$.totalItems").value(0));
    }

    @Test
    void aBlockRevokesTooAndAPrivateProfileCannotUseTheWall() throws Exception {
        Account ana = register("Ana");
        Account bea = register("Bea");
        befriend(bea, ana);
        String noteId = JsonPath.read(body(ana, post("/api/v1/notes")
                .content("{\"title\":\"Transacciones\",\"content\":\"ACID\",\"visibility\":\"PRIVATE\"}"), 201), "$.id");
        body(ana, post("/api/v1/notes/" + noteId + "/recipients").content("{\"friendId\":\"" + bea.id() + "\"}"),
                200);
        mvc.perform(as(bea, get("/api/v1/notes/shared/" + noteId))).andExpect(status().isOk());

        // Bloquear también quita el acceso; desbloquear y volver a ser amigas no lo devuelve.
        String block = body(ana, post("/api/v1/social/friends/blocks").content("{\"userId\":\"" + bea.id() + "\"}"),
                200);
        mvc.perform(as(bea, get("/api/v1/notes/shared/" + noteId))).andExpect(status().isNotFound());
        body(ana, delete("/api/v1/social/friends/" + JsonPath.read(block, "$.id")), 204);
        befriend(bea, ana);
        mvc.perform(as(bea, get("/api/v1/notes/shared/" + noteId))).andExpect(status().isNotFound());

        // Con el perfil privado no se publica algo que nadie puede abrir.
        mvc.perform(as(ana, patch("/api/v1/me")).content("{\"privacy\":\"PRIVATE\"}")).andExpect(status().isOk());
        mvc.perform(as(ana, post("/api/v1/notes/" + noteId + "/wall").content("{}")))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("NOTE_WALL_PROFILE_PRIVATE"));
    }

    /** {@code from} pide amistad y {@code to} la acepta; devuelve el id de la amistad. */
    private String befriend(Account from, Account to) throws Exception {
        String request = body(from, post("/api/v1/social/friends/requests")
                .content("{\"userId\":\"" + to.id() + "\"}"), 201);
        String id = JsonPath.read(request, "$.id");
        body(to, post("/api/v1/social/friends/" + id + "/accept"), 200);
        return id;
    }
}
