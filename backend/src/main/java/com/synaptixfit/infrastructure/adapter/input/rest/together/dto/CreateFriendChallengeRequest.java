package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.domain.model.together.FriendChallenge;
import com.synaptixfit.domain.model.together.FriendChallengeMode;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.Set;
import java.util.UUID;

/** Nuevo reto con amigos: plantilla, días (7-14), modo (por defecto juntos) y amigos (1-24). */
public record CreateFriendChallengeRequest(@NotNull UUID templateId,
                                           @Min(FriendChallenge.MIN_DAYS) @Max(FriendChallenge.MAX_DAYS) int days,
                                           FriendChallengeMode mode,
                                           @NotEmpty @Size(max = FriendChallenge.MAX_FRIENDS) Set<UUID> friendIds) {
}
