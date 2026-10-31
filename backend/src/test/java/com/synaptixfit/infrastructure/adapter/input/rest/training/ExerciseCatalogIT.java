package com.synaptixfit.infrastructure.adapter.input.rest.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.nio.charset.StandardCharsets;
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

    /** V930: nombres del catálogo en el idioma de la petición; sin cabecera, en español. */
    @Test
    void namesFollowTheRequestLanguageAndSearchFindsTranslatedNames() throws Exception {
        String token = register("exercise-names-it@example.com");
        UUID id = jdbc.sql("SELECT e.id FROM ejercicios e JOIN ejercicio_nombres n ON n.ejercicio_id = e.id "
                        + "AND n.idioma = 'en' JOIN ejercicio_musculo_objetivo j ON j.ejercicio_id = e.id "
                        + "JOIN musculos m ON m.id = j.musculo_id AND m.nombre = 'Cuádriceps' "
                        + "WHERE e.activo ORDER BY e.nombre LIMIT 1")
                .query(UUID.class).single();
        String spanish = jdbc.sql("SELECT nombre FROM ejercicios WHERE id = :id").param("id", id)
                .query(String.class).single();
        String english = jdbc.sql("SELECT nombre FROM ejercicio_nombres WHERE ejercicio_id = :id AND idioma = 'en'")
                .param("id", id).query(String.class).single();
        String muscle = jdbc.sql("SELECT nombre FROM vocabulario_nombres WHERE termino = 'Cuádriceps' AND idioma = 'en'")
                .query(String.class).single();

        mvc.perform(get("/api/v1/exercises/" + id).header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value(spanish));
        String response = mvc.perform(get("/api/v1/exercises/" + id).header("Authorization", "Bearer " + token)
                        .header("Accept-Language", "en-GB"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value(english))
                .andReturn().getResponse().getContentAsString();
        List<String> muscles = JsonPath.read(response, "$.targetMuscles[*].name");
        assertThat(muscles).contains(muscle);

        String found = mvc.perform(get("/api/v1/exercises").param("q", english).param("size", "50")
                        .header("Authorization", "Bearer " + token).header("Accept-Language", "en"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        List<String> foundIds = JsonPath.read(found, "$.items[*].id");
        assertThat(foundIds).contains(id.toString());

        // La administración edita el canónico: aunque use la app en inglés, recibe el español (si no,
        // al guardar escribiría la traducción sobre el nombre que usan las reglas de rutinas).
        register("exercise-names-admin-it@example.com");
        jdbc.sql("UPDATE usuarios SET rol = 'admin' WHERE email = 'exercise-names-admin-it@example.com'").update();
        String admin = login("exercise-names-admin-it@example.com");
        mvc.perform(get("/api/v1/admin/exercises/" + id).header("Authorization", "Bearer " + admin)
                        .header("Accept-Language", "en"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value(spanish))
                .andExpect(jsonPath("$.targetMuscles[*].name", hasItem("Cuádriceps")));

        // Un ejercicio nuevo del panel con sus nombres revisados: se ve traducido al momento.
        int quadriceps = jdbc.sql("SELECT id FROM musculos WHERE nombre = 'Cuádriceps'").query(Integer.class).single();
        String created = mvc.perform(post("/api/v1/admin/exercises").header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).characterEncoding(StandardCharsets.UTF_8)
                        .content(exercise("Sentadilla búlgara con kettlebell", quadriceps,
                                ",\"translations\":{\"en\":\"Kettlebell Bulgarian split squat\",\"fr\":\" \","
                                        + "\"pt\":\"Agachamento búlgaro com kettlebell\"}")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Sentadilla búlgara con kettlebell"))
                .andReturn().getResponse().getContentAsString();
        String newId = JsonPath.read(created, "$.id");
        mvc.perform(get("/api/v1/admin/exercises/" + newId + "/names").header("Authorization", "Bearer " + admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.en").value("Kettlebell Bulgarian split squat"))
                .andExpect(jsonPath("$.fr").doesNotExist())
                .andExpect(jsonPath("$.pt").value("Agachamento búlgaro com kettlebell"));
        mvc.perform(get("/api/v1/exercises/" + newId).header("Authorization", "Bearer " + token)
                        .header("Accept-Language", "en"))
                .andExpect(jsonPath("$.name").value("Kettlebell Bulgarian split squat"));
        mvc.perform(get("/api/v1/exercises/" + newId).header("Authorization", "Bearer " + token)
                        .header("Accept-Language", "fr"))
                .andExpect(jsonPath("$.name").value("Sentadilla búlgara con kettlebell"));

        // Editar sin enviar nombres los deja; enviarlos vacíos los quita.
        mvc.perform(put("/api/v1/admin/exercises/" + newId).header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).characterEncoding(StandardCharsets.UTF_8)
                        .content(exercise("Sentadilla búlgara con kettlebell", quadriceps, "")))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/admin/exercises/" + newId + "/names").header("Authorization", "Bearer " + admin))
                .andExpect(jsonPath("$.en").value("Kettlebell Bulgarian split squat"));
        mvc.perform(put("/api/v1/admin/exercises/" + newId).header("Authorization", "Bearer " + admin)
                        .contentType(MediaType.APPLICATION_JSON).characterEncoding(StandardCharsets.UTF_8)
                        .content(exercise("Sentadilla búlgara con kettlebell", quadriceps, ",\"translations\":{}")))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/exercises/" + newId).header("Authorization", "Bearer " + token)
                        .header("Accept-Language", "en"))
                .andExpect(jsonPath("$.name").value("Sentadilla búlgara con kettlebell"));
        mvc.perform(get("/api/v1/admin/exercises/" + UUID.randomUUID() + "/names")
                        .header("Authorization", "Bearer " + admin))
                .andExpect(status().isNotFound());
        // Solo la administración.
        mvc.perform(post("/api/v1/admin/exercises/name-suggestions").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"Plancha\"}"))
                .andExpect(status().isForbidden());
    }

    private static String exercise(String name, int muscle, String extra) {
        return "{\"name\":\"" + name + "\",\"difficulty\":\"INTERMEDIATE\",\"modality\":\"STRENGTH\",\"circuit\":false,\"met\":5.0,\"instructions\":[\"Baja controlando\"],"
                + "\"targetMuscleIds\":[" + muscle + "]" + extra + "}";
    }

    private String login(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private String register(String email) throws Exception {
        String response = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Deportista\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(response, "$.accessToken");
    }
}
