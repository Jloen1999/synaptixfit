package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/** Oculta o deja de ocultar el contenido de otro usuario (shadowban). Auditado. */
public interface SetUserShadowbanUseCase {

    record Command(UUID adminId, UUID userId, boolean shadowbanned) {}

    User setUserShadowban(Command command);
}
