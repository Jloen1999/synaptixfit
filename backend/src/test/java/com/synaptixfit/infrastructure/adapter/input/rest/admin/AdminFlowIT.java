package com.synaptixfit.infrastructure.adapter.input.rest.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Flujo completo del panel de administración y del autoservicio RGPD sobre PostgreSQL real:
 * valida las consultas JdbcClient contra el esquema, la seguridad por rol y los códigos de error.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    @Test
    void adminPanelAndSelfServiceFlow() throws Exception {
        register("admin-it@example.com", "Admin Integra");
        String userToken = register("member-it@example.com", "Miembro Integra");
        jdbc.sql("UPDATE usuarios SET rol = 'admin' WHERE email = 'admin-it@example.com'").update();
        String adminToken = login("admin-it@example.com");
        UUID adminId = idOf("admin-it@example.com");
        UUID memberId = idOf("member-it@example.com");

        // Seguridad: un usuario normal no entra en el panel.
        mvc.perform(get("/api/v1/admin/metrics").header("Authorization", "Bearer " + userToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("FORBIDDEN"));

        // KPIs y tendencia.
        jdbc.sql("""
                INSERT INTO sesiones_registradas (usuario_id, duracion_minutos, rpe, calorias_quemadas, completada_en)
                VALUES (:id, 45, 7, 320, now())
                """).param("id", memberId).update();
        mvc.perform(as(adminToken, get("/api/v1/admin/metrics")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalUsers").value(greaterThanOrEqualTo(2)))
                .andExpect(jsonPath("$.trainingSessionsToday").value(greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.activeUsersToday").value(greaterThanOrEqualTo(1)));
        mvc.perform(as(adminToken, get("/api/v1/admin/metrics/trend").param("days", "7")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(7))
                .andExpect(jsonPath("$[6].trainingSessions").value(greaterThanOrEqualTo(1)));

        // Búsqueda, ficha, estadísticas, gráficos y línea de tiempo.
        mvc.perform(as(adminToken, get("/api/v1/admin/users").param("query", "MEMBER-it")
                        .param("sort", "XP").param("direction", "ASC")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].email").value("member-it@example.com"))
                .andExpect(jsonPath("$.items[0].role").value("USER"));
        mvc.perform(as(adminToken, get("/api/v1/admin/users").param("role", "ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[*].email", hasItem("admin-it@example.com")));
        mvc.perform(as(adminToken, get("/api/v1/admin/users/" + memberId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.account.email").value("member-it@example.com"))
                .andExpect(jsonPath("$.wellbeingProfile").isEmpty());
        mvc.perform(as(adminToken, get("/api/v1/admin/users/" + memberId + "/stats")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.trainingSessions").value(1))
                .andExpect(jsonPath("$.trainingMinutes").value(45))
                .andExpect(jsonPath("$.caloriesBurned").value(320));
        mvc.perform(as(adminToken, get("/api/v1/admin/users/" + memberId + "/activity").param("weeks", "4")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(4))
                .andExpect(jsonPath("$[3].trainingMinutes").value(45));
        mvc.perform(as(adminToken, get("/api/v1/admin/users/" + memberId + "/timeline")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[*].type", hasItem("TRAINING_SESSION")))
                .andExpect(jsonPath("$.items[*].type", hasItem("ACCOUNT_CREATED")));

        // Shadowban auditado.
        mvc.perform(as(adminToken, put("/api/v1/admin/users/" + memberId + "/shadowban"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"shadowbanned\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.shadowbanned").value(true));
        mvc.perform(as(adminToken, get("/api/v1/admin/audit").param("action", "ACTIVATE_SHADOWBAN")
                        .param("entityId", memberId.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].adminEmail").value("admin-it@example.com"))
                .andExpect(jsonPath("$.items[0].entityType").value("USER"))
                .andExpect(jsonPath("$.items[0].details.after.shadowbanned").value(true));

        // Reglas: no auto-objetivo y email único.
        mvc.perform(as(adminToken, put("/api/v1/admin/users/" + adminId + "/role"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"USER\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("ADMIN_CANNOT_TARGET_SELF"));
        mvc.perform(as(adminToken, patch("/api/v1/admin/users/" + memberId))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"email\":\"admin-it@example.com\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ADMIN_EMAIL_ALREADY_IN_USE"));
        mvc.perform(as(adminToken, put("/api/v1/admin/users/" + memberId + "/progress"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"level\":4,\"levelXp\":120}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.level").value(4))
                .andExpect(jsonPath("$.totalXp").value(720));

        // Bloqueo: las cuentas nuevas nacen ocultas.
        mvc.perform(as(adminToken, put("/api/v1/admin/lockdown"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"active\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(true))
                .andExpect(jsonPath("$.startedBy").value(adminId.toString()));
        register("late-it@example.com", "Llega Tarde");
        mvc.perform(as(adminToken, put("/api/v1/admin/lockdown"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"active\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(false));
        UUID lateId = idOf("late-it@example.com");
        mvc.perform(as(adminToken, get("/api/v1/admin/users").param("query", "late-it").param("shadowbanned", "true")))
                .andExpect(jsonPath("$.totalItems").value(1));
        mvc.perform(as(adminToken, get("/api/v1/admin/audit").param("entityType", "PLATFORM_SETTINGS")))
                .andExpect(jsonPath("$.totalItems").value(2))
                .andExpect(jsonPath("$.items[0].action").value("DEACTIVATE_LOCKDOWN"));

        // Exportación RGPD (admin y autoservicio).
        String adminExport = mvc.perform(as(adminToken, get("/api/v1/admin/users/" + memberId + "/export")))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CONTENT_DISPOSITION, containsString("attachment")))
                .andExpect(jsonPath("$.account.email").value("member-it@example.com"))
                .andExpect(jsonPath("$.trainingSessions.length()").value(1))
                .andReturn().getResponse().getContentAsString();
        assertThat(adminExport).doesNotContain("password_hash").doesNotContain("$2a$")
                .doesNotContain("fecha_nacimiento");
        mvc.perform(as(userToken, get("/api/v1/me/export")))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CONTENT_DISPOSITION, containsString(".json")))
                .andExpect(jsonPath("$.userId").value(memberId.toString()))
                .andExpect(jsonPath("$.routines").isArray());

        // Vaciar datos conserva la cuenta.
        mvc.perform(as(adminToken, post("/api/v1/admin/users/" + memberId + "/wipe")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mode").value("CONTENT_WIPED"))
                .andExpect(jsonPath("$.deletedRecords").value(greaterThanOrEqualTo(1)));
        mvc.perform(as(adminToken, get("/api/v1/admin/users/" + memberId + "/stats")))
                .andExpect(jsonPath("$.trainingSessions").value(0));
        mvc.perform(as(adminToken, get("/api/v1/admin/users/" + memberId)))
                .andExpect(jsonPath("$.account.level").value(1))
                .andExpect(jsonPath("$.account.deleted").value(false));

        // Anonimizar: la cuenta deja de poder entrar y queda marcada como eliminada.
        mvc.perform(as(adminToken, post("/api/v1/admin/users/" + lateId + "/anonymize")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mode").value("ANONYMIZED"));
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"late-it@example.com\",\"password\":\"secret123\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(as(adminToken, get("/api/v1/admin/users/" + lateId)))
                .andExpect(jsonPath("$.account.deleted").value(true))
                .andExpect(jsonPath("$.account.email").value(containsString("synaptixfit.invalid")));
        mvc.perform(as(adminToken, get("/api/v1/admin/users").param("status", "DELETED")))
                .andExpect(jsonPath("$.items[*].id", hasItem(lateId.toString())));
        mvc.perform(as(adminToken, put("/api/v1/admin/users/" + lateId + "/shadowban"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"shadowbanned\":false}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("ADMIN_USER_DELETED"));
        mvc.perform(as(adminToken, delete("/api/v1/admin/users/" + lateId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mode").value("DELETED"));
        mvc.perform(as(adminToken, get("/api/v1/admin/users/" + lateId)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("ADMIN_USER_NOT_FOUND"));

        // Baja voluntaria.
        mvc.perform(as(userToken, delete("/api/v1/me"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"password\":\"wrong1234\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("GDPR_PASSWORD_MISMATCH"));
        mvc.perform(as(userToken, delete("/api/v1/me")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("GDPR_CONFIRMATION_REQUIRED"));
        mvc.perform(as(userToken, delete("/api/v1/me"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"password\":\"secret123\"}"))
                .andExpect(status().isNoContent());
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"member-it@example.com\",\"password\":\"secret123\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(as(adminToken, get("/api/v1/admin/audit").param("action", "SELF_DELETE_ACCOUNT")))
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].adminId").isEmpty());
        // El último administrador no puede darse de baja. La BD embebida se comparte entre tests y el orden
        // cambia de una máquina a otra: se deja a este como único administrador para no depender de él.
        jdbc.sql("UPDATE usuarios SET rol = 'usuario' WHERE rol = 'admin' AND email <> 'admin-it@example.com'")
                .update();
        mvc.perform(as(adminToken, delete("/api/v1/me"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"password\":\"secret123\"}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("GDPR_LAST_ADMIN"));
    }

    private String register(String email, String fullName) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\""
                                + fullName + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private String login(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private UUID idOf(String email) {
        return jdbc.sql("SELECT id FROM usuarios WHERE email = :email").param("email", email)
                .query(UUID.class).single();
    }

    private static MockHttpServletRequestBuilder as(String token, MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + token);
    }
}
