package com.synaptixfit.application.service.admin;

import com.synaptixfit.application.port.input.admin.AnonymizeUserUseCase;
import com.synaptixfit.application.port.input.admin.ChangeUserRoleUseCase;
import com.synaptixfit.application.port.input.admin.DeleteUserUseCase;
import com.synaptixfit.application.port.input.admin.ExportUserDataUseCase;
import com.synaptixfit.application.port.input.admin.SetUserProgressUseCase;
import com.synaptixfit.application.port.input.admin.SetUserShadowbanUseCase;
import com.synaptixfit.application.port.input.admin.UpdateUserIdentityUseCase;
import com.synaptixfit.application.port.input.admin.WipeUserDataUseCase;
import com.synaptixfit.application.service.privacy.UserDataEraser;
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
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.admin.AdminAuditPort;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.privacy.UserDataExportPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Acciones del panel sobre un usuario. Cada cambio efectivo queda en la auditoría con el
 * antes/después; las peticiones que no cambian nada no se auditan.
 *
 * <p>Reglas: un administrador no puede cambiar su propio rol, ocultarse, vaciar sus datos,
 * anonimizarse ni eliminarse desde el panel. Una cuenta anonimizada solo admite exportar y
 * eliminar (anonimizarla de nuevo no hace nada).
 */
public class AdminUserManagementService implements UpdateUserIdentityUseCase, SetUserProgressUseCase,
        ChangeUserRoleUseCase, SetUserShadowbanUseCase, WipeUserDataUseCase, AnonymizeUserUseCase,
        DeleteUserUseCase, ExportUserDataUseCase {

    /** Nivel máximo asignable a mano (evita valores absurdos en la progresión). */
    public static final int MAX_LEVEL = 1000;

    private final UserRepositoryPort users;
    private final RefreshTokenRepositoryPort refreshTokens;
    private final AdminAuditPort audit;
    private final UserDataEraser eraser;
    private final UserDataExportPort exporter;
    private final Clock clock;

    public AdminUserManagementService(UserRepositoryPort users, RefreshTokenRepositoryPort refreshTokens,
                                      AdminAuditPort audit, UserDataEraser eraser, UserDataExportPort exporter,
                                      Clock clock) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.audit = audit;
        this.eraser = eraser;
        this.exporter = exporter;
        this.clock = clock;
    }

    @Override
    public User updateUserIdentity(UpdateUserIdentityUseCase.Command command) {
        User user = activeTarget(command.userId());
        boolean changed = false;
        if (command.fullName() != null && !command.fullName().strip().equals(user.fullName())) {
            String before = user.fullName();
            user.rename(command.fullName());
            record(command.adminId(), AuditAction.UPDATE_NAME, user.id(),
                    AuditEntry.change("fullName", before, user.fullName()));
            changed = true;
        }
        if (command.email() != null) {
            String email = User.normalizeEmail(command.email());
            if (!email.equals(user.email())) {
                if (users.existsByEmail(email)) {
                    throw new AdminEmailAlreadyInUseException();
                }
                String before = user.email();
                user.changeEmail(email);
                record(command.adminId(), AuditAction.UPDATE_EMAIL, user.id(),
                        AuditEntry.change("email", before, user.email()));
                changed = true;
            }
        }
        return changed ? users.save(user) : user;
    }

    @Override
    public User setUserProgress(SetUserProgressUseCase.Command command) {
        User user = activeTarget(command.userId());
        Guard.range(command.level(), "level", 1, MAX_LEVEL);
        Guard.range(command.levelXp(), "levelXp", 0, User.thresholdFor(command.level()) - 1);
        if (user.level() == command.level() && user.levelXp() == command.levelXp()) {
            return user;
        }
        Map<String, Object> before = progress(user.level(), user.levelXp());
        user.resetProgress(command.level(), command.levelXp());
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("before", before);
        details.put("after", progress(user.level(), user.levelXp()));
        record(command.adminId(), AuditAction.SET_PROGRESS, user.id(), details);
        return users.save(user);
    }

    @Override
    public User changeUserRole(ChangeUserRoleUseCase.Command command) {
        requireNotSelf(command.adminId(), command.userId());
        User user = activeTarget(command.userId());
        Role role = Guard.notNull(command.role(), "role");
        if (user.role() == role) {
            return user;
        }
        Role before = user.role();
        user.changeRole(role);
        record(command.adminId(), AuditAction.CHANGE_ROLE, user.id(),
                AuditEntry.change("role", before.name(), role.name()));
        return users.save(user);
    }

    @Override
    public User setUserShadowban(SetUserShadowbanUseCase.Command command) {
        requireNotSelf(command.adminId(), command.userId());
        User user = activeTarget(command.userId());
        if (user.shadowbanned() == command.shadowbanned()) {
            return user;
        }
        user.setShadowbanned(command.shadowbanned());
        record(command.adminId(),
                command.shadowbanned() ? AuditAction.ACTIVATE_SHADOWBAN : AuditAction.DEACTIVATE_SHADOWBAN,
                user.id(), AuditEntry.change("shadowbanned", !command.shadowbanned(), command.shadowbanned()));
        return users.save(user);
    }

    @Override
    public ErasureReport wipeUserData(UUID adminId, UUID userId) {
        requireNotSelf(adminId, userId);
        User user = activeTarget(userId);
        Map<String, Object> before = progress(user.level(), user.levelXp());
        before.put("streak", user.streak());
        ErasureReport report = eraser.wipeContent(user.id());
        user.resetProgress(1, 0);
        user.updateStreak(0);
        users.save(user);
        Map<String, Object> details = reportDetails(report);
        details.put("before", before);
        record(adminId, AuditAction.WIPE_USER_DATA, user.id(), details);
        return report;
    }

    @Override
    public ErasureReport anonymizeUser(UUID adminId, UUID userId) {
        requireNotSelf(adminId, userId);
        User user = target(userId);
        if (!user.isActive()) {
            return new ErasureReport(userId, ErasureMode.ANONYMIZED, 0, 0, 0);
        }
        Instant now = clock.instant();
        ErasureReport report = eraser.erasePersonalData(user.id());
        user.anonymize(now);
        user.changeRole(Role.USER);
        users.save(user);
        refreshTokens.revokeAllForUser(user.id(), now);
        audit.redactDetailsForEntity(user.id());
        record(adminId, AuditAction.ANONYMIZE_USER, user.id(), reportDetails(report));
        return report;
    }

    @Override
    public ErasureReport deleteUser(UUID adminId, UUID userId) {
        requireNotSelf(adminId, userId);
        User user = target(userId);
        ErasureReport report = eraser.deleteAccount(user.id());
        audit.redactDetailsForEntity(user.id());
        record(adminId, AuditAction.DELETE_USER, user.id(), reportDetails(report));
        return report;
    }

    @Override
    public UserDataExport exportUserData(UUID adminId, UUID userId) {
        User user = target(userId);
        Instant now = clock.instant();
        UserDataExport export = new UserDataExport(user.id(), now, exporter.exportAsJson(user.id(), now,
                UserDataExportPort.Requester.ADMINISTRATOR));
        record(adminId, AuditAction.EXPORT_USER_DATA, user.id(), Map.of());
        return export;
    }

    private User target(UUID userId) {
        return users.findById(userId).orElseThrow(() -> new AdminUserNotFoundException(userId));
    }

    private User activeTarget(UUID userId) {
        User user = target(userId);
        if (!user.isActive()) {
            throw new AdminUserDeletedException();
        }
        return user;
    }

    private static void requireNotSelf(UUID adminId, UUID userId) {
        if (adminId != null && adminId.equals(userId)) {
            throw new AdminCannotTargetSelfException();
        }
    }

    private void record(UUID adminId, AuditAction action, UUID userId, Map<String, Object> details) {
        audit.record(AuditEntry.of(adminId, action, AuditEntity.USER, userId, details, clock.instant()));
    }

    private static Map<String, Object> progress(int level, int levelXp) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("level", level);
        map.put("levelXp", levelXp);
        return map;
    }

    private static Map<String, Object> reportDetails(ErasureReport report) {
        Map<String, Object> details = new LinkedHashMap<>();
        details.put("deletedRecords", report.deletedRecords());
        details.put("storedFiles", report.storedFiles());
        details.put("failedFileDeletions", report.failedFileDeletions());
        return details;
    }
}
