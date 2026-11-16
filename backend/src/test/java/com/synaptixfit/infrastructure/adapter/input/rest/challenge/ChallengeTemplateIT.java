package com.synaptixfit.infrastructure.adapter.input.rest.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.ActivityKind;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Set;
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
 * Plantillas de retos productivos (ADR 0043) sobre PostgreSQL real: valida V1062, el alta desde una plantilla, la
 * regla en la respuesta y que no se repite un reto en marcha.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ChallengeTemplateIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;
    @Autowired
    private JdbcClient jdbc;
    @Autowired
    private ChallengeReferencePort references;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Estudiante T\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private String body(MockHttpServletRequestBuilder b, String token, int expected) throws Exception {
        return mvc.perform(b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().is(expected)).andReturn().getResponse().getContentAsString();
    }

    @Test
    @SuppressWarnings("unchecked")
    void templateStartsAPrivateChallengeCountedByTheServer() throws Exception {
        String token = register("plantillas-reto@example.com");

        String templates = body(get("/api/v1/challenges/templates").header("Accept-Language", "en"), token, 200);
        assertThat((List<String>) JsonPath.read(templates, "$[*].code"))
                .contains("primer_mes_entrenando", "entrena_en_examenes_2", "estudia_y_muevete_2", "pomodoro_diario",
                        "repasa_cada_dia", "empieza_a_correr", "registro_diario")
                .doesNotContain("entrena_en_examenes", "estudia_y_muevete", "primeros_5_km", "estudio_temprano")
                .hasSize(10);
        assertThat((List<Integer>) JsonPath.read(templates, "$[?(@.code == 'entrena_en_examenes_2')].rule.perUnit"))
                .containsExactly(2);
        assertThat((List<Integer>) JsonPath.read(templates, "$[?(@.code == 'empieza_a_correr')].rule.target"))
                .containsExactly(8);
        assertThat((List<String>) JsonPath.read(templates, "$[?(@.code == 'pomodoro_diario')].title"))
                .containsExactly("One Pomodoro a day");
        assertThat((List<Boolean>) JsonPath.read(templates, "$[?(@.code == 'registro_diario')].rule.privateOnly"))
                .containsExactly(true);
        List<String> ids = JsonPath.read(templates, "$[?(@.code == 'pomodoro_diario')].id");

        String challenge = body(post("/api/v1/challenges/templates/" + ids.getFirst() + "/start"), token, 201);
        assertThat((String) JsonPath.read(challenge, "$.title")).isEqualTo("Un Pomodoro al día");
        assertThat((String) JsonPath.read(challenge, "$.visibility")).isEqualTo("PRIVATE");
        assertThat((Boolean) JsonPath.read(challenge, "$.tracksRule")).isTrue();
        assertThat((String) JsonPath.read(challenge, "$.rule.metric")).isEqualTo("FOCUS_MINUTES");
        assertThat((Integer) JsonPath.read(challenge, "$.rule.target")).isEqualTo(5);
        assertThat((Integer) JsonPath.read(challenge, "$.rule.met")).isZero();
        assertThat((String) JsonPath.read(challenge, "$.templateCode")).isEqualTo("pomodoro_diario");

        String id = JsonPath.read(challenge, "$.id");
        String again = body(get("/api/v1/challenges/" + id), token, 200);
        assertThat((Integer) JsonPath.read(again, "$.rule.perUnit")).isEqualTo(25);

        mvc.perform(post("/api/v1/challenges/templates/" + ids.getFirst() + "/start")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CHALLENGE_TEMPLATE_ALREADY_ACTIVE"));
        String after = body(get("/api/v1/challenges/templates"), token, 200);
        assertThat((List<Boolean>) JsonPath.read(after, "$[?(@.code == 'pomodoro_diario')].running"))
                .containsExactly(true);
    }

    /** ADR 0054: retirar una plantilla no toca los retos en curso que salieron de ella; solo deja de ofrecerse. */
    @Test
    @SuppressWarnings("unchecked")
    void retiringATemplateKeepsTheChallengesInProgress() throws Exception {
        String token = register("plantillas-retiradas@example.com");
        String templates = body(get("/api/v1/challenges/templates"), token, 200);
        List<String> ids = JsonPath.read(templates, "$[?(@.code == 'simulacro_semanal')].id");
        String challenge = body(post("/api/v1/challenges/templates/" + ids.getFirst() + "/start"), token, 201);
        String id = JsonPath.read(challenge, "$.id");

        jdbc.sql("UPDATE plantillas_reto SET activa = false WHERE codigo = 'simulacro_semanal'").update();
        try {
            String still = body(get("/api/v1/challenges/" + id), token, 200);
            assertThat((String) JsonPath.read(still, "$.rule.metric")).isEqualTo("TESTS");
            assertThat((Integer) JsonPath.read(still, "$.rule.target")).isEqualTo(4);
            String after = body(get("/api/v1/challenges/templates"), token, 200);
            assertThat((List<String>) JsonPath.read(after, "$[*].code")).doesNotContain("simulacro_semanal");
            mvc.perform(post("/api/v1/challenges/templates/" + ids.getFirst() + "/start")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.code").value("CHALLENGE_TEMPLATE_NOT_FOUND"));
        } finally {
            jdbc.sql("UPDATE plantillas_reto SET activa = true WHERE codigo = 'simulacro_semanal'").update();
        }
        assertThat(jdbc.sql("SELECT count(*) FROM plantillas_reto WHERE activa = false").query(Integer.class)
                .single()).isEqualTo(4);
    }

    /**
     * Lo que leen los retos automáticos de otros módulos: una carrera cuenta por su actividad con origen GPS (se guarda
     * antes del evento que recuenta), no una apuntada a mano; del registro diario solo la fecha; una semana
     * planificada solo si dio la experiencia.
     */
    @Test
    void activityReadsRunsCheckInsAndPlannedWeeks() throws Exception {
        register("actividad-retos@example.com");
        UUID user = jdbc.sql("SELECT id FROM usuarios WHERE email = 'actividad-retos@example.com'")
                .query(UUID.class).single();
        Instant now = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        activity(user, now.plus(1, ChronoUnit.HOURS), "GPS");
        activity(user, now.plus(2, ChronoUnit.HOURS), "MANUAL");
        jdbc.sql("INSERT INTO estado_diario_usuario (usuario_id, fecha) VALUES (:u, :d)")
                .param("u", user).param("d", LocalDate.now()).update();
        // Creado hace diez días, pero la XP de planificar llegó ahora: cuenta por el momento de la XP.
        jdbc.sql("INSERT INTO planes_estudio (usuario_id, nombre, semana_inicio, semana_fin, creado_en,"
                        + " xp_planificacion_otorgado, xp_planificacion_en) VALUES (:u, 'Plan', :m, :s, :created, true,"
                        + " :awarded)")
                .param("u", user).param("m", LocalDate.of(2026, 11, 16)).param("s", LocalDate.of(2026, 11, 22))
                .param("created", Timestamp.from(now.minus(10, ChronoUnit.DAYS)))
                .param("awarded", Timestamp.from(now))
                .update();

        List<ActivityFact> facts = references.activity(user,
                Set.of(ActivityKind.RUN, ActivityKind.CHECK_IN, ActivityKind.PLANNED_WEEK),
                now.minus(1, ChronoUnit.DAYS), now.plus(1, ChronoUnit.DAYS));

        assertThat(facts).filteredOn(f -> f.kind() == ActivityKind.RUN).hasSize(1);
        assertThat(facts).filteredOn(f -> f.kind() == ActivityKind.CHECK_IN)
                .singleElement().satisfies(f -> assertThat(f.at()).isNull());
        assertThat(facts).filteredOn(f -> f.kind() == ActivityKind.PLANNED_WEEK)
                .singleElement().satisfies(f -> assertThat(f.day()).isEqualTo(LocalDate.of(2026, 11, 16)));
    }

    private void activity(UUID user, Instant start, String source) {
        UUID block = UUID.randomUUID();
        jdbc.sql("INSERT INTO horarios_academicos (id, usuario_id, hora_inicio, hora_fin, tipo_actividad, completado)"
                        + " VALUES (:id, :u, :start, :end, 'deporte', true)")
                .param("id", block).param("u", user).param("start", Timestamp.from(start))
                .param("end", Timestamp.from(start.plus(40, ChronoUnit.MINUTES)))
                .update();
        jdbc.sql("INSERT INTO actividades_apuntadas (bloque_id, usuario_id, clase, minutos_reales, origen, creado_en)"
                        + " VALUES (:b, :u, 'RUN', 35, :o, :t)")
                .param("b", block).param("u", user).param("o", source).param("t", Timestamp.from(start))
                .update();
    }
}
