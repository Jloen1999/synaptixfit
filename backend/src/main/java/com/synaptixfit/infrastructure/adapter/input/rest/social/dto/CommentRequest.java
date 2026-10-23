package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Texto de un comentario (1-500 caracteres). */
public record CommentRequest(@NotBlank @Size(max = 500) String text) {
}
