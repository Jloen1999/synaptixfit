package com.synaptixfit.infrastructure.adapter.input.rest.profile;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
 * Fallo 12 y ADR 0036 sobre PostgreSQL real: el formulario completo de la cuenta se guarda de una vez, la fecha de
 * nacimiento se valida, sale en /me pero no en el perfil público, y el perfil físico ya no exige la edad.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AccountBirthDateFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Ana Pérez\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private static MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder b, String token) {
        return b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON);
    }

    @Test
    void theWholeAccountFormIsSavedAndTheBirthDateStaysPrivate() throws Exception {
        String token = register("birth-it@example.com");

        // Lo mismo que manda la app al pulsar «Guardar» en Editar cuenta.
        mvc.perform(auth(patch("/api/v1/me"), token).content("""
                        {"fullName":"Ana López","avatarUrl":"","privacy":"PUBLIC","usageFocus":"ACADEMIC",
                         "birthDate":"2004-05-06"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Ana López"))
                .andExpect(jsonPath("$.usageFocus").value("ACADEMIC"))
                .andExpect(jsonPath("$.privacy").value("PUBLIC"))
                .andExpect(jsonPath("$.birthDate").value("2004-05-06"));
        String me = mvc.perform(auth(get("/api/v1/me"), token))
                .andExpect(jsonPath("$.usageFocus").value("ACADEMIC"))
                .andExpect(jsonPath("$.birthDate").value("2004-05-06"))
                .andReturn().getResponse().getContentAsString();
        String id = JsonPath.read(me, "$.id");

        mvc.perform(auth(get(PUBLIC_PROFILE + id), token))
                .andExpect(jsonPath("$.birthDate").doesNotExist())
                .andExpect(jsonPath("$.age").doesNotExist());

        mvc.perform(auth(patch("/api/v1/me"), token).content("{\"birthDate\":\"2099-01-01\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_BIRTH_DATE"));

        mvc.perform(auth(patch("/api/v1/me"), token).content("{\"removeBirthDate\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.birthDate").doesNotExist());
    }

    @Test
    void theWellnessProfileNoLongerNeedsTheAge() throws Exception {
        String token = register("birth-wellness-it@example.com");

        mvc.perform(auth(put("/api/v1/profile/wellness"), token).content("""
                        {"sex":"FEMALE","weightKg":60,"heightCm":165,"primaryGoal":"HYPERTROPHY"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.age").doesNotExist());
    }

    private static final String PUBLIC_PROFILE = "/api/v1/social/users/";
}
