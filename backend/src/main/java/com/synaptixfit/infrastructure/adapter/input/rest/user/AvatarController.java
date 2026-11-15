package com.synaptixfit.infrastructure.adapter.input.rest.user;

import com.synaptixfit.application.port.input.user.ReadAvatarUseCase;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Duration;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Sirve la foto de perfil subida a la app (ruta pública en {@code SecurityConfig}: la pintan las listas de amigos
 * y la comunidad con una imagen normal, sin cabecera de sesión). El archivo es privado en R2 y pasa por aquí,
 * por el dominio de la app (ADR 0024 y 0052).
 */
@Tag(name = "Account")
@RestController
@RequestMapping("/api/v1/avatars")
public class AvatarController {

    /**
     * Cada foto tiene un nombre nuevo, así que su contenido no cambia; un día de caché (Cloudflare y el móvil)
     * basta y, si se quita la foto, deja de verse como mucho al día siguiente.
     */
    static final Duration CACHE = Duration.ofDays(1);

    private final ReadAvatarUseCase readAvatar;

    public AvatarController(ReadAvatarUseCase readAvatar) {
        this.readAvatar = readAvatar;
    }

    @GetMapping("/{userId}/{fileName}")
    public ResponseEntity<byte[]> avatar(@PathVariable UUID userId, @PathVariable String fileName) {
        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_JPEG)
                .cacheControl(CacheControl.maxAge(CACHE).cachePublic())
                .header("X-Content-Type-Options", "nosniff")
                .body(readAvatar.readAvatar(userId, fileName));
    }
}
