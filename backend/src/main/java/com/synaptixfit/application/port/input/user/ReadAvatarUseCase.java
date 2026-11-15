package com.synaptixfit.application.port.input.user;

import java.util.UUID;

/**
 * Lee la foto de perfil actual de una cuenta para servirla (sin sesión: la ven los amigos y la comunidad, como
 * el nombre). Una foto anterior o borrada ya no se sirve (ADR 0052).
 */
public interface ReadAvatarUseCase {

    /** JPEG de la foto; {@code fileName} es {@code <foto>.jpg}. */
    byte[] readAvatar(UUID userId, String fileName);
}
