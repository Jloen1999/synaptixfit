package com.synaptixfit.domain.exception.admin;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El usuario gestionado desde el panel no existe. */
public class AdminUserNotFoundException extends ResourceNotFoundException {

    public AdminUserNotFoundException(UUID id) {
        super("ADMIN_USER_NOT_FOUND", "User", id);
    }
}
