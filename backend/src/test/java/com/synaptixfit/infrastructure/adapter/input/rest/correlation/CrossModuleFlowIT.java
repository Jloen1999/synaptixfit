package com.synaptixfit.infrastructure.adapter.input.rest.correlation;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
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
 * Correlación entre módulos sobre PostgreSQL real: entrenar avanza retos de fitness y da insignias y
 * avisos; el Pomodoro da XP con tope y cuenta para la racha; deshacer (borrar entregas o
 * asignaturas, desmarcar) no deja XP ni estados colgados; el repaso SM-2 completa su bloque; la
 * privacidad alcanza a los apuntes; el bloque de deporte sigue a la sesión de su día de rutina.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CrossModuleFlowIT {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");

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
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Usuaria\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private String body(MockHttpServletRequestBuilder b, String token, int expectedStatus) throws Exception {
        return mvc.perform(b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().is(expectedStatus)).andReturn().getResponse().getContentAsString();
    }

    private UUID userId(String token) throws Exception {
        return UUID.fromString(JsonPath.read(body(get("/api/v1/me"), token, 200), "$.id"));
    }

    /** XP total de la cuenta: cada nivel n pide 100·n puntos ({@code User.thresholdFor}). */
    private int totalXp(String token) throws Exception {
        String me = body(get("/api/v1/me"), token, 200);
        int level = JsonPath.read(me, "$.level");
        int levelXp = JsonPath.read(me, "$.levelXp");
        return 100 * level * (level - 1) / 2 + levelXp;
    }

    private long count(String sql, UUID user) {
        return jdbc.sql(sql).param("u", user).query(Long.class).single();
    }

    private String finishFreeSession(String token) throws Exception {
        String session = body(post("/api/v1/training/sessions"), token, 201);
        String sessionId = JsonPath.read(session, "$.id");
        body(post("/api/v1/training/sessions/" + sessionId + "/finish").content("{\"durationSeconds\":1800,\"rpe\":5}"),
                token, 200);
        return sessionId;
    }

    @Test
    void trainingAdvancesAFitnessChallengeAwardsBadgesNotifiesAndPostsOnce() throws Exception {
        String token = register("cross-train@example.com");
        UUID user = userId(token);
        String end = Instant.now().plus(7, ChronoUnit.DAYS).toString();
        String challenge = body(post("/api/v1/challenges").content("""
                {"title":"Entrenar una vez","type":"FITNESS","endAt":"%s","sessionTarget":1}""".formatted(end)),
                token, 201);
        String challengeId = JsonPath.read(challenge, "$.id");
        assertThat((Integer) JsonPath.read(challenge, "$.sessionTarget")).isEqualTo(1);
        assertThat((Integer) JsonPath.read(challenge, "$.sessionsCompleted")).isZero();
        assertThat((Boolean) JsonPath.read(challenge, "$.tracksTrainingSessions")).isTrue();

        String sessionId = finishFreeSession(token);

        String done = body(get("/api/v1/challenges/" + challengeId), token, 200);
        assertThat((Boolean) JsonPath.read(done, "$.completed")).isTrue();
        assertThat((Integer) JsonPath.read(done, "$.sessionsCompleted")).isEqualTo(1);
        assertThat((Integer) JsonPath.read(done, "$.xpAwarded")).isEqualTo(40);
        // Insignias evaluadas en el servidor, sin llamar a /badges/evaluate.
        List<String> unnotified = JsonPath.read(body(get("/api/v1/badges/unnotified"), token, 200), "$[*].name");
        assertThat(unnotified).contains("Primeros pasos", "Primer reto");
        assertThat(count("select count(*) from notificaciones where usuario_id = :u and tipo = 'milestone'"
                + " and url_accion = '/challenges/" + challengeId + "'", user)).isEqualTo(1);
        assertThat(count("select count(*) from notificaciones where usuario_id = :u and tipo = 'milestone'"
                + " and descripcion like '%Primeros pasos%'", user)).isEqualTo(1);
        assertThat(count("select count(*) from actividades_sociales where usuario_id = :u"
                + " and tipo = 'challenge_completed'", user)).isEqualTo(1);

        // Desmarcar la sesión descompleta el reto; volver a terminarla no duplica publicación ni aviso.
        body(post("/api/v1/training/sessions/" + sessionId + "/unmark"), token, 200);
        assertThat((Boolean) JsonPath.read(body(get("/api/v1/challenges/" + challengeId), token, 200), "$.completed"))
                .isFalse();
        body(post("/api/v1/training/sessions/" + sessionId + "/finish").content("{\"durationSeconds\":1800,\"rpe\":5}"),
                token, 200);
        assertThat((Boolean) JsonPath.read(body(get("/api/v1/challenges/" + challengeId), token, 200), "$.completed"))
                .isTrue();
        assertThat(count("select count(*) from actividades_sociales where usuario_id = :u"
                + " and tipo = 'challenge_completed'", user)).isEqualTo(1);
        assertThat(count("select count(*) from notificaciones where usuario_id = :u"
                + " and url_accion = '/challenges/" + challengeId + "'", user)).isEqualTo(1);
    }

    @Test
    void twoChallengesWithTheSameTitleAreBothNotified() throws Exception {
        String token = register("cross-same-title@example.com");
        UUID user = userId(token);
        String end = Instant.now().plus(7, ChronoUnit.DAYS).toString();
        String request = """
                {"title":"Entrenar hoy","type":"FITNESS","endAt":"%s","sessionTarget":1}""".formatted(end);
        String first = JsonPath.read(body(post("/api/v1/challenges").content(request), token, 201), "$.id");
        String second = JsonPath.read(body(post("/api/v1/challenges").content(request), token, 201), "$.id");

        finishFreeSession(token);

        // La clave es el id del reto, no su título: los dos avisan una vez.
        assertThat(count("select count(*) from notificaciones where usuario_id = :u and clave_referencia in ('challenge:"
                + first + "', 'challenge:" + second + "')", user)).isEqualTo(2);
    }

    @Test
    void theHomeShowsTheTrainingSessionProgressOfAFitnessChallenge() throws Exception {
        String token = register("cross-home@example.com");
        String end = Instant.now().plus(7, ChronoUnit.DAYS).toString();
        body(post("/api/v1/challenges").content("""
                {"title":"Tres entrenos","type":"FITNESS","endAt":"%s","sessionTarget":3}""".formatted(end)),
                token, 201);

        finishFreeSession(token);

        // Inicio usa su propia consulta: debe dar el mismo progreso que el detalle del reto.
        Double progress = JsonPath.read(body(get("/api/v1/dashboard"), token, 200), "$.activeChallenges[0].progress");
        assertThat(progress).isCloseTo(33.33, org.assertj.core.api.Assertions.within(0.1));
    }

    @Test
    void focusSessionsGiveCappedXpCountForTheStreakAndTheCognitiveLoad() throws Exception {
        String token = register("cross-focus@example.com");
        UUID user = userId(token);

        for (int expected : new int[]{5, 5, 5, 5, 0}) {
            String focus = body(post("/api/v1/planner/focus-sessions")
                    .content("{\"phase\":\"FOCUS\",\"durationMinutes\":25}"), token, 201);
            assertThat((Integer) JsonPath.read(focus, "$.xpAwarded")).isEqualTo(expected);
            assertThat((String) JsonPath.read(focus, "$.xpStatus"))
                    .isEqualTo(expected > 0 ? "AWARDED" : "DAILY_CAP_REACHED");
        }
        assertThat(totalXp(token)).isEqualTo(20);
        String pause = body(post("/api/v1/planner/focus-sessions")
                .content("{\"phase\":\"SHORT_BREAK\",\"durationMinutes\":5}"), token, 201);
        assertThat((String) JsonPath.read(pause, "$.xpStatus")).isEqualTo("NOT_ELIGIBLE");
        String streak = body(get("/api/v1/streak"), token, 200);
        assertThat((Integer) JsonPath.read(streak, "$.currentDays")).isEqualTo(1);
        assertThat((Boolean) JsonPath.read(streak, "$.activeToday")).isTrue();
        Double load = jdbc.sql("select carga_cognitiva_actual from estado_cognitivo_usuario where usuario_id = :u")
                .param("u", user).query(Double.class).single();
        assertThat(load).isPositive();
        // Los 5 Pomodoros (125 min) cuentan como estudio de hoy y de la semana en el inicio.
        String dashboard = body(get("/api/v1/dashboard"), token, 200);
        assertThat((Integer) JsonPath.read(dashboard, "$.today.studyMinutesCompleted")).isEqualTo(125);
        assertThat((Integer) JsonPath.read(dashboard, "$.week.studyMinutesCompleted")).isEqualTo(125);

        // Un bloque ajeno no se puede usar como contexto del Pomodoro.
        mvc.perform(post("/api/v1/planner/focus-sessions").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"phase\":\"FOCUS\",\"durationMinutes\":25,\"blockId\":\"" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void deletingACompletedDeadlineUncompletesTheLinkedChallenge() throws Exception {
        String token = register("cross-deadline@example.com");
        Instant due = Instant.now().plus(3, ChronoUnit.DAYS);
        String deadline = body(post("/api/v1/planner/deadlines").content("""
                {"title":"Práctica final","type":"ASSIGNMENT","dueAt":"%s"}""".formatted(due)), token, 201);
        String deadlineId = JsonPath.read(deadline, "$.id");
        String challenge = body(post("/api/v1/challenges").content("""
                {"title":"Entregar la práctica","endAt":"%s","linkedEntityType":"DELIVERY","linkedEntityId":"%s"}"""
                .formatted(due.plus(1, ChronoUnit.DAYS), deadlineId)), token, 201);
        String challengeId = JsonPath.read(challenge, "$.id");

        body(put("/api/v1/planner/deadlines/" + deadlineId + "/completion").content("{\"completed\":true}"), token, 200);
        assertThat((Boolean) JsonPath.read(body(get("/api/v1/challenges/" + challengeId), token, 200), "$.completed"))
                .isTrue();
        assertThat(totalXp(token)).isEqualTo(30 + 40);

        body(delete("/api/v1/planner/deadlines/" + deadlineId), token, 204);

        String after = body(get("/api/v1/challenges/" + challengeId), token, 200);
        assertThat((Boolean) JsonPath.read(after, "$.completed")).isFalse();
        assertThat((Integer) JsonPath.read(after, "$.xpAwarded")).isZero();
        assertThat(totalXp(token)).isZero();
    }

    @Test
    void deletingASubjectDeletesItsBlocksThroughThePlannerAndRevokesTheirXp() throws Exception {
        String token = register("cross-subject@example.com");
        UUID user = userId(token);
        String subject = body(post("/api/v1/subjects").content("{\"name\":\"Física\",\"credits\":6}"), token, 201);
        String subjectId = JsonPath.read(subject, "$.id");
        Instant start = Instant.now().plus(1, ChronoUnit.DAYS).truncatedTo(ChronoUnit.HOURS);
        String block = body(post("/api/v1/planner/blocks").content("""
                {"start":"%s","end":"%s","type":"STUDY","subjectId":"%s"}"""
                .formatted(start, start.plus(Duration.ofMinutes(60)), subjectId)), token, 201);
        String blockId = JsonPath.read(block, "$.block.id");
        body(put("/api/v1/planner/blocks/" + blockId + "/completion").content("{\"completed\":true}"), token, 200);
        assertThat(totalXp(token)).isEqualTo(20);

        body(delete("/api/v1/subjects/" + subjectId), token, 204);

        assertThat(totalXp(token)).isZero();
        assertThat(count("select count(*) from horarios_academicos where usuario_id = :u", user)).isZero();
    }

    @Test
    void aReviewCompletesItsReviewBlockAndPrivacyHidesTheNotes() throws Exception {
        String token = register("cross-review@example.com");
        UUID user = userId(token);
        String subject = body(post("/api/v1/subjects").content("{\"name\":\"Historia\",\"credits\":6}"), token, 201);
        String subjectId = JsonPath.read(subject, "$.id");
        String note = body(post("/api/v1/notes").content("""
                {"subjectId":"%s","title":"Barroco","content":"# Barroco","visibility":"PUBLIC"}""".formatted(subjectId)),
                token, 201);
        String noteId = JsonPath.read(note, "$.id");
        String material = body(post("/api/v1/study-materials")
                .content("{\"originType\":\"NOTE\",\"originId\":\"" + noteId + "\"}"), token, 201);
        String materialId = JsonPath.read(material, "$.id");

        String first = body(post("/api/v1/study-materials/" + materialId + "/reviews").content("{\"quality\":4}"),
                token, 200);
        assertThat((Integer) JsonPath.read(first, "$.xpAwarded")).isEqualTo(5);
        String pendingSql = "select count(*) from horarios_academicos where usuario_id = :u"
                + " and material_estudio_id = '" + materialId + "' and completado = false";
        assertThat(count(pendingSql, user)).isEqualTo(1);

        // El bloque pendiente pasa a hoy (repaso atrasado): el siguiente repaso lo completa sin XP de bloque.
        jdbc.sql("""
                        update horarios_academicos set hora_inicio = now() - interval '2 hours',
                               hora_fin = now() - interval '90 minutes'
                        where usuario_id = :u and material_estudio_id = :m""")
                .param("u", user).param("m", UUID.fromString(materialId)).update();
        String second = body(post("/api/v1/study-materials/" + materialId + "/reviews").content("{\"quality\":4}"),
                token, 200);
        assertThat((Integer) JsonPath.read(second, "$.xpAwarded")).isZero();
        assertThat(count("select count(*) from horarios_academicos where usuario_id = :u and material_estudio_id = '"
                + materialId + "' and completado = true and xp_bloque_otorgado = false", user)).isEqualTo(1);
        assertThat(count(pendingSql, user)).isEqualTo(1);
        assertThat(totalXp(token)).isEqualTo(5);

        // UserPrivacyChanged solo se publica si la privacidad cambia: se pasa a público y luego a privado.
        body(patch("/api/v1/me").content("{\"privacy\":\"PUBLIC\"}"), token, 200);
        body(patch("/api/v1/me").content("{\"privacy\":\"PRIVATE\"}"), token, 200);
        assertThat((String) JsonPath.read(body(get("/api/v1/notes/" + noteId), token, 200), "$.visibility"))
                .isEqualTo("PRIVATE");
    }

    @Test
    void theSportBlockOfTheRoutineDayFollowsTheTrainingSessionWithoutExtraXp() throws Exception {
        String token = register("cross-sport@example.com");
        UUID user = userId(token);
        String exerciseId = jdbc.sql("SELECT CAST(id AS text) FROM ejercicios WHERE COALESCE(activo, true)"
                + " ORDER BY nombre LIMIT 1").query(String.class).single();
        String routine = body(post("/api/v1/routines").content("""
                {"name":"Rutina corta","goal":"HYPERTROPHY","visibility":"PRIVATE","weeks":[{"days":[
                  {"dayNumber":1,"exercises":[{"exerciseId":"%s","sets":3,"reps":10,"restSeconds":60}]}]}]}"""
                .formatted(exerciseId)), token, 201);
        String routineId = JsonPath.read(routine, "$.id");
        String dayId = JsonPath.read(routine, "$.weeks[0].days[0].id");
        // Bloque de deporte de hoy (Europe/Madrid, la zona de sesiones y calendario) para ese día de rutina.
        OffsetDateTime noon = LocalDate.now(MADRID).atTime(LocalTime.NOON).atZone(MADRID).toOffsetDateTime();
        UUID blockId = UUID.randomUUID();
        jdbc.sql("""
                        insert into horarios_academicos (id, usuario_id, hora_inicio, hora_fin, tipo_actividad,
                                                         rutina_id, dia_rutina_id, dia_semana)
                        values (:id, :u, :start, :end, 'deporte', :routine, :day, 1)""")
                .param("id", blockId).param("u", user)
                .param("start", noon.withOffsetSameInstant(ZoneOffset.UTC))
                .param("end", noon.plusHours(1).withOffsetSameInstant(ZoneOffset.UTC))
                .param("routine", UUID.fromString(routineId)).param("day", UUID.fromString(dayId))
                .update();

        String session = body(post("/api/v1/training/sessions")
                .content("{\"routineId\":\"" + routineId + "\",\"dayId\":\"" + dayId + "\"}"), token, 201);
        String sessionId = JsonPath.read(session, "$.id");
        String finish = body(post("/api/v1/training/sessions/" + sessionId + "/finish")
                .content("{\"durationSeconds\":1800,\"rpe\":5}"), token, 200);
        int sessionXp = JsonPath.read(finish, "$.session.xpAwarded");

        String blockState = "select count(*) from horarios_academicos where id = '" + blockId + "' and usuario_id = :u"
                + " and completado = true and xp_bloque_otorgado = false";
        assertThat(count(blockState, user)).isEqualTo(1);
        assertThat(totalXp(token)).isEqualTo(sessionXp);

        body(post("/api/v1/training/sessions/" + sessionId + "/unmark"), token, 200);
        assertThat(count(blockState, user)).isZero();
        assertThat(totalXp(token)).isZero();
    }
}
