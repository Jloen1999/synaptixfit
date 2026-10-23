package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeDetails;
import com.synaptixfit.domain.model.challenge.MilestoneDraft;
import java.util.List;
import java.util.UUID;

/** Crea un reto con tareas opcionales (máx. 12, pesos que suman 100). */
public interface CreateChallengeUseCase {

    record Command(UUID userId, ChallengeDetails details, List<MilestoneDraft> milestones) {}

    Challenge createChallenge(Command command);
}
