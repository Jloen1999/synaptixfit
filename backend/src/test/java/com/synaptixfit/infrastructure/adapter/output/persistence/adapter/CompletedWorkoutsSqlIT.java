package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserActivity;
import com.synaptixfit.domain.model.admin.AdminUserCounts;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import com.synaptixfit.domain.model.badge.BadgeActivitySnapshot;
import com.synaptixfit.domain.model.dashboard.DashboardReadModels.TrainingTotals;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.port.output.admin.AdminUserQueryPort;
import com.synaptixfit.domain.port.output.admin.PlatformMetricsQueryPort;
import com.synaptixfit.domain.port.output.analytics.AnalyticsSourcePort;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.dashboard.DashboardReadPort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
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

/**
 * La definición única de «entreno hecho» ({@link CompletedWorkoutsSql}) sobre PostgreSQL real: Inicio, Progreso, el
 * panel de administración, los retos y las insignias cuentan las mismas filas (vocabulario.md §3). Los retos y las
 * insignias, además, dejan fuera lo que no llega al mínimo de minutos de {@code TrainingRewards}.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CompletedWorkoutsSqlIT {

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    private static final Instant FROM = Instant.parse("2026-11-09T00:00:00Z");
    private static final Instant TO = Instant.parse("2026-11-16T00:00:00Z");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;
    @Autowired
    private JdbcClient jdbc;
    @Autowired
    private DashboardReadPort dashboard;
    @Autowired
    private AnalyticsSourcePort analytics;
    @Autowired
    private AdminUserQueryPort adminUsers;
    @Autowired
    private PlatformMetricsQueryPort platform;
    @Autowired
    private ChallengeReferencePort challenges;
    @Autowired
    private UserActivityPort badges;

    private UUID register() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"entrenos" + suffix + "@example.com\","
                                + "\"password\":\"secret123\",\"fullName\":\"Entrenos " + suffix + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return UUID.fromString(JsonPath.read(body, "$.user.id"));
    }

    private void session(UUID user, Instant end, int minutes, int rpe, double kcal) {
        jdbc.sql("INSERT INTO sesiones_registradas (usuario_id, duracion_minutos, rpe, calorias_quemadas, completada_en)"
                        + " VALUES (:u, :m, :rpe, :kcal, :end)")
                .param("u", user).param("m", minutes).param("rpe", rpe).param("kcal", kcal)
                .param("end", Timestamp.from(end))
                .update();
    }

    /** Evento del calendario con su actividad apuntada (como una carrera GPS o a mano). */
    private UUID activity(UUID user, Instant end, ActivityType type, boolean done) {
        return activity(user, end, type, done, null);
    }

    private UUID activity(UUID user, Instant end, ActivityType type, boolean done, UUID routineDay) {
        UUID block = UUID.randomUUID();
        jdbc.sql("INSERT INTO horarios_academicos (id, usuario_id, hora_inicio, hora_fin, tipo_actividad, completado,"
                        + " dia_rutina_id) VALUES (:id, :u, :start, :end, :type, :done, :day)")
                .param("id", block).param("u", user)
                .param("start", Timestamp.from(end.minus(40, ChronoUnit.MINUTES))).param("end", Timestamp.from(end))
                .param("type", type.code()).param("done", done).param("day", routineDay)
                .update();
        jdbc.sql("INSERT INTO actividades_apuntadas (bloque_id, usuario_id, clase, minutos_reales, creado_en)"
                        + " VALUES (:b, :u, 'RUN', 35, :t)")
                .param("b", block).param("u", user).param("t", Timestamp.from(end))
                .update();
        return block;
    }

    /** Carrera GPS del evento (kcal calculadas) y su registro de carga física (esfuerzo): una fila de cada una. */
    private void gpsRunWithLoad(UUID user, UUID block, Instant end, int kcal, int effort) {
        jdbc.sql("INSERT INTO carreras_gps (bloque_id, usuario_id, clave_cliente, clase, iniciada_en, terminada_en,"
                        + " segundos_movimiento, distancia_metros, desnivel_metros, kcal, esfuerzo, tramos, ruta,"
                        + " creado_en) VALUES (:b, :u, :key, 'RUN', :start, :end, 2100, 6000, 20, :kcal, :effort,"
                        + " CAST('[]' AS jsonb), CAST('[]' AS jsonb), :end)")
                .param("b", block).param("u", user).param("key", UUID.randomUUID())
                .param("start", Timestamp.from(end.minus(35, ChronoUnit.MINUTES))).param("end", Timestamp.from(end))
                .param("kcal", kcal).param("effort", effort)
                .update();
        jdbc.sql("INSERT INTO registros_carga_fisica (usuario_id, rpe_sesion, duracion_minutos, bloque_id)"
                        + " VALUES (:u, :rpe, 35, :b)")
                .param("u", user).param("rpe", effort).param("b", block)
                .update();
    }

    /** Día de una rutina: su evento del calendario es el reflejo de la sesión, que ya cuenta por sí misma. */
    private UUID routineDay(UUID user) {
        UUID routine = UUID.randomUUID();
        UUID week = UUID.randomUUID();
        UUID day = UUID.randomUUID();
        jdbc.sql("INSERT INTO rutinas (id, usuario_id, nombre, objetivo) VALUES (:id, :u, 'Torso-Pierna', 'Fuerza Máxima')")
                .param("id", routine).param("u", user).update();
        jdbc.sql("INSERT INTO semanas_rutina (id, rutina_id, numero_semana) VALUES (:id, :r, 1)")
                .param("id", week).param("r", routine).update();
        jdbc.sql("INSERT INTO dias_rutina (id, semana_id, numero_dia) VALUES (:id, :w, 1)")
                .param("id", day).param("w", week).update();
        return day;
    }

    @Test
    void everyReaderCountsTheSameWorkouts() throws Exception {
        UUID user = register();
        session(user, Instant.parse("2026-11-10T18:00:00Z"), 45, 9, 300);
        // Demasiado corta para insignias y retos, pero es un entreno hecho para Inicio, Progreso y el panel.
        session(user, Instant.parse("2026-11-11T18:00:00Z"), 5, 4, 20);
        Instant run = Instant.parse("2026-11-12T08:00:00Z");
        UUID runBlock = activity(user, run, ActivityType.SPORT, true);
        gpsRunWithLoad(user, runBlock, run, 250, 7);
        // Desmarcada en el calendario: no cuenta en ningún sitio.
        activity(user, Instant.parse("2026-11-13T08:00:00Z"), ActivityType.SPORT, false);
        // Una fila suelta en un evento que dejó de ser deporte tampoco es un entreno.
        activity(user, Instant.parse("2026-11-14T08:00:00Z"), ActivityType.STUDY, true);
        // El evento de un día de rutina refleja su sesión: contarlo sería contarla dos veces.
        activity(user, Instant.parse("2026-11-13T19:00:00Z"), ActivityType.SPORT, true, routineDay(user));

        TrainingTotals totals = dashboard.trainingTotals(user, FROM, TO);
        List<CompletedSession> progress = analytics.completedTrainingSessions(user, FROM);
        List<CompletedSession> admin = adminUsers.completedTrainingSessions(user, FROM, TO);
        AdminUserCounts counts = adminUsers.counts(user);
        List<UserActivity> platformRows = platform.completedTrainingSessions(FROM, TO).stream()
                .filter(a -> a.userId().equals(user)).toList();

        assertThat(totals.sessions()).isEqualTo(3);
        assertThat(totals.minutes()).isEqualTo(45 + 5 + 35);
        // Las kcal de la carrera y su esfuerzo salen una vez (una fila por evento en cada tabla).
        assertThat(totals.calories()).isEqualTo(300 + 20 + 250);
        assertThat(progress).filteredOn(s -> s.completedAt().equals(run))
                .singleElement().satisfies(s -> assertThat(s.rpe()).isEqualTo(7));
        assertThat(progress).hasSize(3);
        assertThat(admin).hasSize(3);
        assertThat(counts.trainingSessions()).isEqualTo(3);
        assertThat(counts.trainingMinutes()).isEqualTo(85);
        assertThat(platformRows).hasSize(3);
        assertThat(dashboard.lastTrainingSession(user)).contains(Instant.parse("2026-11-12T08:00:00Z"));
        // El panel solo enseña el esfuerzo de las sesiones de gimnasio, como antes de unificar la definición.
        assertThat(admin).filteredOn(s -> s.rpe() != null).hasSize(2);
        assertThat(counts.averageRpe()).isEqualTo(6.5);

        // Retos e insignias: los mismos entrenos, sin la sesión de 5 minutos.
        assertThat(challenges.completedTrainingSessions(user, FROM, TO)).isEqualTo(2);
        BadgeActivitySnapshot snapshot = badges.snapshot(user, ZONE);
        assertThat(snapshot.sessionsCompleted()).isEqualTo(2);
        assertThat(snapshot.highRpeSessions()).isEqualTo(1);
        assertThat(snapshot.sessionDays()).containsExactlyInAnyOrder(LocalDate.of(2026, 11, 10),
                LocalDate.of(2026, 11, 12));
    }
}
