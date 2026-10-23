package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.PostView;
import java.util.UUID;

/** Edita una publicación propia. Los campos nulos no cambian. */
public interface EditPostUseCase {

    record Command(UUID userId, UUID postId, String description, String imageUrl) {}

    PostView editPost(Command command);
}
