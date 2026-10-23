package com.synaptixfit.infrastructure.adapter.input.rest.social;

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
 * Flujo social completo sobre PostgreSQL real: amistad → publicación → like → comentario →
 * notificaciones, más visibilidad (privacidad y shadowban) y moderación.
 */
@SpringBootTest
@AutoConfigureMockMvc
class SocialFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;
    @Autowired
    private JdbcClient jdbc;

    private record Account(UUID id, String token, String email) {}

    private final String suffix = UUID.randomUUID().toString().substring(0, 8);

    private Account register(String name, String privacy) throws Exception {
        String email = name.toLowerCase() + suffix + "@example.com";
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\""
                                + name + suffix + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String token = JsonPath.read(body, "$.accessToken");
        UUID id = UUID.fromString(JsonPath.read(body, "$.user.id"));
        mvc.perform(patch("/api/v1/me").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"privacy\":\"" + privacy + "\"}"))
                .andExpect(status().isOk());
        return new Account(id, token, email);
    }

    private static MockHttpServletRequestBuilder as(Account a, MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + a.token()).contentType(MediaType.APPLICATION_JSON);
    }

    @Test
    void friendshipPostLikeCommentAndNotifications() throws Exception {
        Account ana = register("Ana", "FRIENDS");
        Account bea = register("Bea", "PUBLIC");
        Account carl = register("Carl", "PUBLIC");

        // UserRegistered crea las preferencias por defecto.
        assertThat(jdbc.sql("SELECT count(*) FROM preferencias_notificacion WHERE usuario_id = :id")
                .param("id", ana.id()).query(Long.class).single()).isEqualTo(1L);
        mvc.perform(as(ana, get("/api/v1/notifications/preferences")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dailyLimit").value(10))
                .andExpect(jsonPath("$.mode").value("NORMAL"))
                .andExpect(jsonPath("$.activeCategories.length()").value(5));

        // Búsqueda y solicitud de amistad.
        mvc.perform(as(bea, get("/api/v1/social/users/search").param("q", "ana" + suffix)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].id").value(ana.id().toString()))
                .andExpect(jsonPath("$.items[0].relation").value("NONE"));
        String request = mvc.perform(as(bea, post("/api/v1/social/friends/requests"))
                        .content("{\"userId\":\"" + ana.id() + "\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.relation").value("REQUEST_SENT"))
                .andExpect(jsonPath("$.user.id").value(ana.id().toString()))
                .andReturn().getResponse().getContentAsString();
        String friendshipId = JsonPath.read(request, "$.id");
        mvc.perform(as(bea, post("/api/v1/social/friends/requests")).content("{\"userId\":\"" + ana.id() + "\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("FRIENDSHIP_ALREADY_EXISTS"));
        mvc.perform(as(ana, get("/api/v1/social/friends").param("kind", "RECEIVED")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].id").value(friendshipId))
                .andExpect(jsonPath("$.items[0].relation").value("REQUEST_RECEIVED"));
        mvc.perform(as(ana, post("/api/v1/social/friends/" + friendshipId + "/accept")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACCEPTED"))
                .andExpect(jsonPath("$.relation").value("FRIENDS"));
        mvc.perform(as(bea, get("/api/v1/social/friends")))
                .andExpect(jsonPath("$.items[0].user.id").value(ana.id().toString()));

        // Ana publica (perfil solo para amigos).
        String created = mvc.perform(as(ana, post("/api/v1/social/posts")).content("""
                        {"type":"BADGE_UNLOCKED","description":"¡Nueva insignia!","metadata":{"badgeId":"b1"}}
                        """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.mine").value(true))
                .andExpect(jsonPath("$.metadata.badgeId").value("b1"))
                .andReturn().getResponse().getContentAsString();
        String postId = JsonPath.read(created, "$.id");

        // Bea (amiga) la ve; Carl (no amigo) no.
        mvc.perform(as(bea, get("/api/v1/social/posts").param("authorId", ana.id().toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].author.id").value(ana.id().toString()));
        mvc.perform(as(carl, get("/api/v1/social/posts").param("authorId", ana.id().toString())))
                .andExpect(jsonPath("$.totalItems").value(0));
        mvc.perform(as(carl, get("/api/v1/social/posts/" + postId)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("POST_NOT_FOUND"));
        mvc.perform(as(carl, get("/api/v1/social/users/" + ana.id())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.restricted").value(true))
                .andExpect(jsonPath("$.level").doesNotExist());

        // Like idempotente y comentario.
        mvc.perform(as(bea, put("/api/v1/social/posts/" + postId + "/like")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.liked").value(true))
                .andExpect(jsonPath("$.likesCount").value(1));
        mvc.perform(as(bea, put("/api/v1/social/posts/" + postId + "/like")))
                .andExpect(jsonPath("$.likesCount").value(1));
        String comment = mvc.perform(as(bea, post("/api/v1/social/posts/" + postId + "/comments"))
                        .content("{\"text\":\"¡Enhorabuena!\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.mine").value(true))
                .andReturn().getResponse().getContentAsString();
        String commentId = JsonPath.read(comment, "$.id");
        mvc.perform(as(bea, get("/api/v1/social/posts/" + postId)))
                .andExpect(jsonPath("$.likesCount").value(1))
                .andExpect(jsonPath("$.commentsCount").value(1))
                .andExpect(jsonPath("$.likedByMe").value(true))
                .andExpect(jsonPath("$.mine").value(false));
        mvc.perform(as(ana, get("/api/v1/social/posts/" + postId + "/comments")))
                .andExpect(jsonPath("$.items[0].text").value("¡Enhorabuena!"))
                .andExpect(jsonPath("$.items[0].mine").value(false));
        mvc.perform(as(ana, patch("/api/v1/social/comments/" + commentId)).content("{\"text\":\"hack\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("COMMENT_FORBIDDEN"));
        mvc.perform(as(bea, patch("/api/v1/social/comments/" + commentId)).content("{\"text\":\"¡Felicidades!\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.edited").value(true));

        // Notificaciones de Ana: solicitud, like y comentario (el segundo like no notifica).
        mvc.perform(as(ana, get("/api/v1/notifications/unread-count")))
                .andExpect(jsonPath("$.total").value(3))
                .andExpect(jsonPath("$.informative").value(3));
        mvc.perform(as(ana, get("/api/v1/notifications").param("priority", "INFORMATIVE").param("unreadOnly", "true")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(3))
                .andExpect(jsonPath("$.items[0].type").value("SOCIAL"))
                .andExpect(jsonPath("$.items[0].actionUrl").value("/social/posts/" + postId));
        String notifs = mvc.perform(as(ana, get("/api/v1/notifications")))
                .andReturn().getResponse().getContentAsString();
        String notificationId = JsonPath.read(notifs, "$.items[0].id");
        mvc.perform(as(bea, post("/api/v1/notifications/" + notificationId + "/read")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("NOTIFICATION_NOT_FOUND"));
        mvc.perform(as(ana, post("/api/v1/notifications/" + notificationId + "/read")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.read").value(true));
        mvc.perform(as(ana, post("/api/v1/notifications/read-all")))
                .andExpect(jsonPath("$.updated").value(2));
        mvc.perform(as(ana, get("/api/v1/notifications/unread-count")))
                .andExpect(jsonPath("$.total").value(0));
        mvc.perform(as(ana, delete("/api/v1/notifications/" + notificationId)))
                .andExpect(status().isNoContent());
        // Bea recibió la aceptación de su solicitud.
        mvc.perform(as(bea, get("/api/v1/notifications/unread-count")))
                .andExpect(jsonPath("$.total").value(1));

        // Sondeo de novedades con since.
        mvc.perform(as(bea, get("/api/v1/social/posts").param("since", "2999-01-01T00:00:00Z")))
                .andExpect(jsonPath("$.totalItems").value(0));

        // Preferencias inválidas.
        mvc.perform(as(ana, put("/api/v1/notifications/preferences")).content("""
                        {"activeCategories":["SOCIAL"],"quietHoursStart":"23:00","dailyLimit":5,"mode":"EXAMS"}
                        """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("NOTIFICATION_INVALID_QUIET_HOURS"));
        mvc.perform(as(ana, put("/api/v1/notifications/preferences")).content("""
                        {"activeCategories":["SOCIAL","ACADEMIC"],"quietHoursStart":"23:00",
                         "quietHoursEnd":"07:00","dailyLimit":5,"mode":"EXAMS"}
                        """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mode").value("EXAMS"))
                .andExpect(jsonPath("$.quietHoursEnd").value("07:00:00"));

        // Reporte y moderación.
        mvc.perform(as(bea, post("/api/v1/social/posts/" + postId + "/report")))
                .andExpect(status().isNoContent());
        mvc.perform(as(bea, get("/api/v1/admin/social/reports")))
                .andExpect(status().isForbidden());
        jdbc.sql("UPDATE usuarios SET rol = 'admin' WHERE id = :id").param("id", carl.id()).update();
        String login = mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + carl.email() + "\",\"password\":\"secret123\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        Account admin = new Account(carl.id(), JsonPath.read(login, "$.accessToken"), carl.email());
        mvc.perform(as(admin, get("/api/v1/admin/social/reports").param("type", "POST")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.id == '" + postId + "')].reportedBy").value(bea.id().toString()));
        mvc.perform(as(admin, post("/api/v1/admin/social/posts/" + postId + "/dismiss-report")))
                .andExpect(status().isNoContent());
        assertThat(jdbc.sql("""
                        SELECT count(*) FROM admin_auditoria
                         WHERE admin_id = :admin AND accion = 'aprobar_contenido' AND entidad_id = :post
                           AND detalle ->> 'autor_id' = :author
                        """)
                .param("admin", carl.id()).param("post", UUID.fromString(postId)).param("author", ana.id().toString())
                .query(Long.class).single()).isEqualTo(1L);

        // Shadowban: la publicación de Ana desaparece para Bea pero no para Ana.
        jdbc.sql("UPDATE usuarios SET is_shadowbanned = true WHERE id = :id").param("id", ana.id()).update();
        mvc.perform(as(bea, get("/api/v1/social/posts").param("authorId", ana.id().toString())))
                .andExpect(jsonPath("$.totalItems").value(0));
        mvc.perform(as(ana, get("/api/v1/social/posts").param("authorId", ana.id().toString())
                        .param("period", "TODAY")))
                .andExpect(jsonPath("$.totalItems").value(1));

        // Borrado por moderación.
        mvc.perform(as(admin, delete("/api/v1/admin/social/posts/" + postId)))
                .andExpect(status().isNoContent());
        mvc.perform(as(ana, get("/api/v1/social/posts/" + postId)))
                .andExpect(status().isNotFound());
    }

    @Test
    void blockingHidesUsersFromEachOther() throws Exception {
        Account dani = register("Dani", "PUBLIC");
        Account eva = register("Eva", "PUBLIC");
        mvc.perform(as(dani, post("/api/v1/social/posts")).content("{\"type\":\"ROUTINE\",\"description\":\"Rutina\"}"))
                .andExpect(status().isCreated());

        String block = mvc.perform(as(dani, post("/api/v1/social/friends/blocks"))
                        .content("{\"userId\":\"" + eva.id() + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.relation").value("BLOCKED"))
                .andReturn().getResponse().getContentAsString();
        String blockId = JsonPath.read(block, "$.id");

        mvc.perform(as(eva, get("/api/v1/social/posts").param("authorId", dani.id().toString())))
                .andExpect(jsonPath("$.totalItems").value(0));
        mvc.perform(as(eva, get("/api/v1/social/users/" + dani.id())))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("SOCIAL_USER_NOT_FOUND"));
        mvc.perform(as(eva, get("/api/v1/social/users/search").param("q", "dani" + suffix)))
                .andExpect(jsonPath("$.totalItems").value(0));
        mvc.perform(as(dani, post("/api/v1/social/friends/requests")).content("{\"userId\":\"" + eva.id() + "\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("FRIENDSHIP_BLOCKED"));
        mvc.perform(as(dani, get("/api/v1/social/friends").param("kind", "BLOCKED")))
                .andExpect(jsonPath("$.items[0].user.id").value(eva.id().toString()));

        mvc.perform(as(dani, delete("/api/v1/social/friends/" + blockId)))
                .andExpect(status().isNoContent());
        mvc.perform(as(eva, get("/api/v1/social/posts").param("authorId", dani.id().toString())))
                .andExpect(jsonPath("$.totalItems").value(1));
    }
}
