package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.Progression;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import java.time.Instant;
import java.util.UUID;

/** Cuenta de un usuario vista desde el panel. */
public record AdminUserAccountResponse(UUID id, String email, String fullName, String avatarUrl, Role role,
                                       int level, int levelXp, int levelThreshold, long totalXp, int streak,
                                       Visibility privacy, boolean shadowbanned, boolean hasPassword,
                                       boolean googleLinked, boolean deleted, Instant createdAt,
                                       Instant deletedAt) {

    public static AdminUserAccountResponse from(User u) {
        return new AdminUserAccountResponse(u.id(), u.email(), u.fullName(), u.avatarUrl(), u.role(), u.level(),
                u.levelXp(), u.levelThreshold(), Progression.totalXp(u.level(), u.levelXp()), u.streak(),
                u.privacy(), u.shadowbanned(), u.hasPassword(), u.googleSubject() != null, !u.isActive(),
                u.createdAt(), u.deletedAt());
    }
}
