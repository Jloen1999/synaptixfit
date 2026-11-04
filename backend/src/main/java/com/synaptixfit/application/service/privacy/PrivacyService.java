package com.synaptixfit.application.service.privacy;

import com.synaptixfit.application.port.input.privacy.DeleteMyAccountUseCase;
import com.synaptixfit.application.port.input.privacy.ExportMyDataUseCase;
import com.synaptixfit.domain.exception.privacy.GdprConfirmationRequiredException;
import com.synaptixfit.domain.exception.privacy.GdprLastAdminException;
import com.synaptixfit.domain.exception.privacy.GdprPasswordMismatchException;
import com.synaptixfit.domain.exception.user.UserNotFoundException;
import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.AuditEntity;
import com.synaptixfit.domain.model.admin.AuditEntry;
import com.synaptixfit.domain.model.privacy.ErasureReport;
import com.synaptixfit.domain.model.privacy.UserDataExport;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.admin.AdminAuditPort;
import com.synaptixfit.domain.port.output.admin.AdminUserQueryPort;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import com.synaptixfit.domain.port.output.privacy.UserDataExportPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/** Autoservicio RGPD del usuario autenticado: exportar sus datos y darse de baja. */
public class PrivacyService implements ExportMyDataUseCase, DeleteMyAccountUseCase {

    private final UserRepositoryPort users;
    private final PasswordHasherPort passwordHasher;
    private final AdminUserQueryPort userQueries;
    private final UserDataEraser eraser;
    private final UserDataExportPort exporter;
    private final AdminAuditPort audit;
    private final Clock clock;

    public PrivacyService(UserRepositoryPort users, PasswordHasherPort passwordHasher,
                          AdminUserQueryPort userQueries, UserDataEraser eraser, UserDataExportPort exporter,
                          AdminAuditPort audit, Clock clock) {
        this.users = users;
        this.passwordHasher = passwordHasher;
        this.userQueries = userQueries;
        this.eraser = eraser;
        this.exporter = exporter;
        this.audit = audit;
        this.clock = clock;
    }

    @Override
    public UserDataExport exportMyData(UUID userId) {
        User user = activeUser(userId);
        Instant now = clock.instant();
        return new UserDataExport(user.id(), now, exporter.exportAsJson(user.id(), now,
                UserDataExportPort.Requester.OWNER));
    }

    @Override
    public void deleteMyAccount(Command command) {
        User user = activeUser(command.userId());
        if (user.hasPassword()) {
            if (command.password() == null || command.password().isBlank()) {
                throw new GdprConfirmationRequiredException("password is required to delete the account");
            }
            if (!passwordHasher.matches(command.password(), user.passwordHash())) {
                throw new GdprPasswordMismatchException();
            }
        } else if (!command.confirmed()) {
            throw new GdprConfirmationRequiredException("explicit confirmation is required to delete the account");
        }
        if (user.isAdmin() && userQueries.countActiveAdmins() <= 1) {
            throw new GdprLastAdminException();
        }
        ErasureReport report = eraser.deleteAccount(user.id());
        audit.redactDetailsForEntity(user.id());
        // La traza de la baja no guarda datos personales: solo qué se borró.
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("deletedRecords", report.deletedRecords());
        details.put("storedFiles", report.storedFiles());
        details.put("failedFileDeletions", report.failedFileDeletions());
        audit.record(AuditEntry.of(null, AuditAction.SELF_DELETE_ACCOUNT, AuditEntity.USER, user.id(), details,
                clock.instant()));
    }

    private User activeUser(UUID userId) {
        return users.findById(userId)
                .filter(User::isActive)
                .orElseThrow(() -> new UserNotFoundException(userId));
    }
}
