package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.PostType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.Map;

/** Nueva publicación. {@code metadata}: objeto JSON libre con la entidad vinculada (insignia, rutina, reto…). */
public record CreatePostRequest(@NotNull PostType type,
                                @NotBlank @Size(max = 2000) String description,
                                @Size(max = 2048) String imageUrl,
                                Map<String, Object> metadata) {
}
