package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.shared.EffectiveVisibility;
import com.synaptixfit.domain.model.shared.Visibility;

/**
 * Quién puede leer un apunte ajeno (ADR 0064): lo que deja ver su visibilidad efectiva ({@link EffectiveVisibility})
 * o, si su autor se lo pasó con «Compartir › Con un amigo», quien lo recibió mientras sigan siendo amigos y no haya
 * bloqueo ni shadowban. Pasarlo es un acto explícito: vale aunque el apunte o el perfil sean privados.
 */
public final class NoteAccess {

    private NoteAccess() {
    }

    public static boolean canRead(Visibility visibility, AuthorAudience audience, boolean sentToReader) {
        if (EffectiveVisibility.canView(visibility, audience)) {
            return true;
        }
        return sentToReader && audience.friends() && audience.authorActive() && !audience.authorShadowbanned()
                && !audience.blocked();
    }
}
