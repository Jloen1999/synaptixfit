package com.synaptixfit.infrastructure.adapter.input.rest.privacy;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.model.privacy.LegalTerms;
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

/**
 * Textos legales (ADR 0034) sobre la aplicación completa: públicos sin sesión en JSON y HTML, «pendiente» sin
 * responsable configurado, y la aceptación de la versión vigente con su registro en {@code aceptaciones_legales}.
 */
@SpringBootTest
@AutoConfigureMockMvc
class LegalFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Test
    void documentsArePublicInJsonAndHtml() throws Exception {
        mvc.perform(get("/api/v1/legal/privacy").param("lang", "en"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.kind").value("privacy"))
                .andExpect(jsonPath("$.language").value("en"))
                .andExpect(jsonPath("$.version").value(LegalTerms.CURRENT_VERSION))
                .andExpect(jsonPath("$.blocks[0].type").exists())
                // Sin LEGAL_CONTROLLER_NAME ni LEGAL_CONTACT_EMAIL en los tests: no se inventa nada.
                .andExpect(jsonPath("$.contactConfigured").value(false));

        mvc.perform(get("/api/v1/legal/account-deletion/page"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(header().string("Content-Security-Policy", containsString("default-src 'none'")))
                .andExpect(header().string("Content-Security-Policy", containsString("frame-ancestors 'none'")))
                .andExpect(content().string(containsString("<h1>Eliminar tu cuenta de SynaptixFit</h1>")))
                .andExpect(content().string(containsString("(pendiente de indicar)")))
                .andExpect(content().string(not(containsString("{{"))));

        mvc.perform(get("/api/v1/legal/cookies"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("LEGAL_DOCUMENT_NOT_FOUND"));

        // La ruta HTML responde con una página 404, nunca con un 500 ni con JSON.
        mvc.perform(get("/api/v1/legal/cookies/page"))
                .andExpect(status().isNotFound())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(containsString("Página no encontrada")));
    }

    @Test
    void registeringWithTheCurrentVersionLeavesTheAcceptanceRecorded() throws Exception {
        String email = "legal-reg-" + UUID.randomUUID() + "@example.com";
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Legal\","
                                + "\"acceptedLegalVersion\":\"" + LegalTerms.CURRENT_VERSION + "\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String token = "Bearer " + JsonPath.read(body, "$.accessToken");

        mvc.perform(get("/api/v1/me/legal-acceptance").header("Authorization", token))
                .andExpect(jsonPath("$.required").value(false))
                .andExpect(jsonPath("$.acceptedVersion").value(LegalTerms.CURRENT_VERSION));
    }

    @Test
    void acceptingTheCurrentVersionIsRecorded() throws Exception {
        String email = "legal-" + UUID.randomUUID() + "@example.com";
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Legal\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String token = "Bearer " + JsonPath.read(body, "$.accessToken");

        mvc.perform(get("/api/v1/me/legal-acceptance").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.required").value(true))
                .andExpect(jsonPath("$.currentVersion").value(LegalTerms.CURRENT_VERSION));

        mvc.perform(put("/api/v1/me/legal-acceptance").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"version\":\"2000-01-01\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LEGAL_VERSION_OUTDATED"));

        for (int i = 0; i < 2; i++) {
            mvc.perform(put("/api/v1/me/legal-acceptance").header("Authorization", token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"version\":\"" + LegalTerms.CURRENT_VERSION + "\"}"))
                    .andExpect(status().isNoContent());
        }

        mvc.perform(get("/api/v1/me/legal-acceptance").header("Authorization", token))
                .andExpect(jsonPath("$.required").value(false))
                .andExpect(jsonPath("$.acceptedVersion").value(LegalTerms.CURRENT_VERSION));

        mvc.perform(put("/api/v1/me/legal-acceptance").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"version\":\"" + LegalTerms.CURRENT_VERSION + "\"}"))
                .andExpect(status().isUnauthorized());
    }
}
