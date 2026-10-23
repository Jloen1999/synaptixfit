package com.synaptixfit.infrastructure.adapter.input.rest.auth.dto;

import com.synaptixfit.application.port.input.auth.AuthSession;
import com.synaptixfit.infrastructure.adapter.input.rest.user.dto.AccountResponse;
import java.time.Instant;

/** Sesión emitida. */
public record AuthResponse(String accessToken, Instant accessTokenExpiresAt, String refreshToken,
                           String tokenType, AccountResponse user) {

    public static AuthResponse from(AuthSession session) {
        return new AuthResponse(session.accessToken(), session.accessTokenExpiresAt(), session.refreshToken(),
                "Bearer", AccountResponse.from(session.user()));
    }
}
