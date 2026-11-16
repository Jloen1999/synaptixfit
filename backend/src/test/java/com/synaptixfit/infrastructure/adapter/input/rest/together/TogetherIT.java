package com.synaptixfit.infrastructure.adapter.input.rest.together;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
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
 * «Con amigos» (ADR 0044) sobre PostgreSQL real: valida V1064, que solo se invita a amigos, el tablón con reacciones,
 * la racha con un amigo, entrenar juntos con la sesión normal de cada uno y que al bloquear se sale de lo compartido.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TogetherIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private record Account(String token, String id) {
    }

    private Account register(String email, String name) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"" + name
                                + "\"}"))
                .andReturn().getResponse().getContentAsString();
        return new Account(JsonPath.read(body, "$.accessToken"), JsonPath.read(body, "$.user.id"));
    }

    private String call(MockHttpServletRequestBuilder b, Account who, String json, int expected) throws Exception {
        var response = mvc.perform(b.header("Authorization", "Bearer " + who.token())
                        .contentType(MediaType.APPLICATION_JSON).content(json == null ? "" : json))
                .andReturn().getResponse();
        assertThat(response.getStatus()).as(response.getContentAsString()).isEqualTo(expected);
        return response.getContentAsString();
    }

    private void befriend(Account a, Account b) throws Exception {
        String request = call(post("/api/v1/social/friends/requests"), a, "{\"userId\":\"" + b.id() + "\"}", 201);
        String id = JsonPath.read(request, "$.id");
        call(post("/api/v1/social/friends/" + id + "/accept"), b, null, 200);
    }

    @Test
    void friendsShareChallengesStreaksAndWorkoutsUntilOneBlocks() throws Exception {
        Account me = register("yo.amigos@example.com", "Yo Amigos");
        Account ana = register("ana.amigos@example.com", "Ana Amigos");
        Account stranger = register("otra.amigos@example.com", "Otra Persona");
        befriend(me, ana);

        // Retos: nunca plantillas de bienestar; solo amigos mutuos.
        String templates = call(get("/api/v1/together/challenges/templates"), me, null, 200);
        assertThat(templates).doesNotContain("CHECK_INS");
        List<String> ids = JsonPath.read(templates, "$[?(@.code == 'repasa_cada_dia')].id");
        String template = ids.getFirst();
        String strangerBody = "{\"templateId\":\"" + template + "\",\"days\":7,\"friendIds\":[\"" + stranger.id()
                + "\"]}";
        assertThat(call(post("/api/v1/together/challenges"), me, strangerBody, 422)).contains("TOGETHER_NOT_FRIENDS");
        String created = call(post("/api/v1/together/challenges"), me,
                "{\"templateId\":\"" + template + "\",\"days\":7,\"friendIds\":[\"" + ana.id() + "\"]}", 201);
        String challengeId = JsonPath.read(created, "$.id");
        assertThat((String) JsonPath.read(created, "$.mode")).isEqualTo("COOPERATIVE");
        assertThat((Integer) JsonPath.read(created, "$.groupTarget")).isEqualTo(6);
        call(get("/api/v1/together/challenges/" + challengeId), stranger, null, 404);

        String overview = call(get("/api/v1/together"), ana, null, 200);
        assertThat((String) JsonPath.read(overview, "$.challenges[0].myStatus")).isEqualTo("INVITED");
        call(post("/api/v1/together/challenges/" + challengeId + "/join"), ana, null, 200);
        call(post("/api/v1/together/challenges/" + challengeId + "/leave"), ana, null, 204);
        call(get("/api/v1/together/challenges/" + challengeId), ana, null, 404);
        String rejoined = call(post("/api/v1/together/challenges/" + challengeId + "/join"), ana, null, 200);
        assertThat((Integer) JsonPath.read(rejoined, "$.groupTarget")).isEqualTo(12);
        String today = LocalDate.now(ZoneId.of("Europe/Madrid")).toString();
        // Nadie ha sumado nada todavía: no hay entrada a la que reaccionar en el tablón.
        call(put("/api/v1/together/challenges/" + challengeId + "/reactions"), ana,
                "{\"recipientId\":\"" + me.id() + "\",\"day\":\"" + today + "\",\"reaction\":\"CLAP\"}", 409);
        call(put("/api/v1/together/challenges/" + challengeId + "/reactions"), me,
                "{\"recipientId\":\"" + me.id() + "\",\"day\":\"" + today + "\",\"reaction\":\"CLAP\"}", 409);

        // Racha con un amigo.
        String streak = call(post("/api/v1/together/streaks"), me, "{\"friendId\":\"" + ana.id() + "\"}", 201);
        String streakId = JsonPath.read(streak, "$.id");
        call(post("/api/v1/together/streaks/" + streakId + "/accept"), me, null, 409);
        String accepted = call(post("/api/v1/together/streaks/" + streakId + "/accept"), ana, null, 200);
        assertThat((String) JsonPath.read(accepted, "$.status")).isEqualTo("ACTIVE");
        assertThat(call(post("/api/v1/together/streaks/" + streakId + "/nudge"), me, null, 422))
                .contains("FRIEND_STREAK_NUDGE_UNAVAILABLE");

        // Entrenar juntos: Ana entrena con una copia en pausa de la rutina.
        String gallery = call(get("/api/v1/training/templates"), me, null, 200);
        List<String> routineTemplates = JsonPath.read(gallery, "$[?(@.code == 'mantener_examenes_casa')].id");
        String routine = call(post("/api/v1/training/templates/" + routineTemplates.getFirst() + "/use"), me, null,
                201);
        String routineId = JsonPath.read(routine, "$.id");
        String workout = call(post("/api/v1/together/workouts"), me,
                "{\"routineId\":\"" + routineId + "\",\"friendIds\":[\"" + ana.id() + "\"]}", 201);
        String workoutId = JsonPath.read(workout, "$.id");
        assertThat((List<?>) JsonPath.read(workout, "$.exercises")).isNotEmpty();
        String start = call(post("/api/v1/together/workouts/" + workoutId + "/start"), ana, null, 200);
        String sessionId = JsonPath.read(start, "$.sessionId");
        assertThat((String) JsonPath.read(call(post("/api/v1/together/workouts/" + workoutId + "/start"), ana, null,
                200), "$.sessionId")).isEqualTo(sessionId);
        String bySession = call(get("/api/v1/together/workouts/by-session/" + sessionId), ana, null, 200);
        assertThat((String) JsonPath.read(bySession, "$.id")).isEqualTo(workoutId);
        assertThat(bySession).doesNotContain("weightKg").doesNotContain("rpe");
        String mine = call(get("/api/v1/routines?status=PAUSED"), ana, null, 200);
        assertThat(mine).contains("(copiada)");
        call(get("/api/v1/together/workouts/by-session/" + sessionId), me, null, 204);

        // Denunciar y bloquear: se sale de todo lo compartido.
        call(post("/api/v1/social/users/" + me.id() + "/report"), ana, "{\"context\":\"FRIEND_STREAK\"}", 204);
        call(post("/api/v1/social/friends/blocks"), me, "{\"userId\":\"" + ana.id() + "\"}", 200);
        call(get("/api/v1/together/challenges/" + challengeId), ana, null, 404);
        call(get("/api/v1/together/workouts/" + workoutId), ana, null, 404);
        // Tras el bloqueo no se vuelve a entrar con «Deshacer».
        call(post("/api/v1/together/challenges/" + challengeId + "/join"), ana, null, 404);
        call(post("/api/v1/together/workouts/" + workoutId + "/join"), ana, null, 404);
        String after = call(get("/api/v1/together"), me, null, 200);
        assertThat((List<?>) JsonPath.read(after, "$.streaks")).isEmpty();
        call(delete("/api/v1/together/streaks/" + streakId), me, null, 404);
    }
}
