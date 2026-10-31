package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import com.synaptixfit.domain.model.auth.PasswordResetToken;
import com.synaptixfit.domain.port.output.auth.PasswordResetTokenRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.PasswordResetTokenEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.PasswordResetTokenJpaRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link PasswordResetTokenRepositoryPort} con JPA. */
@Repository
public class PasswordResetTokenPersistenceAdapter implements PasswordResetTokenRepositoryPort {

    private final PasswordResetTokenJpaRepository repository;

    public PasswordResetTokenPersistenceAdapter(PasswordResetTokenJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public PasswordResetToken save(PasswordResetToken token) {
        PasswordResetTokenEntity e = repository.findById(token.id()).orElseGet(PasswordResetTokenEntity::new);
        e.setId(token.id());
        e.setUsuarioId(token.userId());
        e.setTokenHash(token.tokenHash());
        e.setCreadoEn(token.createdAt());
        e.setExpiraEn(token.expiresAt());
        e.setUsadoEn(token.usedAt());
        return toDomain(repository.save(e));
    }

    @Override
    public Optional<PasswordResetToken> findByHash(String tokenHash) {
        return repository.findByTokenHash(tokenHash).map(PasswordResetTokenPersistenceAdapter::toDomain);
    }

    @Override
    public int countCreatedSince(UUID userId, Instant since) {
        return repository.countByUsuarioIdAndCreadoEnAfter(userId, since);
    }

    @Override
    public void invalidateAllForUser(UUID userId, Instant when) {
        repository.invalidateAllForUser(userId, when);
    }

    private static PasswordResetToken toDomain(PasswordResetTokenEntity e) {
        return new PasswordResetToken(e.getId(), e.getUsuarioId(), e.getTokenHash(), e.getCreadoEn(),
                e.getExpiraEn(), e.getUsadoEn());
    }
}
