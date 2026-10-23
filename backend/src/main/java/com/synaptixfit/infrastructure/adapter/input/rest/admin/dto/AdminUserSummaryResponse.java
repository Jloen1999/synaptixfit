package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.AdminUserSummary;
import com.synaptixfit.domain.model.user.Role;
import java.time.Instant;
import java.util.UUID;

/** Fila del listado de usuarios. */
public record AdminUserSummaryResponse(UUID id, String email, String fullName, String avatarUrl, Role role,
                                       int level, int levelXp, int levelThreshold, long totalXp, int streak,
                                       boolean shadowbanned, boolean deleted, Instant createdAt,
                                       Instant deletedAt) {

    public static AdminUserSummaryResponse from(AdminUserSummary u) {
        return new AdminUserSummaryResponse(u.id(), u.email(), u.fullName(), u.avatarUrl(), u.role(), u.level(),
                u.levelXp(), u.levelThreshold(), u.totalXp(), u.streak(), u.shadowbanned(), u.deletedAt() != null,
                u.createdAt(), u.deletedAt());
    }
}
