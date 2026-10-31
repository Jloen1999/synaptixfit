package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.head;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
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
 * Suscripción al calendario de punta a punta: el enlace privado se lee sin sesión, trae los bloques del usuario
 * y deja de funcionar al revocarlo (404 con su {@code code}).
 */
@SpringBootTest
@AutoConfigureMockMvc
class CalendarFeedIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String token;

    @BeforeEach
    void register() throws Exception {
        String email = "feed-" + UUID.randomUUID() + "@example.com";
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Feed\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        token = JsonPath.read(body, "$.accessToken");
    }

    private MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder request) {
        return request.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON);
    }

    @Test
    void thePrivateLinkServesTheCalendarWithoutLoginUntilRevoked() throws Exception {
        Instant tomorrow = Instant.now().truncatedTo(ChronoUnit.DAYS).plus(Duration.ofDays(1)).plus(Duration.ofHours(9));
        mvc.perform(auth(post("/api/v1/planner/blocks")).content("""
                        {"start":"%s","end":"%s","type":"STUDY","topics":"Repaso de matrices"}
                        """.formatted(tomorrow, tomorrow.plus(Duration.ofHours(1)))))
                .andExpect(status().isCreated());

        mvc.perform(auth(get("/api/v1/planner/calendar-feed")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(false));
        String created = mvc.perform(auth(post("/api/v1/planner/calendar-feed")))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String feed = JsonPath.read(created, "$.token");

        // Sin cabecera de autorización: así lo piden los calendarios externos.
        mvc.perform(get("/api/v1/planner/calendar-feed/" + feed + ".ics"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("text/calendar"))
                .andExpect(content().string(containsString("BEGIN:VCALENDAR")))
                .andExpect(content().string(containsString("Repaso de matrices")))
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(header().string("X-Robots-Tag", containsString("noindex")));
        mvc.perform(auth(get("/api/v1/planner/calendar-feed")))
                .andExpect(jsonPath("$.active").value(true));

        mvc.perform(auth(delete("/api/v1/planner/calendar-feed"))).andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/planner/calendar-feed/" + feed + ".ics"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("PLANNER_CALENDAR_FEED_NOT_FOUND"));
    }

    /** Solo el GET/HEAD de {@code /<token>.ics} es público; el resto del planificador sigue pidiendo sesión. */
    @Test
    void onlyTheFeedItselfIsPublic() throws Exception {
        mvc.perform(get("/api/v1/planner/calendar-feed")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/planner/calendar-feed")).andExpect(status().isUnauthorized());
        mvc.perform(delete("/api/v1/planner/calendar-feed")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/planner/calendar-feed/whatever")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/planner/deadlines")).andExpect(status().isUnauthorized());
        mvc.perform(head("/api/v1/planner/calendar-feed/unknown.ics")).andExpect(status().isNotFound());
    }
}
