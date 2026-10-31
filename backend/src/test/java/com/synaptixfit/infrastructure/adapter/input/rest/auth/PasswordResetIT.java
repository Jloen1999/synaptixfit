package com.synaptixfit.infrastructure.adapter.input.rest.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.port.output.auth.PasswordResetMailerPort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Recuperar la contraseña de punta a punta (V970, rutas públicas, errores): el correo se sustituye por un doble
 * que captura el token.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PasswordResetIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private PasswordResetMailerPort mailer;

    @Test
    void theEmailedLinkSetsANewPasswordAndEndsTheOldSessions() throws Exception {
        String email = "reset-" + UUID.randomUUID() + "@example.com";
        String registered = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"vieja1234\",\"fullName\":\"Ana\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String refresh = JsonPath.read(registered, "$.refreshToken");

        mvc.perform(post("/api/v1/auth/password-reset").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email.toUpperCase() + "\"}"))
                .andExpect(status().isAccepted());
        ArgumentCaptor<String> token = ArgumentCaptor.forClass(String.class);
        verify(mailer).sendPasswordReset(eq(email), token.capture(), any(Instant.class));

        mvc.perform(post("/api/v1/auth/password-reset/confirm").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"" + token.getValue() + "\",\"newPassword\":\"nueva1234\"}"))
                .andExpect(status().isNoContent());

        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"nueva1234\"}"))
                .andExpect(status().isOk());
        mvc.perform(post("/api/v1/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + refresh + "\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/auth/password-reset/confirm").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"" + token.getValue() + "\",\"newPassword\":\"otra12345\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("AUTH_RESET_TOKEN_INVALID"));
    }

    /** Dos confirmaciones a la vez del mismo enlace: solo una cambia la contraseña. */
    @Test
    void theSameLinkWorksOnlyOnceEvenWhenUsedTwiceAtTheSameTime() throws Exception {
        String email = "race-" + UUID.randomUUID() + "@example.com";
        mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"vieja1234\",\"fullName\":\"Eva\"}"))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/v1/auth/password-reset").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\"}"))
                .andExpect(status().isAccepted());
        ArgumentCaptor<String> token = ArgumentCaptor.forClass(String.class);
        verify(mailer).sendPasswordReset(eq(email), token.capture(), any(Instant.class));

        Callable<Integer> confirm = () -> mvc.perform(post("/api/v1/auth/password-reset/confirm")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"" + token.getValue() + "\",\"newPassword\":\"nueva1234\"}"))
                .andReturn().getResponse().getStatus();
        try (ExecutorService pool = Executors.newFixedThreadPool(2)) {
            List<Future<Integer>> results = pool.invokeAll(List.of(confirm, confirm));
            List<Integer> statuses = new ArrayList<>();
            for (Future<Integer> r : results) {
                statuses.add(r.get());
            }
            assertThat(statuses).containsExactlyInAnyOrder(204, 400);
        }
    }

    @Test
    void anUnknownEmailGetsTheSameAnswerAndNoEmail() throws Exception {
        mvc.perform(post("/api/v1/auth/password-reset").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"nadie-" + UUID.randomUUID() + "@example.com\"}"))
                .andExpect(status().isAccepted());

        verify(mailer, never()).sendPasswordReset(anyString(), anyString(), any(Instant.class));
    }
}
