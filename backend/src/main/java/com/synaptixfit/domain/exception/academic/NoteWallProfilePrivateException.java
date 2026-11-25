package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.BusinessRuleException;

/**
 * Con el perfil privado nadie más ve el muro ni el apunte: publicarlo dejaría una publicación que nadie puede abrir
 * (ADR 0064). Se cambia antes la privacidad del perfil.
 */
public class NoteWallProfilePrivateException extends BusinessRuleException {

    public NoteWallProfilePrivateException() {
        super("NOTE_WALL_PROFILE_PRIVATE", "a private profile cannot share a note on the wall");
    }
}
