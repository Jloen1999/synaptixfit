package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.together;

import com.synaptixfit.domain.model.together.FriendStreak;
import com.synaptixfit.domain.port.output.together.FriendStreakRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin.JdbcValues;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/** Implementa {@link FriendStreakRepositoryPort} sobre {@code rachas_amigo} (V1064, ADR 0044). */
@Component
public class FriendStreakJdbcAdapter implements FriendStreakRepositoryPort {

    private static final String SELECT = "SELECT id, solicitante_id, receptor_id, estado, desde, ultimo_aviso,"
            + " creado_en, actualizado_en FROM rachas_amigo";

    private final JdbcClient jdbc;

    public FriendStreakJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<FriendStreak> findById(UUID id) {
        return jdbc.sql(SELECT + " WHERE id = :id").param("id", id).query(FriendStreakJdbcAdapter::map).optional();
    }

    @Override
    public Optional<FriendStreak> findBetween(UUID userA, UUID userB) {
        return jdbc.sql(SELECT + " WHERE (solicitante_id = :a AND receptor_id = :b)"
                        + " OR (solicitante_id = :b AND receptor_id = :a)")
                .param("a", userA).param("b", userB)
                .query(FriendStreakJdbcAdapter::map).optional();
    }

    @Override
    public List<FriendStreak> findByUser(UUID userId) {
        return jdbc.sql(SELECT + " WHERE solicitante_id = :user OR receptor_id = :user ORDER BY creado_en")
                .param("user", userId)
                .query(FriendStreakJdbcAdapter::map).list();
    }

    @Override
    public FriendStreak save(FriendStreak s) {
        int updated = jdbc.sql("UPDATE rachas_amigo SET estado = :status, desde = :since, ultimo_aviso = :nudge,"
                        + " actualizado_en = :updated WHERE id = :id")
                .param("status", s.status().name())
                .param("since", s.since())
                .param("nudge", s.lastNudgeOn())
                .param("updated", JdbcValues.param(s.updatedAt()))
                .param("id", s.id())
                .update();
        if (updated == 0) {
            jdbc.sql("INSERT INTO rachas_amigo (id, solicitante_id, receptor_id, usuario_menor, usuario_mayor, estado,"
                            + " desde, ultimo_aviso, creado_en, actualizado_en) VALUES (:id, :requester, :addressee,"
                            + " :lower, :higher, :status, :since, :nudge, :created, :updated)")
                    .param("id", s.id())
                    .param("lower", s.lowerId())
                    .param("higher", s.higherId())
                    .param("requester", s.requesterId())
                    .param("addressee", s.addresseeId())
                    .param("status", s.status().name())
                    .param("since", s.since())
                    .param("nudge", s.lastNudgeOn())
                    .param("created", JdbcValues.param(s.createdAt()))
                    .param("updated", JdbcValues.param(s.updatedAt()))
                    .update();
        }
        return s;
    }

    @Override
    public void delete(UUID id) {
        jdbc.sql("DELETE FROM rachas_amigo WHERE id = :id").param("id", id).update();
    }

    private static FriendStreak map(ResultSet rs, int row) throws SQLException {
        return new FriendStreak(rs.getObject("id", UUID.class), rs.getObject("solicitante_id", UUID.class),
                rs.getObject("receptor_id", UUID.class), FriendStreak.Status.valueOf(rs.getString("estado")),
                JdbcValues.date(rs, "desde"), JdbcValues.date(rs, "ultimo_aviso"), JdbcValues.instant(rs, "creado_en"),
                JdbcValues.instant(rs, "actualizado_en"));
    }
}
