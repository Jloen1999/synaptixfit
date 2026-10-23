package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/** Cambia el nombre y/o el email de un usuario (los nulos no cambian). Auditado. */
public interface UpdateUserIdentityUseCase {

    record Command(UUID adminId, UUID userId, String fullName, String email) {}

    User updateUserIdentity(Command command);
}
