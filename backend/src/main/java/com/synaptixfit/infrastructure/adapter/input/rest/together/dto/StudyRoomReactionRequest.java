package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.domain.model.together.StudyRoomReaction;
import jakarta.validation.constraints.NotNull;

/** Reacción fija en la sala (sin texto libre). */
public record StudyRoomReactionRequest(@NotNull StudyRoomReaction reaction) {
}
