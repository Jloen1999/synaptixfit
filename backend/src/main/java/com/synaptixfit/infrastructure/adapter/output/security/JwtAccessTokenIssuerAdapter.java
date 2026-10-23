package com.synaptixfit.infrastructure.adapter.output.security;

import com.synaptixfit.domain.model.auth.AccessToken;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.auth.AccessTokenIssuerPort;
import com.synaptixfit.infrastructure.config.AppProperties;
import com.synaptixfit.infrastructure.config.SecurityConfig;
import java.time.Clock;
import java.time.Instant;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Component;

/** Emite JWT HS256 con {@code sub} = id de usuario y {@code role} = USER | ADMIN. */
@Component
public class JwtAccessTokenIssuerAdapter implements AccessTokenIssuerPort {

    private final JwtEncoder encoder;
    private final AppProperties properties;
    private final Clock clock;

    public JwtAccessTokenIssuerAdapter(JwtEncoder encoder, AppProperties properties, Clock clock) {
        this.encoder = encoder;
        this.properties = properties;
        this.clock = clock;
    }

    @Override
    public AccessToken issue(User user) {
        Instant now = clock.instant();
        Instant expiresAt = now.plus(properties.jwt().accessTokenTtl());
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(properties.jwt().issuer())
                .subject(user.id().toString())
                .issuedAt(now)
                .expiresAt(expiresAt)
                .claim(SecurityConfig.ROLE_CLAIM, user.role().name())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        String token = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return new AccessToken(token, expiresAt);
    }
}
