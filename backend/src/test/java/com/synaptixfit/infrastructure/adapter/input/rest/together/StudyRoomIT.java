package com.synaptixfit.infrastructure.adapter.input.rest.together;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.application.port.input.together.CreditStudyRoomRoundsUseCase;
import com.synaptixfit.application.port.input.together.FindStudyRoomsToCreditUseCase;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.OffsetDateTime;
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
 * «Estudiamos juntos» (ADR 0045) sobre PostgreSQL real: valida V1065, que solo entran amigos, la asignatura privada,
 * las reacciones, que cada ronda terminada se apunta una sola vez como Pomodoro normal (en {@code sesiones_focus}),
 * la denuncia desde la sala, la exportación y que bloquear saca de la sala.
 */
@SpringBootTest
@AutoConfigureMockMvc
class StudyRoomIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    @Autowired
    private FindStudyRoomsToCreditUseCase roomsToCredit;

    @Autowired
    private CreditStudyRoomRoundsUseCase creditRounds;

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
    void friendsStudyTogetherAndEachFinishedRoundIsAPomodoro() throws Exception {
        Account me = register("yo.sala@example.com", "Yo Sala");
        Account ana = register("ana.sala@example.com", "Ana Sala");
        Account stranger = register("otra.sala@example.com", "Otra Sala");
        befriend(me, ana);

        String subject = call(post("/api/v1/subjects"), me,
                "{\"name\":\"Álgebra\",\"credits\":6,\"perceivedDifficulty\":3,\"priority\":\"HIGH\"}", 201);
        String subjectId = JsonPath.read(subject, "$.id");
        assertThat(call(post("/api/v1/together/study-rooms"), me, "{\"length\":\"SHORT\",\"rounds\":2,"
                + "\"friendIds\":[\"" + stranger.id() + "\"]}", 422)).contains("TOGETHER_NOT_FRIENDS");
        String created = call(post("/api/v1/together/study-rooms"), me, "{\"length\":\"SHORT\",\"rounds\":2,"
                + "\"friendIds\":[\"" + ana.id() + "\"],\"subjectId\":\"" + subjectId + "\"}", 201);
        String roomId = JsonPath.read(created, "$.id");
        assertThat((String) JsonPath.read(created, "$.phase")).isEqualTo("WAITING");
        assertThat((Integer) JsonPath.read(created, "$.focusMinutes")).isEqualTo(25);
        assertThat((String) JsonPath.read(created, "$.serverTime")).isNotBlank();
        call(get("/api/v1/together/study-rooms/" + roomId), stranger, null, 404);

        String overview = call(get("/api/v1/together"), ana, null, 200);
        assertThat((String) JsonPath.read(overview, "$.studyRooms[0].myStatus")).isEqualTo("INVITED");
        String limits = call(get("/api/v1/together/limits"), ana, null, 200);
        assertThat((Integer) JsonPath.read(limits, "$.studyRoomFriends")).isEqualTo(4);
        assertThat((Integer) JsonPath.read(limits, "$.challengeFriends")).isEqualTo(24);
        List<Integer> breaks = JsonPath.read(limits, "$.studyRoomLengths[?(@.length == 'LONG')].breakMinutes");
        assertThat(breaks).containsExactly(10);
        // La asignatura de los demás nunca sale.
        assertThat(overview).doesNotContain(subjectId);

        call(post("/api/v1/together/study-rooms/" + roomId + "/start"), ana, null, 409);
        String joined = call(post("/api/v1/together/study-rooms/" + roomId + "/join"), ana, null, 200);
        assertThat(joined).doesNotContain(subjectId);
        String started = call(post("/api/v1/together/study-rooms/" + roomId + "/start"), ana, null, 200);
        assertThat((String) JsonPath.read(started, "$.phase")).isEqualTo("FOCUS");
        assertThat((Integer) JsonPath.read(started, "$.round")).isEqualTo(1);
        call(put("/api/v1/together/study-rooms/" + roomId + "/reaction"), ana, "{\"reaction\":\"COFFEE\"}", 200);
        String mine = call(get("/api/v1/together/study-rooms/" + roomId), me, null, 200);
        assertThat((String) JsonPath.read(mine, "$.mySubjectId")).isEqualTo(subjectId);
        List<String> reactions = JsonPath.read(mine, "$.members[?(@.me == false)].reaction");
        assertThat(reactions).containsExactly("COFFEE");

        // Como si la sala hubiera empezado hace 26 minutos con los dos dentro: la ronda 1 ha terminado.
        OffsetDateTime earlier = OffsetDateTime.now(ZoneOffset.UTC).minusMinutes(26);
        jdbc.sql("UPDATE salas_estudio SET inicio = :at WHERE id = :id")
                .param("at", earlier).param("id", UUID.fromString(roomId)).update();
        jdbc.sql("UPDATE salas_estudio_miembros SET actualizado_en = :at WHERE sala_id = :id")
                .param("at", earlier.minusMinutes(1)).param("id", UUID.fromString(roomId)).update();
        assertThat(roomsToCredit.roomsToCredit()).contains(UUID.fromString(roomId));
        assertThat(creditRounds.creditRounds(UUID.fromString(roomId))).isEqualTo(2);
        assertThat(creditRounds.creditRounds(UUID.fromString(roomId))).isZero();
        assertThat(focusSessions(me, subjectId)).isEqualTo(1);
        assertThat(jdbc.sql("SELECT count(*) FROM sesiones_focus WHERE usuario_id = :u AND tipo_fase = 'focus'")
                .param("u", UUID.fromString(ana.id())).query(Long.class).single()).isEqualTo(1);
        String now = call(get("/api/v1/together/study-rooms/" + roomId), me, null, 200);
        assertThat((String) JsonPath.read(now, "$.phase")).isEqualTo("BREAK");

        // Denunciar desde la sala, exportar y bloquear: Ana sale de la sala.
        call(post("/api/v1/social/users/" + me.id() + "/report"), ana, "{\"context\":\"STUDY_ROOM\"}", 204);
        assertThat(call(get("/api/v1/me/export"), ana, null, 200)).contains("studyRooms");
        call(post("/api/v1/social/friends/blocks"), me, "{\"userId\":\"" + ana.id() + "\"}", 200);
        call(get("/api/v1/together/study-rooms/" + roomId), ana, null, 404);
        call(post("/api/v1/together/study-rooms/" + roomId + "/join"), ana, null, 404);
        String afterBlock = call(get("/api/v1/together/study-rooms/" + roomId), me, null, 200);
        List<String> statuses = JsonPath.read(afterBlock, "$.members[?(@.me == false)].status");
        assertThat(statuses).containsExactly("LEFT");
    }

    private long focusSessions(Account who, String subjectId) {
        return jdbc.sql("SELECT count(*) FROM sesiones_focus WHERE usuario_id = :u AND asignatura_id = :s")
                .param("u", UUID.fromString(who.id()))
                .param("s", UUID.fromString(subjectId))
                .query(Long.class).single();
    }
}
