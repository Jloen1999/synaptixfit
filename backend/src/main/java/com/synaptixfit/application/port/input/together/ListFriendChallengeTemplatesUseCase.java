package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import java.util.List;
import java.util.UUID;

/** Plantillas que valen para un reto con amigos: las de su modo de uso y nunca las de bienestar. */
public interface ListFriendChallengeTemplatesUseCase {

    List<ChallengeTemplate> friendTemplates(UUID userId, String language);
}
