package com.synaptixfit.infrastructure.adapter.input.rest.user.dto;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import java.time.Instant;
import java.util.UUID;

/** Cuenta del usuario con su progresión y su enfoque de uso (sin elegir se informa como BOTH). */
public record AccountResponse(UUID id, String email, String fullName, String avatarUrl, int level,
                              int levelXp, int levelThreshold, int streak, Visibility privacy, String role,
                              boolean hasPassword, boolean googleLinked, UsageFocus usageFocus,
                              boolean usageFocusChosen, Instant createdAt) {

    public static AccountResponse from(User u) {
        return new AccountResponse(u.id(), u.email(), u.fullName(), u.avatarUrl(), u.level(), u.levelXp(),
                u.levelThreshold(), u.streak(), u.privacy(), u.role().name(), u.hasPassword(),
                u.googleSubject() != null, u.effectiveFocus(), u.focusChosen(), u.createdAt());
    }
}
