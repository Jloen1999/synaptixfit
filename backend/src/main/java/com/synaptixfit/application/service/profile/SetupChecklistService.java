package com.synaptixfit.application.service.profile;

import com.synaptixfit.application.port.input.planner.GetCalendarBlocksUseCase;
import com.synaptixfit.application.port.input.profile.GetOnboardingStatusUseCase;
import com.synaptixfit.application.port.input.profile.GetSetupChecklistUseCase;
import com.synaptixfit.application.port.input.training.ListMyRoutinesUseCase;
import com.synaptixfit.domain.model.profile.OnboardingStatus;
import com.synaptixfit.domain.model.profile.SetupChecklist;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.training.RoutineStatus;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * Implementa {@link GetSetupChecklistUseCase}: junta el estado del onboarding con dos datos de otros
 * módulos (rutina activa y calendario de los próximos días) a través de sus casos de uso; la regla
 * de qué falta vive en {@link SetupChecklist}.
 */
public class SetupChecklistService implements GetSetupChecklistUseCase {

    /** Días por delante en los que se busca algo planificado. */
    static final int UPCOMING_DAYS = 7;

    private final GetOnboardingStatusUseCase onboarding;
    private final ListMyRoutinesUseCase routines;
    private final GetCalendarBlocksUseCase blocks;
    private final Clock clock;

    public SetupChecklistService(GetOnboardingStatusUseCase onboarding, ListMyRoutinesUseCase routines,
                                 GetCalendarBlocksUseCase blocks, Clock clock) {
        this.onboarding = onboarding;
        this.routines = routines;
        this.blocks = blocks;
        this.clock = clock;
    }

    @Override
    public SetupChecklist getSetupChecklist(UUID userId) {
        OnboardingStatus status = onboarding.getOnboardingStatus(userId);
        Instant now = clock.instant();
        boolean hasActiveRoutine = routines.listMine(userId, RoutineStatus.ACTIVE, new PageRequest(0, 1)).totalItems() > 0;
        boolean hasUpcomingBlocks = !blocks.getBlocks(userId, now, now.plus(Duration.ofDays(UPCOMING_DAYS)), null)
                .isEmpty();
        return SetupChecklist.of(status, hasActiveRoutine, hasUpcomingBlocks);
    }
}
