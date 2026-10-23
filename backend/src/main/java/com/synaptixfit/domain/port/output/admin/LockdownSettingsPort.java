package com.synaptixfit.domain.port.output.admin;

import com.synaptixfit.domain.model.admin.LockdownState;

/** Lectura y escritura del modo bloqueo en la configuración global. */
public interface LockdownSettingsPort {

    LockdownState load();

    void save(LockdownState state);
}
