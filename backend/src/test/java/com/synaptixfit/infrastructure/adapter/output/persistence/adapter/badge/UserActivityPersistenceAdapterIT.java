package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.badge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.model.badge.BadgeActivitySnapshot;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
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

/**
 * Lo que leen las insignias sobre PostgreSQL real ({@link UserActivityPersistenceAdapter}): «Planificador nato» cuenta
 * solo las semanas que dieron la XP de planificar ({@code xp_planificacion_otorgado}, ADR 0038), y una carrera o
 * actividad hecha cuenta como un entreno más (vocabulario.md §3), también en los días de entreno.
 */
@SpringBootTest
@AutoConfigureMockMvc
class UserActivityPersistenceAdapterIT {

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    @Autowired
    private UserActivityPort port;

    private UUID register() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"insignias" + suffix + "@example.com\","
                                + "\"password\":\"secret123\",\"fullName\":\"Insignias " + suffix + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return UUID.fromString(JsonPath.read(body, "$.user.id"));
    }

    private void plan(UUID user, LocalDate weekStart, boolean xpGiven) {
        jdbc.sql("INSERT INTO planes_estudio (id, usuario_id, nombre, semana_inicio, semana_fin,"
                        + " xp_planificacion_otorgado) VALUES (:id, :u, 'Semana', :start, :end, :xp)")
                .param("id", UUID.randomUUID()).param("u", user)
                .param("start", weekStart).param("end", weekStart.plusDays(6)).param("xp", xpGiven)
                .update();
    }

    /** Evento de deporte del calendario con su actividad apuntada (como una carrera GPS o a mano). */
    private void activity(UUID user, Instant end, boolean done) {
        UUID block = UUID.randomUUID();
        jdbc.sql("INSERT INTO horarios_academicos (id, usuario_id, hora_inicio, hora_fin, tipo_actividad, completado)"
                        + " VALUES (:id, :u, :start, :end, :type, :done)")
                .param("id", block).param("u", user)
                .param("start", Timestamp.from(end.minus(40, ChronoUnit.MINUTES))).param("end", Timestamp.from(end))
                .param("type", ActivityType.SPORT.code()).param("done", done)
                .update();
        jdbc.sql("INSERT INTO actividades_apuntadas (bloque_id, usuario_id, clase, minutos_reales, creado_en)"
                        + " VALUES (:b, :u, 'RUN', 35, :t)")
                .param("b", block).param("u", user).param("t", Timestamp.from(end))
                .update();
    }

    @Test
    void plannerBadgeCountsOnlyWeeksThatGaveThePlanningXp() throws Exception {
        UUID user = register();
        LocalDate monday = LocalDate.of(2026, 11, 2);
        plan(user, monday, true);
        plan(user, monday.plusWeeks(1), true);
        // Un plan guardado sin la XP (p. ej. por una app antigua sin eventos) no acerca la insignia.
        plan(user, monday.plusWeeks(2), false);

        BadgeActivitySnapshot snapshot = port.snapshot(user, ZONE);

        assertThat(snapshot.studyPlans()).isEqualTo(2);
    }

    @Test
    void doneActivitiesCountAsWorkoutsAndTrainingDays() throws Exception {
        UUID user = register();
        Instant run = Instant.parse("2026-11-10T08:00:00Z");
        activity(user, run, true);
        // Desmarcada en el calendario: ya no cuenta.
        activity(user, Instant.parse("2026-11-11T08:00:00Z"), false);

        BadgeActivitySnapshot snapshot = port.snapshot(user, ZONE);

        assertThat(snapshot.sessionsCompleted()).isEqualTo(1);
        assertThat(snapshot.highRpeSessions()).isZero();
        assertThat(snapshot.sessionDays()).containsExactly(LocalDate.of(2026, 11, 10));
    }
}
