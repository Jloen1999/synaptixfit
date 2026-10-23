package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Retos del usuario con filtros de estado, tipo, tareas y texto. */
public interface ListMyChallengesUseCase {

    PageResult<Challenge> listMyChallenges(UUID userId, ChallengeQuery query, PageRequest page);
}
