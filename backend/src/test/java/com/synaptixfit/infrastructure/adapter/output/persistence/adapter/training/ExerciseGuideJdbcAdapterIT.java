package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
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
 * Guía del ejercicio sobre PostgreSQL real ({@link ExerciseGuideJdbcAdapter}): los consejos de V1033
 * (arrays de texto) con su idioma de reserva, y la nota propia, que solo ve su dueño, se puede guardar
 * dos veces seguidas y se borra con la cuenta.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ExerciseGuideJdbcAdapterIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    private record Account(UUID id, String token) {}

    private final String suffix = UUID.randomUUID().toString().substring(0, 8);

    private Account register(String name) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + name.toLowerCase() + suffix + "@example.com\","
                                + "\"password\":\"secret123\",\"fullName\":\"" + name + suffix + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return new Account(UUID.fromString(JsonPath.read(body, "$.user.id")), JsonPath.read(body, "$.accessToken"));
    }

    private static MockHttpServletRequestBuilder as(Account a, MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + a.token()).contentType(MediaType.APPLICATION_JSON);
    }

    @Test
    void tipsComeFromTheMigrationInTheAppLanguage() throws Exception {
        Account ana = register("Ana");
        UUID exercise = jdbc.sql("SELECT ejercicio_id FROM consejos_ejercicio WHERE idioma = 'fr' LIMIT 1")
                .query(UUID.class).single();

        mvc.perform(as(ana, get("/api/v1/exercises/" + exercise + "/tips")).header("Accept-Language", "fr"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.keyPoints[0]").isString())
                .andExpect(jsonPath("$.commonMistakes[0]").isString());
        // Un idioma sin consejos cae en el español, no en una lista vacía.
        mvc.perform(as(ana, get("/api/v1/exercises/" + exercise + "/tips")).header("Accept-Language", "de"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.keyPoints[0]").isString());
    }

    @Test
    void theNoteIsPrivateCanBeSavedTwiceAndGoesWithTheAccount() throws Exception {
        Account ana = register("Ana");
        Account bea = register("Bea");
        UUID exercise = jdbc.sql("SELECT id FROM ejercicios WHERE activo = true LIMIT 1").query(UUID.class).single();
        String url = "/api/v1/exercises/" + exercise + "/note";

        mvc.perform(as(ana, put(url)).content("{\"text\":\"Banco en el agujero 3\"}")).andExpect(status().isOk());
        mvc.perform(as(ana, put(url)).content("{\"text\":\"Banco en el agujero 4\"}")).andExpect(status().isOk());
        mvc.perform(as(ana, get(url))).andExpect(jsonPath("$.text").value("Banco en el agujero 4"));
        mvc.perform(as(bea, get(url))).andExpect(jsonPath("$.text").doesNotExist());

        // Baja de la cuenta (RGPD): la nota se va con ella.
        mvc.perform(as(ana, delete("/api/v1/me")).content("{\"password\":\"secret123\"}"))
                .andExpect(status().isNoContent());
        assertThat(jdbc.sql("SELECT count(*) FROM notas_ejercicio WHERE usuario_id = :id").param("id", ana.id())
                .query(Integer.class).single()).isZero();
    }

    @Test
    void anUnknownExerciseIsNotFoundWhenReadingItsNoteToo() throws Exception {
        Account ana = register("Ana");
        mvc.perform(as(ana, get("/api/v1/exercises/" + UUID.randomUUID() + "/note")))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("EXERCISE_NOT_FOUND"));
    }
}
