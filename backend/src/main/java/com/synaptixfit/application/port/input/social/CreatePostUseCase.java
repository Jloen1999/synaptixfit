package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.PostType;
import com.synaptixfit.domain.model.social.PostView;
import java.util.UUID;

/** Publica en el muro. {@code metadata} es JSON serializado opcional (entidad vinculada). */
public interface CreatePostUseCase {

    record Command(UUID userId, PostType type, String description, String imageUrl, String metadata) {}

    PostView createPost(Command command);
}
