package com.synaptixfit.domain.port.output.platform;

/** Configuración global de la plataforma. */
public interface PlatformSettingsPort {

    /** Con el bloqueo activo, las cuentas nuevas nacen ocultas (shadowban). */
    boolean isLockdownActive();
}
