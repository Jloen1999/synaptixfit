package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.LockdownState;
import java.util.UUID;

/** Activa o desactiva el modo bloqueo. Idempotente: solo se guarda y audita si cambia. */
public interface SetLockdownUseCase {

    LockdownState setLockdown(UUID adminId, boolean active);
}
