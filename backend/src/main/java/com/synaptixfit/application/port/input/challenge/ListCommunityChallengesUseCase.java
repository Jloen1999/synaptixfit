package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.CommunityChallenge;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Retos activos de otros usuarios: públicos o de amigos (sin autores silenciados). */
public interface ListCommunityChallengesUseCase {

    PageResult<CommunityChallenge> listCommunityChallenges(UUID viewerId, ChallengeType type, String text,
                                                           PageRequest page);
}
