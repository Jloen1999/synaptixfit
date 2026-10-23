package com.synaptixfit.infrastructure.adapter.input.rest.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
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
 * Catálogo de ejercicios ampliado (V850) sobre PostgreSQL embebido: categorías, alternativas para
 * cambiar un ejercicio, calentamiento y vuelta a la calma, y la referencia «la última vez».
 */
@SpringBootTest
@AutoConfigureMockMvc
class ExerciseCatalogIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    @Test
    void expandedCatalogWithCategoriesAlternativesAndBookends() throws Exception {
        String token = register("exercise-catalog-it@example.com");
        assertThat(jdbc.sql("SELECT COUNT(*) FROM ejercicios").query(Long.class).single()).isGreaterThan(5000);
        assertThat(jdbc.sql("SELECT COUNT(*) FROM ejercicios WHERE categoria IS NULL").query(Long.class).single())
                .isZero();
        assertThat(jdbc.sql("SELECT COUNT(*) FROM ejercicios WHERE cardinality(instrucciones) = 0")
                .query(Long.class).single()).isZero();

        mvc.perform(get("/api/v1/exercises").param("category", "STRETCHING").param("size", "5")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].category").value("STRETCHING"));

        // Un ejercicio de fuerza de cuádriceps del catálogo original.
        UUID squat = jdbc.sql("SELECT e.id FROM ejercicios e JOIN ejercicio_musculo_objetivo j ON j.ejercicio_id = e.id "
                        + "JOIN musculos m ON m.id = j.musculo_id WHERE m.nombre = 'Cuádriceps' "
                        + "AND e.categoria = 'strength' AND e.url_gif IS NOT NULL ORDER BY e.nombre LIMIT 1")
                .query(UUID.class).single();

        String alternatives = mvc.perform(get("/api/v1/exercises/" + squat + "/alternatives")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        List<String> ids = JsonPath.read(alternatives, "$[*].id");
        assertThat(ids).isNotEmpty().hasSizeLessThanOrEqualTo(8).doesNotContain(squat.toString());

        mvc.perform(get("/api/v1/exercises/bookends").param("exerciseIds", squat.toString())
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.warmUp").isNotEmpty())
                .andExpect(jsonPath("$.coolDown[0].category").value("STRETCHING"));

        // Sesión de cuerpo entero: muchos músculos y candidatos de sobra. Antes se cortaban por orden
        // alfabético antes de filtrar la categoría y la vuelta a la calma salía vacía.
        List<String> fullBody = jdbc.sql("SELECT DISTINCT ON (j.musculo_id) CAST(e.id AS text) FROM ejercicios e "
                        + "JOIN ejercicio_musculo_objetivo j ON j.ejercicio_id = e.id "
                        + "WHERE e.categoria = 'strength' AND e.url_gif IS NOT NULL ORDER BY j.musculo_id, e.nombre LIMIT 8")
                .query(String.class).list();
        assertThat(fullBody).hasSizeGreaterThanOrEqualTo(6);
        String fullBodyBookends = mvc.perform(get("/api/v1/exercises/bookends")
                        .param("exerciseIds", fullBody.toArray(String[]::new))
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        List<String> warmUp = JsonPath.read(fullBodyBookends, "$.warmUp[*].category");
        List<String> coolDown = JsonPath.read(fullBodyBookends, "$.coolDown[*].category");
        assertThat(warmUp).hasSizeGreaterThanOrEqualTo(3).allMatch(c -> c.equals("MOBILITY") || c.equals("YOGA"));
        assertThat(coolDown).hasSizeGreaterThanOrEqualTo(3).allMatch(c -> c.equals("STRETCHING") || c.equals("YOGA"));

        mvc.perform(get("/api/v1/training/last-performance").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    private String register(String email) throws Exception {
        String response = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Deportista\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(response, "$.accessToken");
    }
}
