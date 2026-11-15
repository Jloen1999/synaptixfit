package com.synaptixfit.application.port.input.user;

import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/** Quita la foto de perfil (y borra el archivo si se subió a la app) y devuelve la cuenta (ADR 0052). */
public interface RemoveAvatarUseCase {

    User removeAvatar(UUID userId);
}
