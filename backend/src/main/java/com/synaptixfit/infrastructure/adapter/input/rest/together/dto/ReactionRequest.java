package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.domain.model.together.Reaction;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.UUID;

/** Reacción fija a lo que sumó {@code recipientId} el día {@code day}. */
public record ReactionRequest(@NotNull UUID recipientId, @NotNull LocalDate day, @NotNull Reaction reaction) {
}
