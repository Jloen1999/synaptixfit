package com.synaptixfit.infrastructure.adapter.input.rest.together;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * «Juntos» a la vez (ADR 0047) sobre PostgreSQL real: valida V1068, que «Empezar» crea la sesión de las dos personas
 * con la misma hora, que pausar una pausa a las dos (y reanudar, también), que el canal SSE recibe el aviso después
 * del commit y que nadie de fuera recibe nada.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TogetherLiveIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private TogetherStreamHub hub;

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

    /** Abre el canal en directo; la respuesta simulada va acumulando lo que se manda por él. */
    private MockHttpServletResponse stream(Account who) throws Exception {
        MvcResult result = mvc.perform(get("/api/v1/together/stream").header("Authorization", "Bearer " + who.token())
                        .accept(MediaType.TEXT_EVENT_STREAM))
                .andReturn();
        assertThat(result.getRequest().isAsyncStarted()).isTrue();
        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        return result.getResponse();
    }

    @Test
    void startingAndPausingGoForEveryoneAndOnlyTheGroupHearsIt() throws Exception {
        Account me = register("yo.directo@example.com", "Yo Directo");
        Account ana = register("ana.directo@example.com", "Ana Directo");
        Account stranger = register("otra.directo@example.com", "Otra Directo");
        befriend(me, ana);

        // Sin token no hay canal.
        assertThat(mvc.perform(get("/api/v1/together/stream")).andReturn().getResponse().getStatus()).isEqualTo(401);
        MockHttpServletResponse anaStream = stream(ana);
        MockHttpServletResponse strangerStream = stream(stranger);
        assertThat(anaStream.getContentAsString()).contains("event:ready");
        assertThat(hub.connections(java.util.UUID.fromString(ana.id()))).isEqualTo(1);

        String gallery = call(get("/api/v1/training/templates"), me, null, 200);
        List<String> templates = JsonPath.read(gallery, "$[?(@.code == 'mantener_examenes_casa')].id");
        String routine = call(post("/api/v1/training/templates/" + templates.getFirst() + "/use"), me, null, 201);
        String routineId = JsonPath.read(routine, "$.id");
        String workout = call(post("/api/v1/together/workouts"), me,
                "{\"routineId\":\"" + routineId + "\",\"friendIds\":[\"" + ana.id() + "\"]}", 201);
        String workoutId = JsonPath.read(workout, "$.id");
        assertThat(anaStream.getContentAsString()).contains("\"type\":\"together\",\"id\":\"" + workoutId + "\"");
        assertThat((Object) JsonPath.read(workout, "$.startedAt")).isNull();
        call(post("/api/v1/together/workouts/" + workoutId + "/join"), ana, null, 200);

        // Empieza Ana: el anfitrión ya tiene su sesión, con la misma hora de inicio.
        String start = call(post("/api/v1/together/workouts/" + workoutId + "/start"), ana, null, 200);
        String anaSession = JsonPath.read(start, "$.sessionId");
        String seen = call(get("/api/v1/together/workouts/" + workoutId), me, null, 200);
        String mySession = JsonPath.read(seen, "$.mySessionId");
        assertThat(mySession).isNotNull().isNotEqualTo(anaSession);
        String startedAt = JsonPath.read(seen, "$.startedAt");
        assertThat((String) JsonPath.read(seen, "$.startedBy.id")).isEqualTo(ana.id());
        String mine = call(get("/api/v1/training/sessions/" + mySession), me, null, 200);
        String hers = call(get("/api/v1/training/sessions/" + anaSession), ana, null, 200);
        assertThat((String) JsonPath.read(mine, "$.startedAt")).isEqualTo(JsonPath.read(hers, "$.startedAt"));
        assertThat(java.time.Instant.parse(JsonPath.read(mine, "$.startedAt")))
                .isEqualTo(java.time.Instant.parse(startedAt));
        // Un segundo «Empezar» del anfitrión retoma la suya; no crea otra.
        assertThat((String) JsonPath.read(call(post("/api/v1/together/workouts/" + workoutId + "/start"), me, null,
                200), "$.sessionId")).isEqualTo(mySession);

        // Pausa Ana: las dos sesiones en pausa y se ve quién la puso.
        call(post("/api/v1/training/sessions/" + anaSession + "/pause"), ana, null, 200);
        assertThat((Object) JsonPath.read(call(get("/api/v1/training/sessions/" + mySession), me, null, 200),
                "$.pausedAt")).isNotNull();
        String paused = call(get("/api/v1/together/workouts/" + workoutId), me, null, 200);
        assertThat((String) JsonPath.read(paused, "$.pausedBy.id")).isEqualTo(ana.id());
        assertThat(paused).doesNotContain("weightKg");

        // Reanuda el anfitrión: las dos siguen.
        call(post("/api/v1/training/sessions/" + mySession + "/resume"), me, null, 200);
        assertThat((Object) JsonPath.read(call(get("/api/v1/training/sessions/" + anaSession), ana, null, 200),
                "$.pausedAt")).isNull();
        assertThat((Object) JsonPath.read(call(get("/api/v1/together/workouts/" + workoutId), ana, null, 200),
                "$.pausedBy")).isNull();

        // Terminar es de cada uno: el anfitrión termina y la sesión de Ana sigue abierta.
        call(post("/api/v1/training/sessions/" + mySession + "/finish"), me,
                "{\"durationSeconds\":600,\"rpe\":7}", 200);
        assertThat((String) JsonPath.read(call(get("/api/v1/training/sessions/" + anaSession), ana, null, 200),
                "$.status")).isNotEqualTo("COMPLETED");

        // El canal de Ana recibió los avisos ya confirmados; el de alguien de fuera, ninguno.
        String heard = anaStream.getContentAsString();
        assertThat(heard).contains("event:change").contains("\"type\":\"workout\",\"id\":\"" + workoutId + "\"");
        assertThat(heard.split("\"type\":\"workout\"", -1).length - 1).isGreaterThanOrEqualTo(5);
        assertThat(strangerStream.getContentAsString()).contains("event:ready").doesNotContain("event:change");
    }

    @Test
    void studyRoomStartIsHeardByTheFriendInside() throws Exception {
        Account me = register("yo.sala.directo@example.com", "Yo Sala");
        Account ana = register("ana.sala.directo@example.com", "Ana Sala");
        befriend(me, ana);
        MockHttpServletResponse anaStream = stream(ana);
        String room = call(post("/api/v1/together/study-rooms"), me,
                "{\"friendIds\":[\"" + ana.id() + "\"],\"length\":\"SHORT\",\"rounds\":1}", 201);
        String roomId = JsonPath.read(room, "$.id");
        call(post("/api/v1/together/study-rooms/" + roomId + "/join"), ana, null, 200);
        call(post("/api/v1/together/study-rooms/" + roomId + "/start"), me, null, 200);
        assertThat(anaStream.getContentAsString())
                .contains("\"type\":\"studyRoom\",\"id\":\"" + roomId + "\"");
    }
}
