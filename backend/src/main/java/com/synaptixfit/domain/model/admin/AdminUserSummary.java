package com.synaptixfit.domain.model.admin;

import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.User;
import java.time.Instant;
import java.util.UUID;

/** Fila del listado de usuarios del panel. */
public record AdminUserSummary(UUID id, String email, String fullName, String avatarUrl, Role role, int level,
                               int levelXp, int streak, boolean shadowbanned, Instant createdAt,
                               Instant deletedAt) {

    public long totalXp() {
        return Progression.totalXp(level, levelXp);
    }

    public int levelThreshold() {
        return User.thresholdFor(level);
    }
}
