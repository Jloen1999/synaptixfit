package com.synaptixfit.infrastructure.adapter.input.rest.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
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
 * Compartir una rutina por enlace (ADR 0043) sobre PostgreSQL real: valida V1063, que el resumen no lleve datos del
 * dueño, la copia privada y que un enlace revocado deja de valer.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RoutineShareLinkIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Persona T\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private String call(MockHttpServletRequestBuilder b, String token, String json, int expected) throws Exception {
        return mvc.perform(b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON)
                        .content(json == null ? "" : json))
                .andExpect(status().is(expected)).andReturn().getResponse().getContentAsString();
    }

    @Test
    void aFriendCopiesTheRoutineUntilTheOwnerStopsSharing() throws Exception {
        String owner = register("comparte@example.com");
        String friend = register("copia@example.com");
        String templates = call(get("/api/v1/training/templates"), owner, null, 200);
        List<String> ids = JsonPath.read(templates, "$[?(@.code == 'mantener_examenes_casa')].id");
        String routine = call(post("/api/v1/training/templates/" + ids.getFirst() + "/use"), owner, null, 201);
        String routineId = JsonPath.read(routine, "$.id");

        String status = call(get("/api/v1/routines/" + routineId + "/share-links"), owner, null, 200);
        assertThat((Object) JsonPath.read(status, "$.sharedUntil")).isNull();
        String link = call(post("/api/v1/routines/" + routineId + "/share-links"), owner, null, 201);
        String token = JsonPath.read(link, "$.token");
        assertThat((String) JsonPath.read(link, "$.expiresAt")).isNotBlank();
        mvc.perform(post("/api/v1/routines/" + routineId + "/share-links").header("Authorization", "Bearer " + friend))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("ROUTINE_NOT_FOUND"));

        String body = "{\"token\":\"" + token + "\"}";
        String preview = call(post("/api/v1/shared-routines/preview"), friend, body, 200);
        assertThat((String) JsonPath.read(preview, "$.name")).isEqualTo("Mantenerte en exámenes · en casa");
        assertThat((Integer) JsonPath.read(preview, "$.daysPerWeek")).isEqualTo(2);
        assertThat(preview).doesNotContain("ownerId").doesNotContain("authorName").doesNotContain("Persona T");

        String copy = call(post("/api/v1/shared-routines/copy"), friend, body, 201);
        assertThat((String) JsonPath.read(copy, "$.visibility")).isEqualTo("PRIVATE");
        assertThat((Boolean) JsonPath.read(copy, "$.owned")).isTrue();
        assertThat((Object) JsonPath.read(copy, "$.origin")).isNull();

        call(delete("/api/v1/routines/" + routineId + "/share-links"), owner, null, 204);
        mvc.perform(post("/api/v1/shared-routines/preview").header("Authorization", "Bearer " + friend)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("ROUTINE_SHARE_LINK_NOT_FOUND"));
        mvc.perform(post("/api/v1/shared-routines/preview").header("Authorization", "Bearer " + friend)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"token\":\"\"}"))
                .andExpect(status().isBadRequest());
    }
}
