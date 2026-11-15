package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.RoutineShareLink;
import com.synaptixfit.domain.port.output.training.RoutineShareLinkRepositoryPort;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/** Implementa {@link RoutineShareLinkRepositoryPort} sobre {@code enlaces_rutina} (V1063). Solo guarda la huella. */
@Component
public class RoutineShareLinkJdbcAdapter implements RoutineShareLinkRepositoryPort {

    private static final String COLUMNS = "id, rutina_id, usuario_id, token_hash, creado_en, caduca_en, revocado_en";

    private final JdbcClient jdbc;

    public RoutineShareLinkJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public RoutineShareLink save(RoutineShareLink link) {
        jdbc.sql("INSERT INTO enlaces_rutina (" + COLUMNS + ") VALUES (:id, :routine, :owner, :hash, :created,"
                        + " :expires, :revoked)")
                .param("id", link.id())
                .param("routine", link.routineId())
                .param("owner", link.ownerId())
                .param("hash", link.tokenHash())
                .param("created", utc(link.createdAt()))
                .param("expires", utc(link.expiresAt()))
                .param("revoked", link.revokedAt() == null ? null : utc(link.revokedAt()))
                .update();
        return link;
    }

    @Override
    public Optional<RoutineShareLink> findByTokenHash(String tokenHash) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM enlaces_rutina WHERE token_hash = :hash")
                .param("hash", tokenHash)
                .query((rs, n) -> map(rs))
                .optional();
    }

    @Override
    public List<RoutineShareLink> findActiveByRoutine(UUID routineId, Instant now) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM enlaces_rutina WHERE rutina_id = :routine"
                        + " AND revocado_en IS NULL AND caduca_en > :now")
                .param("routine", routineId)
                .param("now", utc(now))
                .query((rs, n) -> map(rs))
                .list();
    }

    @Override
    public int revokeAllOfRoutine(UUID routineId, Instant now) {
        return jdbc.sql("UPDATE enlaces_rutina SET revocado_en = :now WHERE rutina_id = :routine"
                        + " AND revocado_en IS NULL AND caduca_en > :now")
                .param("routine", routineId)
                .param("now", utc(now))
                .update();
    }

    private static RoutineShareLink map(ResultSet rs) throws SQLException {
        OffsetDateTime revoked = rs.getObject("revocado_en", OffsetDateTime.class);
        return new RoutineShareLink(rs.getObject("id", UUID.class), rs.getObject("rutina_id", UUID.class),
                rs.getObject("usuario_id", UUID.class), rs.getString("token_hash"),
                rs.getObject("creado_en", OffsetDateTime.class).toInstant(),
                rs.getObject("caduca_en", OffsetDateTime.class).toInstant(),
                revoked == null ? null : revoked.toInstant());
    }

    private static OffsetDateTime utc(Instant instant) {
        return OffsetDateTime.ofInstant(instant, ZoneOffset.UTC);
    }
}
