package com.synaptixfit.application.service.training;

import com.synaptixfit.application.port.input.training.ChangeCycleTrackingUseCase;
import com.synaptixfit.application.port.input.training.DeleteCycleDayUseCase;
import com.synaptixfit.application.port.input.training.DeleteCycleHistoryUseCase;
import com.synaptixfit.application.port.input.training.GetCycleOverviewUseCase;
import com.synaptixfit.application.port.input.training.ListCycleDaysUseCase;
import com.synaptixfit.application.port.input.training.LogCycleDayUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.training.CycleTrackingOffException;
import com.synaptixfit.domain.model.training.CycleDay;
import com.synaptixfit.domain.model.training.CycleOverview;
import com.synaptixfit.domain.model.training.CycleTracking;
import com.synaptixfit.domain.port.output.training.CycleRepositoryPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

/**
 * Seguimiento del ciclo, opcional (ADR 0033): activar con consentimiento, apuntar días, listarlos para el calendario
 * y borrarlos. Guarda con {@link CycleRepositoryPort}; la estimación la hace {@link CycleOverview}. «Hoy» es el día
 * en la zona del registro diario, igual que el check-in.
 */
public class CycleTrackingService implements GetCycleOverviewUseCase, ChangeCycleTrackingUseCase, LogCycleDayUseCase,
        ListCycleDaysUseCase, DeleteCycleDayUseCase, DeleteCycleHistoryUseCase {

    private final CycleRepositoryPort cycles;
    private final Clock clock;
    private final ZoneId zone;

    public CycleTrackingService(CycleRepositoryPort cycles, Clock clock, ZoneId zone) {
        this.cycles = cycles;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public CycleOverview overview(UUID userId) {
        CycleTracking tracking = cycles.findTracking(userId).orElse(CycleTracking.OFF);
        if (!tracking.enabled()) {
            return CycleOverview.off();
        }
        LocalDate today = today();
        return CycleOverview.compute(tracking,
                cycles.findDays(userId, today.minusDays(CycleOverview.LOOKBACK_DAYS), today), today);
    }

    @Override
    public CycleOverview change(UUID userId, boolean enabled, boolean consent, boolean deleteHistory) {
        CycleTracking current = cycles.findTracking(userId).orElse(CycleTracking.OFF);
        if (enabled && !current.enabled()) {
            cycles.saveTracking(userId, CycleTracking.enable(consent, clock.instant()), clock.instant());
        } else if (!enabled) {
            cycles.saveTracking(userId, current.disable(clock.instant()), clock.instant());
            if (deleteHistory) {
                cycles.deleteAllDays(userId);
            }
        }
        return overview(userId);
    }

    @Override
    public CycleOverview log(Command command) {
        requireEnabled(command.userId());
        CycleDay day = new CycleDay(command.date(), command.period(), command.energy(), command.symptoms(),
                command.note(), clock.instant());
        day.requireLoggableOn(today());
        cycles.saveDay(command.userId(), day);
        return overview(command.userId());
    }

    @Override
    public List<CycleDay> list(UUID userId, LocalDate from, LocalDate to) {
        if (to.isBefore(from) || ChronoUnit.DAYS.between(from, to) >= MAX_DAYS) {
            throw new FieldValidationException("to", "OUT_OF_RANGE", "range must be at most " + MAX_DAYS + " days");
        }
        return cycles.findDays(userId, from, to);
    }

    @Override
    public void delete(UUID userId, LocalDate date) {
        cycles.deleteDay(userId, date);
    }

    @Override
    public void deleteAll(UUID userId) {
        cycles.deleteAllDays(userId);
    }

    private void requireEnabled(UUID userId) {
        if (!cycles.findTracking(userId).map(CycleTracking::enabled).orElse(false)) {
            throw new CycleTrackingOffException();
        }
    }

    private LocalDate today() {
        return LocalDate.ofInstant(clock.instant(), zone);
    }
}
