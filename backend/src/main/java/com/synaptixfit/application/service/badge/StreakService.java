package com.synaptixfit.application.service.badge;

import com.synaptixfit.application.port.input.badge.GetStreakUseCase;
import com.synaptixfit.application.port.input.badge.PauseStreakUseCase;
import com.synaptixfit.application.port.input.badge.PeekStreakUseCase;
import com.synaptixfit.application.port.input.badge.ResumeStreakUseCase;
import com.synaptixfit.domain.model.badge.StreakPause;
import com.synaptixfit.domain.model.badge.StreakStatus;
import com.synaptixfit.domain.port.output.badge.StreakPauseRepositoryPort;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

/**
 * Racha diaria del usuario: días consecutivos con una sesión de entrenamiento, un check-in o un Pomodoro completado,
 * con sus pausas ({@link StreakPause}, guardadas con {@link StreakPauseRepositoryPort}). Pausar y reanudar devuelven
 * la racha ya recalculada.
 */
public class StreakService implements GetStreakUseCase, PeekStreakUseCase, PauseStreakUseCase, ResumeStreakUseCase {

    private final UserActivityPort activity;
    private final UserRepositoryPort users;
    private final StreakPauseRepositoryPort pauses;
    private final Clock clock;
    private final ZoneId defaultZone;

    public StreakService(UserActivityPort activity, UserRepositoryPort users, Clock clock, ZoneId defaultZone) {
        this(activity, users, null, clock, defaultZone);
    }

    /** @param pauses pausas de racha; nulo, la racha no tiene pausas (tests antiguos) */
    public StreakService(UserActivityPort activity, UserRepositoryPort users, StreakPauseRepositoryPort pauses,
                         Clock clock, ZoneId defaultZone) {
        this.activity = activity;
        this.users = users;
        this.pauses = pauses;
        this.clock = clock;
        this.defaultZone = defaultZone;
    }

    @Override
    public StreakStatus getStreak(UUID userId, String zone) {
        return refresh(userId, UserZones.resolve(zone, defaultZone));
    }

    @Override
    public StreakStatus peekStreak(UUID userId, String zone) {
        return compute(userId, UserZones.resolve(zone, defaultZone));
    }

    @Override
    public StreakStatus pause(UUID userId, String zone) {
        ZoneId z = UserZones.resolve(zone, defaultZone);
        LocalDate today = today(z);
        List<StreakPause> existing = pausesOf(userId);
        // Sin racha no hay nada que proteger: no gasta días de pausa (lo mismo que dice canPause).
        if (StreakPause.active(existing, today).isEmpty() && compute(userId, z).currentDays() > 0) {
            pauses.save(StreakPause.start(userId, existing, today, clock.instant()));
        }
        return refresh(userId, z);
    }

    @Override
    public StreakStatus resume(UUID userId, String zone) {
        ZoneId z = UserZones.resolve(zone, defaultZone);
        LocalDate today = today(z);
        StreakPause.active(pausesOf(userId), today).ifPresent(active -> active.resumedOn(today)
                .ifPresentOrElse(pauses::save, () -> pauses.delete(active.id())));
        return refresh(userId, z);
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
        return StreakStatus.compute(activity.activeDays(userId, zone), pausesOf(userId),
                LocalDateTime.ofInstant(clock.instant(), zone));
    }

    private List<StreakPause> pausesOf(UUID userId) {
        return pauses == null ? List.of() : pauses.findByUser(userId);
    }

    private LocalDate today(ZoneId zone) {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
