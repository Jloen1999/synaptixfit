package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.badge;

import com.synaptixfit.domain.model.badge.Badge;
import com.synaptixfit.domain.model.badge.UserBadge;
import com.synaptixfit.domain.port.output.badge.BadgeCatalogPort;
import com.synaptixfit.domain.port.output.badge.UserBadgeRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.badge.UserBadgeEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.badge.BadgePersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.badge.BadgeJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.badge.UserBadgeJpaRepository;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/** Implementa el catálogo ({@code insignias}) y las insignias obtenidas ({@code usuario_insignias}). */
@Repository
public class BadgePersistenceAdapter implements BadgeCatalogPort, UserBadgeRepositoryPort {

    private final BadgeJpaRepository badges;
    private final UserBadgeJpaRepository userBadges;
    private final JdbcClient jdbc;

    public BadgePersistenceAdapter(BadgeJpaRepository badges, UserBadgeJpaRepository userBadges, JdbcClient jdbc) {
        this.badges = badges;
        this.userBadges = userBadges;
        this.jdbc = jdbc;
    }

    @Override
    public List<Badge> findAll() {
        return badges.findAllByOrderByOrdenAsc().stream().map(BadgePersistenceMapper::toDomain).toList();
    }

    @Override
    public Optional<Badge> findById(UUID id) {
        return badges.findById(id).map(BadgePersistenceMapper::toDomain);
    }

    @Override
    public List<UserBadge> findByUser(UUID userId) {
        return userBadges.findByUsuarioId(userId).stream().map(BadgePersistenceMapper::toDomain).toList();
    }

    @Override
    public Optional<UserBadge> find(UUID userId, UUID badgeId) {
        return userBadges.findByUsuarioIdAndInsigniaId(userId, badgeId).map(BadgePersistenceMapper::toDomain);
    }

    @Override
    public boolean awardIfAbsent(UserBadge badge) {
        // La restricción única (usuario_id, insignia_id) hace la concesión idempotente.
        return jdbc.sql("""
                        insert into usuario_insignias (id, usuario_id, insignia_id, obtenida_en, notificada, visible)
                        values (:id, :user, :badge, :at, :notified, :visible)
                        on conflict (usuario_id, insignia_id) do nothing
                        """)
                .param("id", badge.id())
                .param("user", badge.userId())
                .param("badge", badge.badgeId())
                .param("at", OffsetDateTime.ofInstant(badge.earnedAt(), ZoneOffset.UTC))
                .param("notified", badge.notified())
                .param("visible", badge.visible())
                .update() > 0;
    }

    @Override
    public UserBadge save(UserBadge badge) {
        UserBadgeEntity entity = userBadges.findById(badge.id()).orElseGet(UserBadgeEntity::new);
        BadgePersistenceMapper.copyToEntity(badge, entity);
        return BadgePersistenceMapper.toDomain(userBadges.save(entity));
    }
}
