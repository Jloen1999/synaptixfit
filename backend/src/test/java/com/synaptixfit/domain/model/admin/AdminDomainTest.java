package com.synaptixfit.domain.model.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.admin.AdminInvalidDateRangeException;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AdminDomainTest {

    private static final Instant T0 = Instant.parse("2026-10-01T00:00:00Z");

    @Test
    void lockdownSwitchIsIdempotentAndTracksTheStarter() {
        LockdownState state = new LockdownState(false, null, null, null);
        UUID admin = UUID.randomUUID();

        assertThat(state.switchTo(true, admin, T0)).isTrue();
        assertThat(state.switchTo(true, UUID.randomUUID(), T0.plusSeconds(5))).isFalse();
        assertThat(state.startedBy()).isEqualTo(admin);
        assertThat(state.startedAt()).isEqualTo(T0);

        assertThat(state.switchTo(false, admin, T0.plusSeconds(10))).isTrue();
        assertThat(state.startedBy()).isNull();
        assertThat(state.updatedAt()).isEqualTo(T0.plusSeconds(10));
    }

    @Test
    void totalXpAddsTheCompletedLevelThresholds() {
        assertThat(Progression.totalXp(1, 40)).isEqualTo(40);
        // Nivel 3 = 100 (nivel 1) + 200 (nivel 2) + experiencia actual.
        assertThat(Progression.totalXp(3, 50)).isEqualTo(350);
    }

    @Test
    void searchCriteriaHasDefaultsAndValidatesLevels() {
        UserSearchCriteria criteria = new UserSearchCriteria("  ana  ", null, null, null, null, null, null, null);
        assertThat(criteria.text()).isEqualTo("ana");
        assertThat(criteria.status()).isEqualTo(UserSearchCriteria.Status.ACTIVE);
        assertThat(criteria.sort()).isEqualTo(UserSearchCriteria.SortField.CREATED_AT);
        assertThat(criteria.direction()).isEqualTo(UserSearchCriteria.SortDirection.DESC);
        assertThatThrownBy(() -> new UserSearchCriteria(null, null, null, null, 5, 2, null, null))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void auditQueryRejectsInvertedRanges() {
        assertThatThrownBy(() -> new AuditQuery(null, null, null, null, T0, T0))
                .isInstanceOf(AdminInvalidDateRangeException.class)
                .extracting("code").isEqualTo("ADMIN_INVALID_DATE_RANGE");
    }

    @Test
    void unknownAuditCodesMapToOther() {
        assertThat(AuditAction.fromCode("wipe")).isEqualTo(AuditAction.WIPE_USER_DATA);
        assertThat(AuditAction.fromCode("moderar")).isEqualTo(AuditAction.OTHER);
        assertThat(AuditEntity.fromCode("usuarios")).isEqualTo(AuditEntity.USER);
    }
}
