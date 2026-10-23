package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.admin.AnonymizeUserUseCase;
import com.synaptixfit.application.port.input.admin.ChangeUserRoleUseCase;
import com.synaptixfit.application.port.input.admin.DeleteUserUseCase;
import com.synaptixfit.application.port.input.admin.ExportUserDataUseCase;
import com.synaptixfit.application.port.input.admin.GetActivityTrendUseCase;
import com.synaptixfit.application.port.input.admin.GetLockdownUseCase;
import com.synaptixfit.application.port.input.admin.GetPlatformMetricsUseCase;
import com.synaptixfit.application.port.input.admin.GetUserDetailUseCase;
import com.synaptixfit.application.port.input.admin.GetUserStatsUseCase;
import com.synaptixfit.application.port.input.admin.GetUserTimelineUseCase;
import com.synaptixfit.application.port.input.admin.GetUserWeeklyActivityUseCase;
import com.synaptixfit.application.port.input.admin.RecordAdminAuditUseCase;
import com.synaptixfit.application.port.input.admin.SearchAuditLogUseCase;
import com.synaptixfit.application.port.input.admin.SearchUsersUseCase;
import com.synaptixfit.application.port.input.admin.SetLockdownUseCase;
import com.synaptixfit.application.port.input.admin.SetUserProgressUseCase;
import com.synaptixfit.application.port.input.admin.SetUserShadowbanUseCase;
import com.synaptixfit.application.port.input.admin.UpdateUserIdentityUseCase;
import com.synaptixfit.application.port.input.admin.WipeUserDataUseCase;
import com.synaptixfit.application.service.admin.AdminAuditService;
import com.synaptixfit.application.service.admin.AdminMetricsService;
import com.synaptixfit.application.service.admin.AdminUserManagementService;
import com.synaptixfit.application.service.admin.AdminUserQueryService;
import com.synaptixfit.application.service.admin.PlatformLockdownService;
import com.synaptixfit.application.service.privacy.UserDataEraser;
import com.synaptixfit.domain.port.output.admin.AdminAuditPort;
import com.synaptixfit.domain.port.output.admin.AdminUserQueryPort;
import com.synaptixfit.domain.port.output.admin.LockdownSettingsPort;
import com.synaptixfit.domain.port.output.admin.PlatformMetricsQueryPort;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.domain.port.output.privacy.UserDataExportPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Raíz de composición del panel de administración (patrón de {@link BeanConfiguration}). */
@Configuration
public class AdminBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final UserRepositoryPort users;
    private final RefreshTokenRepositoryPort refreshTokens;
    private final AdminAuditPort audit;
    private final AdminUserQueryPort userQueries;
    private final PlatformMetricsQueryPort metrics;
    private final LockdownSettingsPort lockdown;
    private final UserDataExportPort exporter;
    private final UserDataEraser eraser;
    private final Clock clock;

    public AdminBeanConfiguration(TransactionalUseCaseFactory tx, UserRepositoryPort users,
                                  RefreshTokenRepositoryPort refreshTokens, AdminAuditPort audit,
                                  AdminUserQueryPort userQueries, PlatformMetricsQueryPort metrics,
                                  LockdownSettingsPort lockdown, UserDataExportPort exporter, UserDataEraser eraser,
                                  Clock clock) {
        this.tx = tx;
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.audit = audit;
        this.userQueries = userQueries;
        this.metrics = metrics;
        this.lockdown = lockdown;
        this.exporter = exporter;
        this.eraser = eraser;
        this.clock = clock;
    }

    // ---------------------------------------------------------------- indicadores

    @Bean(autowireCandidate = false)
    AdminMetricsService adminMetricsService() {
        return new AdminMetricsService(metrics, clock);
    }

    @Bean
    GetPlatformMetricsUseCase getPlatformMetricsUseCase() {
        return tx.wrap(GetPlatformMetricsUseCase.class, adminMetricsService());
    }

    @Bean
    GetActivityTrendUseCase getActivityTrendUseCase() {
        return tx.wrap(GetActivityTrendUseCase.class, adminMetricsService());
    }

    // ---------------------------------------------------------------- consultas de usuarios

    @Bean(autowireCandidate = false)
    AdminUserQueryService adminUserQueryService() {
        return new AdminUserQueryService(users, userQueries, clock);
    }

    @Bean
    SearchUsersUseCase searchUsersUseCase() {
        return tx.wrap(SearchUsersUseCase.class, adminUserQueryService());
    }

    @Bean
    GetUserDetailUseCase getUserDetailUseCase() {
        return tx.wrap(GetUserDetailUseCase.class, adminUserQueryService());
    }

    @Bean
    GetUserStatsUseCase getUserStatsUseCase() {
        return tx.wrap(GetUserStatsUseCase.class, adminUserQueryService());
    }

    @Bean
    GetUserWeeklyActivityUseCase getUserWeeklyActivityUseCase() {
        return tx.wrap(GetUserWeeklyActivityUseCase.class, adminUserQueryService());
    }

    @Bean
    GetUserTimelineUseCase getUserTimelineUseCase() {
        return tx.wrap(GetUserTimelineUseCase.class, adminUserQueryService());
    }

    // ---------------------------------------------------------------- acciones sobre usuarios

    @Bean(autowireCandidate = false)
    AdminUserManagementService adminUserManagementService() {
        return new AdminUserManagementService(users, refreshTokens, audit, eraser, exporter, clock);
    }

    @Bean
    UpdateUserIdentityUseCase updateUserIdentityUseCase() {
        return tx.wrap(UpdateUserIdentityUseCase.class, adminUserManagementService());
    }

    @Bean
    SetUserProgressUseCase setUserProgressUseCase() {
        return tx.wrap(SetUserProgressUseCase.class, adminUserManagementService());
    }

    @Bean
    ChangeUserRoleUseCase changeUserRoleUseCase() {
        return tx.wrap(ChangeUserRoleUseCase.class, adminUserManagementService());
    }

    @Bean
    SetUserShadowbanUseCase setUserShadowbanUseCase() {
        return tx.wrap(SetUserShadowbanUseCase.class, adminUserManagementService());
    }

    @Bean
    WipeUserDataUseCase wipeUserDataUseCase() {
        return tx.wrap(WipeUserDataUseCase.class, adminUserManagementService());
    }

    @Bean
    AnonymizeUserUseCase anonymizeUserUseCase() {
        return tx.wrap(AnonymizeUserUseCase.class, adminUserManagementService());
    }

    @Bean
    DeleteUserUseCase deleteUserUseCase() {
        return tx.wrap(DeleteUserUseCase.class, adminUserManagementService());
    }

    @Bean
    ExportUserDataUseCase exportUserDataUseCase() {
        return tx.wrap(ExportUserDataUseCase.class, adminUserManagementService());
    }

    // ---------------------------------------------------------------- bloqueo

    @Bean(autowireCandidate = false)
    PlatformLockdownService platformLockdownService() {
        return new PlatformLockdownService(lockdown, audit, clock);
    }

    @Bean
    GetLockdownUseCase getLockdownUseCase() {
        return tx.wrap(GetLockdownUseCase.class, platformLockdownService());
    }

    @Bean
    SetLockdownUseCase setLockdownUseCase() {
        return tx.wrap(SetLockdownUseCase.class, platformLockdownService());
    }

    // ---------------------------------------------------------------- auditoría

    @Bean(autowireCandidate = false)
    AdminAuditService adminAuditService() {
        return new AdminAuditService(audit, clock);
    }

    @Bean
    SearchAuditLogUseCase searchAuditLogUseCase() {
        return tx.wrap(SearchAuditLogUseCase.class, adminAuditService());
    }

    @Bean
    RecordAdminAuditUseCase recordAdminAuditUseCase() {
        return tx.wrap(RecordAdminAuditUseCase.class, adminAuditService());
    }
}
