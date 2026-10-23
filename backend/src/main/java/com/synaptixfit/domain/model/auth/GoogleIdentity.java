package com.synaptixfit.domain.model.auth;

/** Identidad verificada de Google. */
public record GoogleIdentity(String subject, String email, boolean emailVerified, String fullName, String pictureUrl) {
}
