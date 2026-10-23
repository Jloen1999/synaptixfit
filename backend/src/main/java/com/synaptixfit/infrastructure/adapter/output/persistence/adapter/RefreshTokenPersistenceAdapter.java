package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import com.synaptixfit.domain.model.auth.RefreshToken;
import com.synaptixfit.domain.port.output.auth.RefreshTokenRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.RefreshTokenEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.RefreshTokenJpaRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link RefreshTokenRepositoryPort} con JPA. */
@Repository
public class RefreshTokenPersistenceAdapter implements RefreshTokenRepositoryPort {

    private final RefreshTokenJpaRepository repository;
    private final Clock clock;

    public RefreshTokenPersistenceAdapter(RefreshTokenJpaRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public RefreshToken save(RefreshToken token) {
        RefreshTokenEntity e = repository.findById(token.id()).orElseGet(() -> {
            RefreshTokenEntity created = new RefreshTokenEntity();
            created.setCreadoEn(clock.instant());
            return created;
        });
        e.setId(token.id());
        e.setUsuarioId(token.userId());
        e.setTokenHash(token.tokenHash());
        e.setExpiraEn(token.expiresAt());
        e.setRevocadoEn(token.revokedAt());
        return toDomain(repository.save(e));
    }

    @Override
    public Optional<RefreshToken> findByHash(String tokenHash) {
        return repository.findByTokenHash(tokenHash).map(RefreshTokenPersistenceAdapter::toDomain);
    }

    @Override
    public void revokeAllForUser(UUID userId, Instant when) {
        repository.revokeAllForUser(userId, when);
    }

    private static RefreshToken toDomain(RefreshTokenEntity e) {
        return new RefreshToken(e.getId(), e.getUsuarioId(), e.getTokenHash(), e.getExpiraEn(), e.getRevocadoEn());
    }
}
