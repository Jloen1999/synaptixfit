package com.synaptixfit.application.service.admin;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.application.service.admin.AdminTestFixtures.RecordingAudit;
import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.AuditEntity;
import com.synaptixfit.domain.model.admin.AuditEntry;
import com.synaptixfit.domain.model.admin.LockdownState;
import com.synaptixfit.domain.port.output.admin.LockdownSettingsPort;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class PlatformLockdownServiceTest {

    private LockdownState stored = new LockdownState(false, null, null, null);
    private int saves;
    private final RecordingAudit audit = new RecordingAudit();
    private final PlatformLockdownService service = new PlatformLockdownService(new LockdownSettingsPort() {
        @Override public LockdownState load() {
            return new LockdownState(stored.active(), stored.startedAt(), stored.startedBy(), stored.updatedAt());
        }
        @Override public void save(LockdownState state) {
            saves++;
            stored = state;
        }
    }, audit, AdminTestFixtures.CLOCK);

    @Test
    void activatingRecordsWhoAndWhenAndAuditsOnce() {
        UUID admin = UUID.randomUUID();

        LockdownState state = service.setLockdown(admin, true);
        service.setLockdown(admin, true);

        assertThat(state.active()).isTrue();
        assertThat(state.startedBy()).isEqualTo(admin);
        assertThat(state.startedAt()).isEqualTo(AdminTestFixtures.NOW);
        assertThat(saves).isEqualTo(1);
        assertThat(audit.entries).singleElement().satisfies(e -> {
            assertThat(e.action()).isEqualTo(AuditAction.ACTIVATE_LOCKDOWN);
            assertThat(e.entity()).isEqualTo(AuditEntity.PLATFORM_SETTINGS);
            assertThat(e.adminId()).isEqualTo(admin);
        });
    }

    @Test
    void deactivatingClearsTheStarter() {
        UUID admin = UUID.randomUUID();
        service.setLockdown(admin, true);

        LockdownState state = service.setLockdown(admin, false);

        assertThat(state.active()).isFalse();
        assertThat(state.startedBy()).isNull();
        assertThat(state.startedAt()).isNull();
        assertThat(service.getLockdown().active()).isFalse();
        assertThat(audit.entries).extracting(AuditEntry::action)
                .containsExactly(AuditAction.ACTIVATE_LOCKDOWN, AuditAction.DEACTIVATE_LOCKDOWN);
    }
}
