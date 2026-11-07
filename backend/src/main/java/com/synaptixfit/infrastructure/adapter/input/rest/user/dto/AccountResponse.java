package com.synaptixfit.infrastructure.adapter.input.rest.user.dto;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Cuenta del usuario con su progresión y su enfoque de uso (sin elegir se informa como BOTH). La fecha de nacimiento y
 * la edad calculada solo salen aquí, a la propia persona (ADR 0036); nunca en el perfil público.
 */
public record AccountResponse(UUID id, String email, String fullName, String avatarUrl, int level,
                              int levelXp, int levelThreshold, int streak, Visibility privacy, String role,
                              boolean hasPassword, boolean googleLinked, UsageFocus usageFocus,
                              boolean usageFocusChosen, LocalDate birthDate, Integer age, Instant createdAt) {

    /** Al iniciar sesión: la edad con el reloj del sistema (solo informa). */
    public static AccountResponse from(User u) {
        return from(u, Clock.systemUTC());
    }

    public static AccountResponse from(User u, Clock clock) {
        return new AccountResponse(u.id(), u.email(), u.fullName(), u.avatarUrl(), u.level(), u.levelXp(),
                u.levelThreshold(), u.streak(), u.privacy(), u.role().name(), u.hasPassword(),
                u.googleSubject() != null, u.effectiveFocus(), u.focusChosen(), u.birthDate(),
                u.ageOn(LocalDate.now(clock)), u.createdAt());
    }
}
