package com.synaptixfit.infrastructure.adapter.input.rest.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.exception.StorageUnavailableException;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Foto de perfil sobre PostgreSQL real (ADR 0052): subir, servir sin sesión solo la foto actual, quitar y los
 * errores con su {@code code}. R2 es un doble: nunca se llama al real.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AvatarFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private FileStoragePort storage;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Ana Pérez\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private static MockMultipartFile photo() throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(new BufferedImage(800, 600, BufferedImage.TYPE_INT_RGB), "jpg", out);
        return new MockMultipartFile("file", "selfie.jpg", "image/jpeg", out.toByteArray());
    }

    @Test
    void aPhotoIsUploadedServedWithoutSessionAndRemoved() throws Exception {
        String token = register("avatar-it@example.com");

        String body = mvc.perform(multipart("/api/v1/me/avatar").file(photo())
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.avatarUrl").isString())
                .andReturn().getResponse().getContentAsString();
        String url = JsonPath.read(body, "$.avatarUrl");
        String userId = JsonPath.read(body, "$.id");
        String path = url.substring(url.indexOf("/api/v1/avatars/"));
        assertThat(path).startsWith("/api/v1/avatars/" + userId + "/").endsWith(".jpg");

        ArgumentCaptor<String> key = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<byte[]> stored = ArgumentCaptor.forClass(byte[].class);
        verify(storage).put(key.capture(), stored.capture(), eq("image/jpeg"));
        assertThat(key.getValue()).startsWith("avatares/" + userId + "/");
        BufferedImage saved = ImageIO.read(new java.io.ByteArrayInputStream(stored.getValue()));
        assertThat(saved.getWidth()).isEqualTo(512);
        assertThat(saved.getHeight()).isEqualTo(512);

        // Se sirve sin sesión, como una imagen normal; solo la foto actual.
        when(storage.download(key.getValue())).thenReturn(stored.getValue());
        mvc.perform(get(path))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_JPEG))
                .andExpect(header().string("Cache-Control", "max-age=86400, public"));
        mvc.perform(get("/api/v1/avatars/" + userId + "/" + UUID.randomUUID() + ".jpg"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("AVATAR_NOT_FOUND"));

        mvc.perform(delete("/api/v1/me/avatar").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.avatarUrl").doesNotExist());
        verify(storage).delete(key.getValue());
        mvc.perform(get(path)).andExpect(status().isNotFound());
    }

    @Test
    void wrongFilesAndAMissingStorageAreExplainedWithTheirCode() throws Exception {
        String token = register("avatar-errors-it@example.com");

        mvc.perform(multipart("/api/v1/me/avatar")
                        .file(new MockMultipartFile("file", "foto.jpg", "image/jpeg", "no soy una foto".getBytes()))
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("AVATAR_INVALID_IMAGE"));

        doThrow(new StorageUnavailableException("File storage is not configured"))
                .when(storage).put(anyString(), any(), anyString());
        mvc.perform(multipart("/api/v1/me/avatar").file(photo()).header("Authorization", "Bearer " + token))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("STORAGE_UNAVAILABLE"));
        mvc.perform(get("/api/v1/me").header("Authorization", "Bearer " + token))
                .andExpect(jsonPath("$.avatarUrl").doesNotExist());
    }
}
