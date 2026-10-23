package com.synaptixfit.application.service.badge;

import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.domain.model.badge.StreakStatus;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.UUID;

/** Racha diaria del usuario: días consecutivos con una sesión de entrenamiento, un check-in o un Pomodoro completado. */
public class StreakService implements GetStreakUseCase {

    private final UserActivityPort activity;
    private final UserRepositoryPort users;
    private final Clock clock;
    private final ZoneId defaultZone;

    public StreakService(UserActivityPort activity, UserRepositoryPort users, Clock clock, ZoneId defaultZone) {
        this.activity = activity;
        this.users = users;
        this.clock = clock;
        this.defaultZone = defaultZone;
    }

    @Override
    public StreakStatus getStreak(UUID userId, String zone) {
        return refresh(userId, UserZones.resolve(zone, defaultZone));
    }

    /** Calcula la racha y la guarda en la cuenta ({@code usuarios.racha_actual}) si ha cambiado. */
    private StreakStatus refresh(UUID userId, ZoneId zone) {
        StreakStatus status = compute(userId, zone);
        users.findById(userId).ifPresent(user -> {
            if (user.streak() != status.currentDays()) {
                user.updateStreak(status.currentDays());
                users.save(user);
            }
        });
        return status;
    }

    /** Calcula la racha sin guardarla. */
    private StreakStatus compute(UUID userId, ZoneId zone) {
        return StreakStatus.compute(activity.activeDays(userId, zone), LocalDateTime.ofInstant(clock.instant(), zone));
    }
}
