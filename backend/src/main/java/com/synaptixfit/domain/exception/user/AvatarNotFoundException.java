package com.synaptixfit.domain.exception.user;

import com.synaptixfit.domain.exception.NotFoundException;

/** La foto pedida no es la foto de perfil actual de esa cuenta (o la cuenta ya no existe). */
public class AvatarNotFoundException extends NotFoundException {

    public AvatarNotFoundException() {
        super("AVATAR_NOT_FOUND", "Profile photo not found");
    }
}
