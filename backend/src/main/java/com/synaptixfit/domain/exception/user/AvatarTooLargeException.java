package com.synaptixfit.domain.exception.user;

import com.synaptixfit.domain.exception.InvalidInputException;

/** La foto de perfil pesa más de 10 MB o tiene más de 40 megapíxeles. */
public class AvatarTooLargeException extends InvalidInputException {

    public AvatarTooLargeException() {
        super("AVATAR_TOO_LARGE", "The photo can be up to 10 MB and 40 megapixels");
    }
}
