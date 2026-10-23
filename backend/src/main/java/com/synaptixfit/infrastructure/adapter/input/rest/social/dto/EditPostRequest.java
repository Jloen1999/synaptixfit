package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import jakarta.validation.constraints.Size;

/** Edición parcial: los campos nulos no cambian; {@code imageUrl} en blanco quita la imagen. */
public record EditPostRequest(@Size(min = 1, max = 2000) String description,
                              @Size(max = 2048) String imageUrl) {
}
