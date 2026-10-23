package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.LockdownState;

/** Estado actual del modo bloqueo. */
public interface GetLockdownUseCase {

    LockdownState getLockdown();
}
