package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.together;

import com.synaptixfit.domain.model.together.FriendChallenge;
import com.synaptixfit.domain.model.together.FriendChallengeMode;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.Reaction;
import com.synaptixfit.domain.model.together.ReactionRecord;
import com.synaptixfit.domain.model.together.TogetherMember;
import com.synaptixfit.domain.model.together.TogetherMembers;
import com.synaptixfit.domain.port.output.together.FriendChallengeReactionPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin.JdbcValues;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link FriendChallengeRepositoryPort} y {@link FriendChallengeReactionPort} sobre {@code retos_amigos},
 * {@code retos_amigos_miembros} y {@code reacciones_reto_amigos} (V1064, ADR 0044). La cabecera no cambia tras
 * crearse; las personas y las reacciones se actualizan o se insertan (SQL estándar, sin «upsert» propio del motor).
 */
@Component
public class FriendChallengeJdbcAdapter implements FriendChallengeRepositoryPort, FriendChallengeReactionPort {

    private static final String HEAD = "SELECT id, creador_id, plantilla_id, modo, inicio, fin, dias, objetivo_persona,"
            + " tope_diario, creado_en FROM retos_amigos";

    private final JdbcClient jdbc;

    public FriendChallengeJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<FriendChallenge> findById(UUID id) {
        return jdbc.sql(HEAD + " WHERE id = :id").param("id", id)
                .query((rs, n) -> new Object[] {rs.getObject("id", UUID.class),
                        rs.getObject("creador_id", UUID.class), rs.getObject("plantilla_id", UUID.class),
                        rs.getString("modo"), JdbcValues.instant(rs, "inicio"), JdbcValues.instant(rs, "fin"),
                        rs.getInt("dias"), rs.getInt("objetivo_persona"), rs.getInt("tope_diario"),
                        JdbcValues.instant(rs, "creado_en")})
                .optional()
                .map(this::toDomain);
    }

    @Override
    public List<FriendChallenge> findVisibleTo(UUID userId, Instant endedAfter) {
        List<UUID> ids = jdbc.sql("SELECT r.id FROM retos_amigos r JOIN retos_amigos_miembros m ON m.reto_id = r.id"
                        + " WHERE m.usuario_id = :user AND m.estado IN (:statuses) AND r.fin > :after"
                        + " ORDER BY r.fin")
                .param("user", userId)
                .param("statuses", TogetherSql.VISIBLE)
                .param("after", JdbcValues.param(endedAfter))
                .query(UUID.class)
                .list();
        return ids.stream().map(this::findById).flatMap(Optional::stream).toList();
    }

    @Override
    public FriendChallenge save(FriendChallenge c) {
        boolean exists = jdbc.sql("SELECT count(*) FROM retos_amigos WHERE id = :id").param("id", c.id())
                .query(Long.class).single() > 0;
        if (!exists) {
            jdbc.sql("INSERT INTO retos_amigos (id, creador_id, plantilla_id, modo, inicio, fin, dias,"
                            + " objetivo_persona, tope_diario, creado_en) VALUES (:id, :creator, :template, :mode,"
                            + " :start, :end, :days, :target, :cap, :created)")
                    .param("id", c.id())
                    .param("creator", c.creatorId())
                    .param("template", c.templateId())
                    .param("mode", c.mode().name())
                    .param("start", JdbcValues.param(c.startAt()))
                    .param("end", JdbcValues.param(c.endAt()))
                    .param("days", c.days())
                    .param("target", c.perPersonTarget())
                    .param("cap", c.dailyCap())
                    .param("created", JdbcValues.param(c.createdAt()))
                    .update();
        }
        for (TogetherMember m : c.members().all()) {
            int updated = jdbc.sql("UPDATE retos_amigos_miembros SET estado = :status, actualizado_en = :at"
                            + " WHERE reto_id = :id AND usuario_id = :user")
                    .param("status", m.status().name())
                    .param("at", JdbcValues.param(m.updatedAt()))
                    .param("id", c.id())
                    .param("user", m.userId())
                    .update();
            if (updated == 0) {
                jdbc.sql("INSERT INTO retos_amigos_miembros (reto_id, usuario_id, estado, actualizado_en)"
                                + " VALUES (:id, :user, :status, :at)")
                        .param("id", c.id())
                        .param("user", m.userId())
                        .param("status", m.status().name())
                        .param("at", JdbcValues.param(m.updatedAt()))
                        .update();
            }
        }
        return c;
    }

    @Override
    public void put(ReactionRecord r) {
        int updated = jdbc.sql("UPDATE reacciones_reto_amigos SET reaccion = :reaction, creado_en = :at"
                        + " WHERE reto_id = :id AND destinatario_id = :recipient AND dia = :day AND autor_id = :author")
                .param("reaction", r.reaction().name())
                .param("at", JdbcValues.param(r.createdAt()))
                .param("id", r.challengeId())
                .param("recipient", r.recipientId())
                .param("day", r.day())
                .param("author", r.authorId())
                .update();
        if (updated == 0) {
            jdbc.sql("INSERT INTO reacciones_reto_amigos (reto_id, destinatario_id, dia, autor_id, reaccion, creado_en)"
                            + " VALUES (:id, :recipient, :day, :author, :reaction, :at)")
                    .param("id", r.challengeId())
                    .param("recipient", r.recipientId())
                    .param("day", r.day())
                    .param("author", r.authorId())
                    .param("reaction", r.reaction().name())
                    .param("at", JdbcValues.param(r.createdAt()))
                    .update();
        }
    }

    @Override
    public void remove(UUID challengeId, UUID recipientId, LocalDate day, UUID authorId) {
        jdbc.sql("DELETE FROM reacciones_reto_amigos WHERE reto_id = :id AND destinatario_id = :recipient"
                        + " AND dia = :day AND autor_id = :author")
                .param("id", challengeId)
                .param("recipient", recipientId)
                .param("day", day)
                .param("author", authorId)
                .update();
    }

    @Override
    public List<ReactionRecord> findByChallenge(UUID challengeId) {
        return jdbc.sql("SELECT reto_id, destinatario_id, dia, autor_id, reaccion, creado_en"
                        + " FROM reacciones_reto_amigos WHERE reto_id = :id")
                .param("id", challengeId)
                .query((rs, n) -> new ReactionRecord(rs.getObject("reto_id", UUID.class),
                        rs.getObject("destinatario_id", UUID.class), JdbcValues.date(rs, "dia"),
                        rs.getObject("autor_id", UUID.class), Reaction.valueOf(rs.getString("reaccion")),
                        JdbcValues.instant(rs, "creado_en")))
                .list();
    }

    private FriendChallenge toDomain(Object[] h) {
        UUID id = (UUID) h[0];
        List<TogetherMember> members = jdbc.sql("SELECT usuario_id, estado, actualizado_en FROM retos_amigos_miembros"
                        + " WHERE reto_id = :id ORDER BY actualizado_en, usuario_id")
                .param("id", id)
                .query((rs, n) -> new TogetherMember(rs.getObject("usuario_id", UUID.class),
                        MemberStatus.valueOf(rs.getString("estado")), JdbcValues.instant(rs, "actualizado_en")))
                .list();
        return new FriendChallenge(id, (UUID) h[1], (UUID) h[2], FriendChallengeMode.valueOf((String) h[3]),
                (Instant) h[4], (Instant) h[5], (Integer) h[6], (Integer) h[7], (Integer) h[8], (Instant) h[9],
                new TogetherMembers(members));
    }
}
