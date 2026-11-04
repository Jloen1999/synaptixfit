package com.synaptixfit.application.service.challenge;

import com.synaptixfit.application.port.input.challenge.ListRoutineDayLinkTargetsUseCase;
import com.synaptixfit.domain.model.challenge.RoutineDayTarget;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import java.util.List;
import java.util.UUID;

/** Implementa {@link ListRoutineDayLinkTargetsUseCase} con {@link ChallengeReferencePort}: solo días vinculables. */
public class RoutineDayLinkTargetService implements ListRoutineDayLinkTargetsUseCase {

    private final ChallengeReferencePort references;

    public RoutineDayLinkTargetService(ChallengeReferencePort references) {
        this.references = references;
    }

    @Override
    public List<RoutineDayTarget> routineDayTargets(UUID userId) {
        return references.routineDayTargets(userId).stream().filter(RoutineDayTarget::linkable).toList();
    }
}
