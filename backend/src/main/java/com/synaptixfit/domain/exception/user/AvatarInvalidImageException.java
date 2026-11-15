package com.synaptixfit.domain.exception.user;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La foto de perfil no es una imagen JPG, PNG o WEBP que se pueda abrir. */
public class AvatarInvalidImageException extends InvalidInputException {

    public AvatarInvalidImageException() {
        super("AVATAR_INVALID_IMAGE", "Send one JPG, PNG or WEBP photo");
    }
}
