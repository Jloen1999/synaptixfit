package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.privacy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.port.output.privacy.UserDataErasurePort;
import com.synaptixfit.domain.port.output.privacy.UserDataExportPort;
import com.synaptixfit.domain.port.output.privacy.UserDataExportPort.Requester;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Instant;
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
 * Borrado de datos sobre PostgreSQL real ({@link UserDataErasureJdbcAdapter}): al anonimizar o vaciar una cuenta
 * no queda nada de salud (ciclo, ADR 0033) ni las notas de ejercicio vinculado al id; al anonimizar se van
 * también las opciones de avisos. La copia de datos que pide un administrador no lleva los de salud.
 */
@SpringBootTest
@AutoConfigureMockMvc
class UserDataErasureJdbcAdapterIT {

    private static final List<String> HEALTH_AND_NOTES = List.of("dias_ciclo", "seguimiento_ciclo", "notas_ejercicio");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    @Autowired
    private UserDataErasurePort erasure;

    @Autowired
    private UserDataExportPort exporter;

    private UUID register() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"borrar" + suffix + "@example.com\","
                                + "\"password\":\"secret123\",\"fullName\":\"Borrar " + suffix + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return UUID.fromString(JsonPath.read(body, "$.user.id"));
    }

    private void seed(UUID user) {
        Instant now = Instant.now();
        jdbc.sql("INSERT INTO seguimiento_ciclo (usuario_id, activo, consentimiento_en, actualizado_en) "
                        + "VALUES (:u, true, :t, :t)")
                .param("u", user).param("t", java.sql.Timestamp.from(now)).update();
        jdbc.sql("INSERT INTO dias_ciclo (usuario_id, fecha, regla, energia, molestias, nota, actualizado_en) "
                        + "VALUES (:u, CURRENT_DATE, true, 'LOW', 'CRAMPS', 'nota privada', :t)")
                .param("u", user).param("t", java.sql.Timestamp.from(now)).update();
        jdbc.sql("INSERT INTO opciones_avisos (usuario_id, racha, registro_diario, clases, actualizado_en) "
                        + "VALUES (:u, false, true, true, :t)")
                .param("u", user).param("t", java.sql.Timestamp.from(now)).update();
        UUID exercise = jdbc.sql("SELECT id FROM ejercicios LIMIT 1").query(UUID.class).single();
        jdbc.sql("INSERT INTO notas_ejercicio (usuario_id, ejercicio_id, texto) VALUES (:u, :e, 'rodilla')")
                .param("u", user).param("e", exercise).update();
        jdbc.sql("INSERT INTO aceptaciones_legales (id, usuario_id, version, aceptada_en) "
                        + "VALUES (:id, :u, '2026-11-04', :t)")
                .param("id", UUID.randomUUID()).param("u", user).param("t", java.sql.Timestamp.from(now)).update();
    }

    private long rows(String table, UUID user) {
        return jdbc.sql("SELECT count(*) FROM " + table + " WHERE usuario_id = :u")
                .param("u", user).query(Long.class).single();
    }

    @Test
    void anonymisingLeavesNoHealthDataNotesOrReminderOptions() throws Exception {
        UUID user = register();
        seed(user);

        erasure.erasePersonalData(user);

        HEALTH_AND_NOTES.forEach(table -> assertThat(rows(table, user)).as(table).isZero());
        assertThat(rows("opciones_avisos", user)).isZero();
        assertThat(rows("aceptaciones_legales", user)).isZero();
    }

    @Test
    void wipingContentRemovesHealthDataAndNotesButKeepsReminderOptions() throws Exception {
        UUID user = register();
        seed(user);

        erasure.wipeContent(user, Instant.now());

        HEALTH_AND_NOTES.forEach(table -> assertThat(rows(table, user)).as(table).isZero());
        // Vaciar conserva el perfil y la configuración, como las preferencias de notificación.
        assertThat(rows("opciones_avisos", user)).isEqualTo(1);
        // La cuenta sigue en uso: se conserva la constancia de la política aceptada (ADR 0034).
        assertThat(rows("aceptaciones_legales", user)).isEqualTo(1);
    }

    @Test
    void onlyTheOwnersCopyCarriesHealthData() throws Exception {
        UUID user = register();
        seed(user);

        String own = exporter.exportAsJson(user, Instant.now(), Requester.OWNER);
        String forAdmin = exporter.exportAsJson(user, Instant.now(), Requester.ADMINISTRATOR);

        assertThat(own).contains("cycleDays").contains("nota privada");
        assertThat(forAdmin).doesNotContain("cycleDays").doesNotContain("cycleTracking").doesNotContain("nota privada");
        assertThat(forAdmin).contains("exerciseNotes");
    }
}
