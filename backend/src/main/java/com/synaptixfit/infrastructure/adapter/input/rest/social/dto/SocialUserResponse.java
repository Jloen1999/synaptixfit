package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import java.util.UUID;

/** Datos públicos de otro usuario en listados de amistad. */
public record SocialUserResponse(UUID id, String fullName, String avatarUrl, int level) {
}
