package com.synaptixfit.infrastructure.adapter.input.rest.badge.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;

/** Insignias (ids del catálogo) que el cliente ya ha mostrado. */
public record MarkBadgesNotifiedRequest(@NotEmpty List<@NotNull UUID> badgeIds) {
}
