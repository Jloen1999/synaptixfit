package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.PublicProfile;
import java.util.UUID;

/** Perfil público de otro usuario según su privacidad. */
public interface GetPublicProfileUseCase {

    PublicProfile getProfile(UUID viewerId, UUID targetUserId);
}
