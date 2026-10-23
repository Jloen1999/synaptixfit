package com.synaptixfit.application.port.input.user;

import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/** Devuelve la cuenta del usuario autenticado. */
public interface GetCurrentUserUseCase {

    User getCurrentUser(UUID userId);
}
