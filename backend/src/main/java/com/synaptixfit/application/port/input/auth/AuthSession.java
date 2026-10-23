package com.synaptixfit.application.port.input.auth;

import com.synaptixfit.domain.model.user.User;
import java.time.Instant;

/** Sesión emitida tras autenticarse o refrescar. */
public record AuthSession(User user, String accessToken, Instant accessTokenExpiresAt, String refreshToken) {
}
