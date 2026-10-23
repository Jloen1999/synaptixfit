package com.synaptixfit.infrastructure.adapter.input.rest.admin;

import com.synaptixfit.application.port.input.admin.AnonymizeUserUseCase;
import com.synaptixfit.application.port.input.admin.ChangeUserRoleUseCase;
import com.synaptixfit.application.port.input.admin.DeleteUserUseCase;
import com.synaptixfit.application.port.input.admin.ExportUserDataUseCase;
import com.synaptixfit.application.port.input.admin.GetUserDetailUseCase;
import com.synaptixfit.application.port.input.admin.GetUserStatsUseCase;
import com.synaptixfit.application.port.input.admin.GetUserTimelineUseCase;
import com.synaptixfit.application.port.input.admin.GetUserWeeklyActivityUseCase;
import com.synaptixfit.application.port.input.admin.SearchUsersUseCase;
import com.synaptixfit.application.port.input.admin.SetUserProgressUseCase;
import com.synaptixfit.application.port.input.admin.SetUserShadowbanUseCase;
import com.synaptixfit.application.port.input.admin.UpdateUserIdentityUseCase;
import com.synaptixfit.application.port.input.admin.WipeUserDataUseCase;
import com.synaptixfit.domain.model.admin.UserSearchCriteria;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.AdminUserAccountResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.AdminUserDetailResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.AdminUserStatsResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.AdminUserSummaryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.ChangeUserRoleRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.ErasureReportResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.SetShadowbanRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.SetUserProgressRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.TimelineEntryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.UpdateUserIdentityRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.WeeklyActivityResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Gestión de usuarios desde el panel de administración. */
@Tag(name = "Admin - Users")
@RestController
@RequestMapping("/api/v1/admin/users")
public class AdminUserController {

    private final SearchUsersUseCase searchUsers;
    private final GetUserDetailUseCase getUserDetail;
    private final GetUserStatsUseCase getUserStats;
    private final GetUserWeeklyActivityUseCase getUserWeeklyActivity;
    private final GetUserTimelineUseCase getUserTimeline;
    private final UpdateUserIdentityUseCase updateUserIdentity;
    private final SetUserProgressUseCase setUserProgress;
    private final ChangeUserRoleUseCase changeUserRole;
    private final SetUserShadowbanUseCase setUserShadowban;
    private final WipeUserDataUseCase wipeUserData;
    private final AnonymizeUserUseCase anonymizeUser;
    private final DeleteUserUseCase deleteUser;
    private final ExportUserDataUseCase exportUserData;

    public AdminUserController(SearchUsersUseCase searchUsers, GetUserDetailUseCase getUserDetail,
                               GetUserStatsUseCase getUserStats, GetUserWeeklyActivityUseCase getUserWeeklyActivity,
                               GetUserTimelineUseCase getUserTimeline, UpdateUserIdentityUseCase updateUserIdentity,
                               SetUserProgressUseCase setUserProgress, ChangeUserRoleUseCase changeUserRole,
                               SetUserShadowbanUseCase setUserShadowban, WipeUserDataUseCase wipeUserData,
                               AnonymizeUserUseCase anonymizeUser, DeleteUserUseCase deleteUser,
                               ExportUserDataUseCase exportUserData) {
        this.searchUsers = searchUsers;
        this.getUserDetail = getUserDetail;
        this.getUserStats = getUserStats;
        this.getUserWeeklyActivity = getUserWeeklyActivity;
        this.getUserTimeline = getUserTimeline;
        this.updateUserIdentity = updateUserIdentity;
        this.setUserProgress = setUserProgress;
        this.changeUserRole = changeUserRole;
        this.setUserShadowban = setUserShadowban;
        this.wipeUserData = wipeUserData;
        this.anonymizeUser = anonymizeUser;
        this.deleteUser = deleteUser;
        this.exportUserData = exportUserData;
    }

    @GetMapping
    public PageResponse<AdminUserSummaryResponse> search(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) Role role,
            @RequestParam(required = false) Boolean shadowbanned,
            @RequestParam(defaultValue = "ACTIVE") UserSearchCriteria.Status status,
            @RequestParam(required = false) Integer minLevel,
            @RequestParam(required = false) Integer maxLevel,
            @RequestParam(defaultValue = "CREATED_AT") UserSearchCriteria.SortField sort,
            @RequestParam(defaultValue = "DESC") UserSearchCriteria.SortDirection direction,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UserSearchCriteria criteria = new UserSearchCriteria(query, role, shadowbanned, status, minLevel, maxLevel,
                sort, direction);
        return PageResponse.from(searchUsers.searchUsers(criteria, new PageRequest(page, size)),
                AdminUserSummaryResponse::from);
    }

    @GetMapping("/{userId}")
    public AdminUserDetailResponse detail(@PathVariable UUID userId) {
        return AdminUserDetailResponse.from(getUserDetail.getUserDetail(userId));
    }

    @GetMapping("/{userId}/stats")
    public AdminUserStatsResponse stats(@PathVariable UUID userId) {
        return AdminUserStatsResponse.from(getUserStats.getUserStats(userId));
    }

    @GetMapping("/{userId}/activity")
    public List<WeeklyActivityResponse> weeklyActivity(@PathVariable UUID userId,
                                                       @RequestParam(defaultValue = "12") int weeks) {
        return getUserWeeklyActivity.getUserWeeklyActivity(userId, weeks).stream()
                .map(WeeklyActivityResponse::from).toList();
    }

    @GetMapping("/{userId}/timeline")
    public PageResponse<TimelineEntryResponse> timeline(@PathVariable UUID userId,
                                                        @RequestParam(defaultValue = "0") int page,
                                                        @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getUserTimeline.getUserTimeline(userId, new PageRequest(page, size)),
                TimelineEntryResponse::from);
    }

    @PatchMapping("/{userId}")
    public AdminUserAccountResponse updateIdentity(@CurrentUserId UUID adminId, @PathVariable UUID userId,
                                                   @Valid @RequestBody UpdateUserIdentityRequest request) {
        return AdminUserAccountResponse.from(updateUserIdentity.updateUserIdentity(
                new UpdateUserIdentityUseCase.Command(adminId, userId, request.fullName(), request.email())));
    }

    @PutMapping("/{userId}/progress")
    public AdminUserAccountResponse setProgress(@CurrentUserId UUID adminId, @PathVariable UUID userId,
                                                @Valid @RequestBody SetUserProgressRequest request) {
        return AdminUserAccountResponse.from(setUserProgress.setUserProgress(
                new SetUserProgressUseCase.Command(adminId, userId, request.level(), request.levelXp())));
    }

    @PutMapping("/{userId}/role")
    public AdminUserAccountResponse changeRole(@CurrentUserId UUID adminId, @PathVariable UUID userId,
                                               @Valid @RequestBody ChangeUserRoleRequest request) {
        return AdminUserAccountResponse.from(changeUserRole.changeUserRole(
                new ChangeUserRoleUseCase.Command(adminId, userId, request.role())));
    }

    @PutMapping("/{userId}/shadowban")
    public AdminUserAccountResponse setShadowban(@CurrentUserId UUID adminId, @PathVariable UUID userId,
                                                 @Valid @RequestBody SetShadowbanRequest request) {
        return AdminUserAccountResponse.from(setUserShadowban.setUserShadowban(
                new SetUserShadowbanUseCase.Command(adminId, userId, request.shadowbanned())));
    }

    @PostMapping("/{userId}/wipe")
    public ErasureReportResponse wipe(@CurrentUserId UUID adminId, @PathVariable UUID userId) {
        return ErasureReportResponse.from(wipeUserData.wipeUserData(adminId, userId));
    }

    @PostMapping("/{userId}/anonymize")
    public ErasureReportResponse anonymize(@CurrentUserId UUID adminId, @PathVariable UUID userId) {
        return ErasureReportResponse.from(anonymizeUser.anonymizeUser(adminId, userId));
    }

    @DeleteMapping("/{userId}")
    public ErasureReportResponse delete(@CurrentUserId UUID adminId, @PathVariable UUID userId) {
        return ErasureReportResponse.from(deleteUser.deleteUser(adminId, userId));
    }

    @GetMapping("/{userId}/export")
    public ResponseEntity<String> export(@CurrentUserId UUID adminId, @PathVariable UUID userId) {
        return ExportResponses.attachment(exportUserData.exportUserData(adminId, userId));
    }
}
