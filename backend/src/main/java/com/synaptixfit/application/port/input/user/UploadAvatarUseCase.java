package com.synaptixfit.application.port.input.user;

import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/** Cambia la foto de perfil por una subida desde el móvil (galería o cámara) y devuelve la cuenta (ADR 0052). */
public interface UploadAvatarUseCase {

    record Command(UUID userId, byte[] content) {
    }

    User uploadAvatar(Command command);
}
