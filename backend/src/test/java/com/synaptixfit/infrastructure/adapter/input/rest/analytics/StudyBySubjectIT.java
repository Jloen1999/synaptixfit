package com.synaptixfit.infrastructure.adapter.input.rest.analytics;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/** Las consultas de la analítica por asignatura se ejecutan sobre PostgreSQL y respetan el rango de semanas. */
@SpringBootTest
@AutoConfigureMockMvc
class StudyBySubjectIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Test
    void anEmptyAccountGetsTheWeeksWithoutSubjects() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"subj-" + UUID.randomUUID()
                                + "@example.com\",\"password\":\"secret123\",\"fullName\":\"Ana\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String auth = "Bearer " + JsonPath.read(body, "$.accessToken");

        mvc.perform(get("/api/v1/analytics/study-subjects").header("Authorization", auth))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.weeks").value(4))
                .andExpect(jsonPath("$.subjects").isArray());
        mvc.perform(get("/api/v1/analytics/study-subjects").param("weeks", "40").header("Authorization", auth))
                .andExpect(status().isBadRequest());
    }
}
