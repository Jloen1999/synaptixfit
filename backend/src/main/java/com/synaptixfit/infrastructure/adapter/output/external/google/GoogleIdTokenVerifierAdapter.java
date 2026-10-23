package com.synaptixfit.infrastructure.adapter.output.external.google;

import com.synaptixfit.domain.exception.auth.InvalidGoogleTokenException;
import com.synaptixfit.domain.model.auth.GoogleIdentity;
import com.synaptixfit.domain.port.output.auth.GoogleIdentityVerifierPort;
import com.synaptixfit.infrastructure.config.AppProperties;
import java.util.List;
import java.util.Set;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.stereotype.Component;

/** Verifica ID tokens de Google con las claves públicas (JWKS) de Google. */
@Component
public class GoogleIdTokenVerifierAdapter implements GoogleIdentityVerifierPort {

    private static final String JWKS = "https://www.googleapis.com/oauth2/v3/certs";
    private static final Set<String> ISSUERS = Set.of("https://accounts.google.com", "accounts.google.com");

    private final NimbusJwtDecoder decoder;

    public GoogleIdTokenVerifierAdapter(AppProperties properties) {
        List<String> audiences = properties.google().clientIds();
        this.decoder = NimbusJwtDecoder.withJwkSetUri(JWKS).build();
        OAuth2TokenValidator<Jwt> issuer = jwt -> ISSUERS.contains(String.valueOf(jwt.getClaims().get("iss")))
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Invalid issuer", null));
        OAuth2TokenValidator<Jwt> audience = jwt -> jwt.getAudience().stream().anyMatch(audiences::contains)
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Invalid audience", null));
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(JwtValidators.createDefault(), issuer, audience));
    }

    @Override
    public GoogleIdentity verify(String idToken) {
        if (idToken == null || idToken.isBlank()) {
            throw new InvalidGoogleTokenException();
        }
        try {
            Jwt jwt = decoder.decode(idToken);
            Object verified = jwt.getClaims().get("email_verified");
            return new GoogleIdentity(
                    jwt.getSubject(),
                    jwt.getClaimAsString("email"),
                    Boolean.TRUE.equals(verified) || "true".equals(String.valueOf(verified)),
                    jwt.getClaimAsString("name"),
                    jwt.getClaimAsString("picture"));
        } catch (JwtException e) {
            throw new InvalidGoogleTokenException();
        }
    }
}
