package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.PostView;
import java.util.UUID;

/** Una publicación visible para el usuario. */
public interface GetPostUseCase {

    PostView getPost(UUID viewerId, UUID postId);
}
