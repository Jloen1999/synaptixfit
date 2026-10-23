package com.synaptixfit.application.port.input.privacy;

import java.util.UUID;

/**
 * Baja voluntaria: elimina la cuenta del usuario autenticado y todos sus datos. Exige la
 * contraseña si la cuenta tiene una; si solo usa Google, una confirmación explícita.
 */
public interface DeleteMyAccountUseCase {

    record Command(UUID userId, String password, boolean confirmed) {}

    void deleteMyAccount(Command command);
}
