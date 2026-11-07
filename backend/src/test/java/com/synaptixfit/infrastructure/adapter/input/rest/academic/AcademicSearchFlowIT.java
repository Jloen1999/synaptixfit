package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
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
 * Buscador único de Académico y aula de la asignatura (ADR 0036) sobre PostgreSQL real: agrupa por tipo, no distingue
 * tildes ni mayúsculas y solo ve lo propio.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AcademicSearchFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Buscador\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private static MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder b, String token) {
        return b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON);
    }

    @Test
    void findsSubjectsAndNotesIgnoringAccentsAndOnlyOwnData() throws Exception {
        String token = register("search-it@example.com");
        String other = register("search-other-it@example.com");
        String subject = mvc.perform(auth(post("/api/v1/subjects"), token).content(
                        "{\"name\":\"Física Cuántica\",\"code\":\"FQ\",\"teacher\":\"Marta Ruiz\",\"room\":\"Aula 2.3\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.room").value("Aula 2.3"))
                .andReturn().getResponse().getContentAsString();
        String subjectId = JsonPath.read(subject, "$.id");
        mvc.perform(auth(post("/api/v1/notes"), token)
                        .content("{\"subjectId\":\"" + subjectId + "\",\"title\":\"Resumen tema 1\","
                                + "\"content\":\"La ecuación de Schrödinger en física\"}"))
                .andExpect(status().isCreated());
        mvc.perform(auth(post("/api/v1/subjects"), other).content("{\"name\":\"Física de otro\"}"))
                .andExpect(status().isCreated());

        mvc.perform(auth(get("/api/v1/academic/search").param("q", "FISICA"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.groups", hasSize(2)))
                .andExpect(jsonPath("$.groups[0].kind").value("SUBJECT"))
                .andExpect(jsonPath("$.groups[0].hits", hasSize(1)))
                .andExpect(jsonPath("$.groups[0].hits[0].title").value("Física Cuántica"))
                .andExpect(jsonPath("$.groups[1].kind").value("NOTE"))
                .andExpect(jsonPath("$.groups[1].hits[0].context").value("Física Cuántica"));

        mvc.perform(auth(get("/api/v1/academic/search").param("q", "marta"), token))
                .andExpect(jsonPath("$.groups[0].kind").value("SUBJECT"));
        mvc.perform(auth(get("/api/v1/academic/search").param("q", "zzz"), token))
                .andExpect(jsonPath("$.groups", hasSize(0)));
        mvc.perform(auth(get("/api/v1/academic/search").param("q", "f"), token))
                .andExpect(status().isBadRequest());
    }
}
