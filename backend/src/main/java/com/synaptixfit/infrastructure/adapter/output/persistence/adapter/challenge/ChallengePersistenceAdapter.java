package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeQuery;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.ChallengeSummary;
import com.synaptixfit.domain.model.challenge.Milestone;
import com.synaptixfit.domain.model.challenge.ProgressEntry;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.challenge.ChallengeRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SqlLike;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.ChallengeEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.challenge.MilestoneEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.challenge.ChallengePersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.challenge.ChallengeJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.challenge.ChallengeProgressJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.challenge.MilestoneJpaRepository;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link ChallengeRepositoryPort}: el reto y sus tareas se cargan y guardan juntos.
 * Los listados con filtros se resuelven con SQL ({@link JdbcClient}) sobre las tablas del módulo.
 */
@Repository
public class ChallengePersistenceAdapter implements ChallengeRepositoryPort {

    private final ChallengeJpaRepository challenges;
    private final MilestoneJpaRepository milestones;
    private final ChallengeProgressJpaRepository progress;
    private final JdbcClient jdbc;

    public ChallengePersistenceAdapter(ChallengeJpaRepository challenges, MilestoneJpaRepository milestones,
                                       ChallengeProgressJpaRepository progress, JdbcClient jdbc) {
        this.challenges = challenges;
        this.milestones = milestones;
        this.progress = progress;
        this.jdbc = jdbc;
    }

    @Override
    public Optional<Challenge> findById(UUID id) {
        return challenges.findById(id).map(e -> toDomain(List.of(e)).getFirst());
    }

    @Override
    public Challenge save(Challenge challenge) {
        ChallengeEntity entity = challenges.findById(challenge.id()).orElseGet(ChallengeEntity::new);
        ChallengePersistenceMapper.copyToEntity(challenge, entity);
        challenges.saveAndFlush(entity);

        Map<UUID, MilestoneEntity> existing = milestones.findByRetoIdOrderByIndiceOrdenAsc(challenge.id()).stream()
                .collect(Collectors.toMap(MilestoneEntity::getId, m -> m));
        Set<UUID> desired = challenge.milestones().stream().map(Milestone::id).collect(Collectors.toSet());

        // 1. Bajas primero: la restricción única (reto_id, indice_orden) no admite solapes.
        List<MilestoneEntity> removed = existing.values().stream().filter(m -> !desired.contains(m.getId())).toList();
        if (!removed.isEmpty()) {
            milestones.deleteAll(removed);
            milestones.flush();
        }
        // 2. Órdenes provisionales negativos para las tareas que cambian de posición.
        boolean reordered = false;
        for (Milestone m : challenge.milestones()) {
            MilestoneEntity e = existing.get(m.id());
            if (e != null && e.getIndiceOrden() != m.order()) {
                e.setIndiceOrden(-m.order());
                reordered = true;
            }
        }
        if (reordered) {
            milestones.flush();
        }
        // 3. Estado final de todas las tareas.
        List<MilestoneEntity> toSave = new ArrayList<>();
        for (Milestone m : challenge.milestones()) {
            MilestoneEntity e = existing.getOrDefault(m.id(), new MilestoneEntity());
            ChallengePersistenceMapper.copyToEntity(challenge.id(), m, e);
            toSave.add(e);
        }
        milestones.saveAllAndFlush(toSave);
        return findById(challenge.id()).orElseThrow();
    }

    @Override
    public void delete(UUID id) {
        challenges.deleteById(id);
        challenges.flush();
    }

    @Override
    public PageResult<Challenge> findByOwner(UUID ownerId, ChallengeQuery query, PageRequest page, Instant now) {
        StringBuilder where = new StringBuilder(" where r.usuario_id = :owner");
        Map<String, Object> params = new HashMap<>();
        params.put("owner", ownerId);
        if (query.status() != null) {
            // Filtro paginado: replica en SQL estándar la regla de Challenge.statusOf (fuente de verdad).
            params.put("now", OffsetDateTime.ofInstant(now, ZoneOffset.UTC));
            switch (query.status()) {
                case COMPLETED -> where.append(" and r.esta_completado = true");
                case ACTIVE -> where.append(" and r.esta_completado = false and r.fecha_fin >= :now");
                case EXPIRED -> where.append(" and r.esta_completado = false and r.fecha_fin < :now");
            }
        }
        if (query.type() != null) {
            where.append(" and r.tipo = :type");
            params.put("type", query.type().name().toLowerCase(Locale.ROOT));
        }
        if (query.withTasks() != null) {
            where.append(query.withTasks() ? " and " : " and not ")
                    .append("exists (select 1 from hitos_de_reto h where h.reto_id = r.id)");
        }
        if (query.text() != null) {
            where.append(" and ").append(SqlLike.containsIgnoreCase("r.titulo", "text"));
            params.put("text", SqlLike.contains(query.text()));
        }
        long total = jdbc.sql("select count(*) from retos r" + where).params(params).query(Long.class).single();
        params.put("limit", page.size());
        params.put("offset", page.offset());
        List<UUID> ids = jdbc.sql("select r.id from retos r" + where
                        + " order by r.esta_completado asc, r.fecha_fin asc, r.id limit :limit offset :offset")
                .params(params).query(UUID.class).list();
        return new PageResult<>(loadInOrder(ids), page.page(), page.size(), total);
    }

    @Override
    public ChallengeSummary summarize(UUID ownerId, Instant now) {
        // Solo datos: el estado de cada reto lo decide Challenge.statusOf (la misma regla que el agregado).
        List<ChallengeStatus> statuses = jdbc.sql("select esta_completado, fecha_fin from retos where usuario_id = :owner")
                .param("owner", ownerId)
                .query((rs, n) -> Challenge.statusOf(rs.getBoolean("esta_completado"),
                        rs.getObject("fecha_fin", OffsetDateTime.class).toInstant(), now))
                .list();
        return ChallengeSummary.of(statuses);
    }

    @Override
    public List<Challenge> findActiveByOwner(UUID ownerId, Instant now) {
        return toDomain(challenges
                .findByUsuarioIdAndEstaCompletadoFalseAndFechaFinGreaterThanEqualOrderByFechaFinAsc(ownerId, now));
    }

    @Override
    public List<Challenge> findByLinkedEntity(UUID ownerId, UUID entityId) {
        return toDomain(challenges.findLinkedTo(ownerId, entityId));
    }

    @Override
    public Optional<Challenge> findByMilestoneId(UUID milestoneId) {
        return milestones.findById(milestoneId).flatMap(m -> findById(m.getRetoId()));
    }

    @Override
    public List<Challenge> findTrainingTrackedByOwner(UUID ownerId) {
        return toDomain(challenges.findByUsuarioIdAndTipoAndSesionesObjetivoIsNotNull(ownerId, "fitness"));
    }

    @Override
    public List<Challenge> findNonPrivateByOwner(UUID ownerId) {
        return toDomain(challenges.findByUsuarioIdAndVisibilidadNot(ownerId, "private"));
    }

    @Override
    public ProgressEntry saveProgress(ProgressEntry entry) {
        return ChallengePersistenceMapper.toDomain(progress.save(ChallengePersistenceMapper.toEntity(entry)));
    }

    @Override
    public List<ProgressEntry> findProgress(UUID challengeId) {
        return progress.findByRetoIdOrderByRegistradoEnDesc(challengeId).stream()
                .map(ChallengePersistenceMapper::toDomain).toList();
    }

    // ------------------------------------------------------------ carga del agregado

    private List<Challenge> loadInOrder(List<UUID> ids) {
        if (ids.isEmpty()) {
            return List.of();
        }
        Map<UUID, ChallengeEntity> byId = challenges.findAllById(ids).stream()
                .collect(Collectors.toMap(ChallengeEntity::getId, e -> e));
        return toDomain(ids.stream().map(byId::get).filter(e -> e != null).toList());
    }

    private List<Challenge> toDomain(List<ChallengeEntity> entities) {
        if (entities.isEmpty()) {
            return List.of();
        }
        Collection<UUID> ids = entities.stream().map(ChallengeEntity::getId).toList();
        Map<UUID, List<MilestoneEntity>> milestonesByChallenge = new LinkedHashMap<>();
        for (MilestoneEntity m : milestones.findByRetoIdIn(ids)) {
            milestonesByChallenge.computeIfAbsent(m.getRetoId(), k -> new ArrayList<>()).add(m);
        }
        Map<UUID, Double> manual = new HashMap<>();
        for (Object[] row : progress.sumManualProgress(ids)) {
            manual.put((UUID) row[0], ((Number) row[1]).doubleValue());
        }
        return entities.stream()
                .map(e -> ChallengePersistenceMapper.toDomain(e,
                        milestonesByChallenge.getOrDefault(e.getId(), List.of()), manual.getOrDefault(e.getId(), 0.0)))
                .toList();
    }

}
