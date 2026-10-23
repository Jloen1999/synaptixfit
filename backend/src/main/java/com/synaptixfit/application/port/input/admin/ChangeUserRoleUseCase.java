package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/** Cambia el rol de otro usuario. Auditado. */
public interface ChangeUserRoleUseCase {

    record Command(UUID adminId, UUID userId, Role role) {}

    User changeUserRole(Command command);
}
