package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/** Fija el nivel y la experiencia del nivel de un usuario (resetear XP = levelXp 0). Auditado. */
public interface SetUserProgressUseCase {

    record Command(UUID adminId, UUID userId, int level, int levelXp) {}

    User setUserProgress(Command command);
}
