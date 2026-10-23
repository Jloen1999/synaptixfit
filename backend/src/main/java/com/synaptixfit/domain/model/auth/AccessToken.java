package com.synaptixfit.domain.model.auth;

import java.time.Instant;

/** Token de acceso firmado y su caducidad. */
public record AccessToken(String value, Instant expiresAt) {
}
