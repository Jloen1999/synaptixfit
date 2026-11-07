package com.synaptixfit.application.service.admin;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.admin.ChangeUserRoleUseCase;
import com.synaptixfit.application.port.input.admin.SetUserProgressUseCase;
import com.synaptixfit.application.port.input.admin.SetUserShadowbanUseCase;
import com.synaptixfit.application.port.input.admin.UpdateUserIdentityUseCase;
import com.synaptixfit.application.service.admin.AdminTestFixtures.FakeErasure;
import com.synaptixfit.application.service.admin.AdminTestFixtures.FakeStorage;
import com.synaptixfit.application.service.admin.AdminTestFixtures.InMemoryUsers;
import com.synaptixfit.application.service.admin.AdminTestFixtures.RecordingAudit;
import com.synaptixfit.application.service.admin.AdminTestFixtures.RecordingEvents;
import com.synaptixfit.application.service.admin.AdminTestFixtures.RecordingTokens;
import com.synaptixfit.application.service.privacy.UserDataEraser;
import com.synaptixfit.domain.event.privacy.UserDataErased;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.admin.AdminCannotTargetSelfException;
import com.synaptixfit.domain.exception.admin.AdminEmailAlreadyInUseException;
import com.synaptixfit.domain.exception.admin.AdminUserDeletedException;
import com.synaptixfit.domain.exception.admin.AdminUserNotFoundException;
import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.AuditEntity;
import com.synaptixfit.domain.model.admin.AuditEntry;
import com.synaptixfit.domain.model.privacy.ErasureMode;
import com.synaptixfit.domain.model.privacy.ErasureReport;
import com.synaptixfit.domain.model.privacy.UserDataExport;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class AdminUserManagementServiceTest {

    private final InMemoryUsers users = new InMemoryUsers();
    private final RecordingAudit audit = new RecordingAudit();
    private final FakeErasure erasure = new FakeErasure();
    private final FakeStorage storage = new FakeStorage();
    private final RecordingTokens tokens = new RecordingTokens();
    private final RecordingEvents events = new RecordingEvents();
    private AdminUserManagementService service;
    private User admin;
    private User target;

    @BeforeEach
    void setUp() {
        erasure.users = users;
        UserDataEraser eraser = new UserDataEraser(erasure, storage, events, AdminTestFixtures.CLOCK);
        service = new AdminUserManagementService(users, tokens, audit, eraser,
                (id, at, requester) -> "{\"userId\":\"" + id + "\",\"requester\":\"" + requester + "\"}",
                AdminTestFixtures.CLOCK);
        admin = users.add(AdminTestFixtures.user("admin@example.com", Role.ADMIN));
        target = users.add(AdminTestFixtures.user("target@example.com", Role.USER));
    }

    @Test
    void renameAndEmailChangeAreAuditedWithBeforeAndAfter() {
        User updated = service.updateUserIdentity(new UpdateUserIdentityUseCase.Command(
                admin.id(), target.id(), "Nombre Nuevo", "New@Example.com"));

        assertThat(updated.fullName()).isEqualTo("Nombre Nuevo");
        assertThat(updated.email()).isEqualTo("new@example.com");
        assertThat(audit.entries).extracting(AuditEntry::action)
                .containsExactly(AuditAction.UPDATE_NAME, AuditAction.UPDATE_EMAIL);
        AuditEntry emailEntry = audit.entries.get(1);
        assertThat(emailEntry.adminId()).isEqualTo(admin.id());
        assertThat(emailEntry.entity()).isEqualTo(AuditEntity.USER);
        assertThat(emailEntry.entityId()).isEqualTo(target.id());
        assertThat(emailEntry.details()).containsEntry("before", Map.of("email", "target@example.com"))
                .containsEntry("after", Map.of("email", "new@example.com"));
        assertThat(emailEntry.createdAt()).isEqualTo(AdminTestFixtures.NOW);
    }

    @Test
    void unchangedIdentityIsNotSavedNorAudited() {
        service.updateUserIdentity(new UpdateUserIdentityUseCase.Command(
                admin.id(), target.id(), target.fullName(), "TARGET@example.com"));
        assertThat(audit.entries).isEmpty();
        assertThat(users.saves).isZero();
    }

    @Test
    void emailOfAnotherAccountIsAConflict() {
        assertThatThrownBy(() -> service.updateUserIdentity(new UpdateUserIdentityUseCase.Command(
                admin.id(), target.id(), null, "admin@example.com")))
                .isInstanceOf(AdminEmailAlreadyInUseException.class)
                .extracting("code").isEqualTo("ADMIN_EMAIL_ALREADY_IN_USE");
        assertThat(audit.entries).isEmpty();
    }

    @Test
    void unknownUserIsNotFound() {
        assertThatThrownBy(() -> service.setUserShadowban(new SetUserShadowbanUseCase.Command(
                admin.id(), UUID.randomUUID(), true)))
                .isInstanceOf(AdminUserNotFoundException.class)
                .extracting("code").isEqualTo("ADMIN_USER_NOT_FOUND");
    }

    @Test
    void progressIsValidatedAgainstTheLevelThreshold() {
        assertThatThrownBy(() -> service.setUserProgress(new SetUserProgressUseCase.Command(
                admin.id(), target.id(), 2, 200)))
                .isInstanceOf(FieldValidationException.class);

        User updated = service.setUserProgress(new SetUserProgressUseCase.Command(admin.id(), target.id(), 5, 0));
        assertThat(updated.level()).isEqualTo(5);
        assertThat(updated.levelXp()).isZero();
        assertThat(audit.entries).singleElement().satisfies(e -> {
            assertThat(e.action()).isEqualTo(AuditAction.SET_PROGRESS);
            assertThat(e.details()).containsEntry("before", Map.of("level", 3, "levelXp", 50));
        });
    }

    @Test
    void adminCannotTargetThemselvesWithDestructiveActions() {
        UUID self = admin.id();
        List<Runnable> actions = List.of(
                () -> service.changeUserRole(new ChangeUserRoleUseCase.Command(self, self, Role.USER)),
                () -> service.setUserShadowban(new SetUserShadowbanUseCase.Command(self, self, true)),
                () -> service.wipeUserData(self, self),
                () -> service.anonymizeUser(self, self),
                () -> service.deleteUser(self, self));
        for (Runnable action : actions) {
            assertThatThrownBy(action::run).isInstanceOf(AdminCannotTargetSelfException.class)
                    .extracting("code").isEqualTo("ADMIN_CANNOT_TARGET_SELF");
        }
        assertThat(audit.entries).isEmpty();
        assertThat(erasure.calls).isEmpty();
        assertThat(users.store.get(self).isAdmin()).isTrue();
    }

    @Test
    void roleChangeAndShadowbanAreAuditedOnlyWhenTheyChange() {
        service.changeUserRole(new ChangeUserRoleUseCase.Command(admin.id(), target.id(), Role.ADMIN));
        service.changeUserRole(new ChangeUserRoleUseCase.Command(admin.id(), target.id(), Role.ADMIN));
        service.setUserShadowban(new SetUserShadowbanUseCase.Command(admin.id(), target.id(), true));
        service.setUserShadowban(new SetUserShadowbanUseCase.Command(admin.id(), target.id(), false));

        assertThat(users.store.get(target.id()).role()).isEqualTo(Role.ADMIN);
        assertThat(audit.entries).extracting(AuditEntry::action).containsExactly(
                AuditAction.CHANGE_ROLE, AuditAction.ACTIVATE_SHADOWBAN, AuditAction.DEACTIVATE_SHADOWBAN);
    }

    @Test
    void wipeErasesContentResetsProgressAndKeepsTheAccount() {
        erasure.keys = List.of("k1", "k2");
        storage.failing.add("k2");
        target.changeBirthDate(java.time.LocalDate.of(2004, 5, 6), java.time.LocalDate.of(2026, 11, 7));

        ErasureReport report = service.wipeUserData(admin.id(), target.id());

        assertThat(report.mode()).isEqualTo(ErasureMode.CONTENT_WIPED);
        assertThat(report.deletedRecords()).isEqualTo(7);
        assertThat(report.storedFiles()).isEqualTo(2);
        assertThat(report.failedFileDeletions()).isEqualTo(1);
        User wiped = users.store.get(target.id());
        assertThat(wiped.isActive()).isTrue();
        assertThat(wiped.level()).isEqualTo(1);
        assertThat(wiped.levelXp()).isZero();
        assertThat(wiped.streak()).isZero();
        assertThat(wiped.birthDate()).isNull();
        assertThat(storage.deleted).containsExactly("k1");
        assertThat(audit.entries).singleElement().extracting(AuditEntry::action)
                .isEqualTo(AuditAction.WIPE_USER_DATA);
        assertThat(events.published).singleElement().isInstanceOf(UserDataErased.class);
    }

    @Test
    void anonymizeScrubsTheAccountRevokesSessionsAndIsIdempotent() {
        ErasureReport report = service.anonymizeUser(admin.id(), target.id());

        User anonymized = users.store.get(target.id());
        assertThat(report.mode()).isEqualTo(ErasureMode.ANONYMIZED);
        assertThat(anonymized.isActive()).isFalse();
        assertThat(anonymized.email()).startsWith("deleted+").doesNotContain("target");
        assertThat(anonymized.hasPassword()).isFalse();
        assertThat(tokens.revokedFor).containsExactly(target.id());
        assertThat(audit.redacted).containsExactly(target.id());
        assertThat(audit.entries).singleElement().satisfies(e -> {
            assertThat(e.action()).isEqualTo(AuditAction.ANONYMIZE_USER);
            assertThat(e.details().toString()).doesNotContain("target@example.com");
        });

        ErasureReport again = service.anonymizeUser(admin.id(), target.id());
        assertThat(again.deletedRecords()).isZero();
        assertThat(erasure.calls).hasSize(1);
        assertThat(audit.entries).hasSize(1);
    }

    @Test
    void anonymizedAccountsRejectEditsButAllowExportAndDelete() {
        service.anonymizeUser(admin.id(), target.id());

        assertThatThrownBy(() -> service.setUserShadowban(new SetUserShadowbanUseCase.Command(
                admin.id(), target.id(), true)))
                .isInstanceOf(AdminUserDeletedException.class);

        UserDataExport export = service.exportUserData(admin.id(), target.id());
        assertThat(export.json()).contains(target.id().toString());
        // La copia que pide un administrador nunca lleva los datos de salud (ADR 0033).
        assertThat(export.json()).contains("ADMINISTRATOR");

        ErasureReport deleted = service.deleteUser(admin.id(), target.id());
        assertThat(deleted.mode()).isEqualTo(ErasureMode.DELETED);
        assertThat(users.store).doesNotContainKey(target.id());
        assertThat(audit.entries).extracting(AuditEntry::action).containsExactly(
                AuditAction.ANONYMIZE_USER, AuditAction.EXPORT_USER_DATA, AuditAction.DELETE_USER);
    }
}
