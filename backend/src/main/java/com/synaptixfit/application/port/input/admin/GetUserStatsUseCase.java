package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.AdminUserStats;
import java.util.UUID;

/** Estadísticas agregadas de un usuario. */
public interface GetUserStatsUseCase {

    AdminUserStats getUserStats(UUID userId);
}
