package com.synaptixfit.application.service.admin;

import com.synaptixfit.application.port.input.admin.GetLockdownUseCase;
import com.synaptixfit.application.port.input.admin.SetLockdownUseCase;
import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.AuditEntity;
import com.synaptixfit.domain.model.admin.AuditEntry;
import com.synaptixfit.domain.model.admin.LockdownState;
import com.synaptixfit.domain.port.output.admin.AdminAuditPort;
import com.synaptixfit.domain.port.output.admin.LockdownSettingsPort;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

/**
 * Modo bloqueo de la plataforma. Sustituye al trigger {@code auditar_cambio_config_global}: la
 * auditoría se registra una sola vez aquí (antes se duplicaba entre el trigger y el cliente).
 */
public class PlatformLockdownService implements GetLockdownUseCase, SetLockdownUseCase {

    private final LockdownSettingsPort settings;
    private final AdminAuditPort audit;
    private final Clock clock;

    public PlatformLockdownService(LockdownSettingsPort settings, AdminAuditPort audit, Clock clock) {
        this.settings = settings;
        this.audit = audit;
        this.clock = clock;
    }

    @Override
    public LockdownState getLockdown() {
        return settings.load();
    }

    @Override
    public LockdownState setLockdown(UUID adminId, boolean active) {
        LockdownState state = settings.load();
        boolean before = state.active();
        Instant now = clock.instant();
        if (state.switchTo(active, adminId, now)) {
            settings.save(state);
            audit.record(AuditEntry.of(adminId,
                    active ? AuditAction.ACTIVATE_LOCKDOWN : AuditAction.DEACTIVATE_LOCKDOWN,
                    AuditEntity.PLATFORM_SETTINGS, null, AuditEntry.change("lockdownActive", before, active), now));
        }
        return state;
    }
}
