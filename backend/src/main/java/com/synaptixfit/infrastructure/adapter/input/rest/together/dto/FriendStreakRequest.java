package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** Proponer una racha a un amigo mutuo. */
public record FriendStreakRequest(@NotNull UUID friendId) {
}
