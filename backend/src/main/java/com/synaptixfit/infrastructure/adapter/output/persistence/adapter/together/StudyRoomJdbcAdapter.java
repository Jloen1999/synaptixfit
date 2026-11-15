package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.together;

import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomLength;
import com.synaptixfit.domain.model.together.StudyRoomReaction;
import com.synaptixfit.domain.model.together.TogetherMember;
import com.synaptixfit.domain.model.together.TogetherMembers;
import com.synaptixfit.domain.port.output.together.StudyRoomRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.admin.JdbcValues;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link StudyRoomRepositoryPort} sobre {@code salas_estudio} y {@code salas_estudio_miembros} (V1065,
 * ADR 0045). La asignatura, la última reacción y la hora en que entró cada persona van en su fila de miembro.
 */
@Component
public class StudyRoomJdbcAdapter implements StudyRoomRepositoryPort {

    private final JdbcClient jdbc;

    public StudyRoomJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    private record Head(UUID id, UUID creatorId, StudyRoomLength length, int rounds, Instant startedAt,
                        int creditedRounds, Instant createdAt) {
    }

    @Override
    public Optional<StudyRoom> findById(UUID id) {
        return jdbc.sql("SELECT id, creador_id, duracion, rondas, inicio, rondas_contadas, creado_en"
                        + " FROM salas_estudio WHERE id = :id")
                .param("id", id)
                .query((rs, n) -> new Head(rs.getObject("id", UUID.class), rs.getObject("creador_id", UUID.class),
                        StudyRoomLength.valueOf(rs.getString("duracion")), rs.getInt("rondas"),
                        JdbcValues.instant(rs, "inicio"), rs.getInt("rondas_contadas"),
                        JdbcValues.instant(rs, "creado_en")))
                .optional()
                .map(this::toDomain);
    }

    @Override
    public Optional<StudyRoom> findByIdForUpdate(UUID id) {
        // Bloquea la fila de la sala; las de sus personas se leen después, ya en exclusiva (SELECT … FOR UPDATE,
        // listado en database_portability.md).
        return jdbc.sql("SELECT id FROM salas_estudio WHERE id = :id FOR UPDATE")
                .param("id", id)
                .query(UUID.class)
                .optional()
                .flatMap(this::findById);
    }

    @Override
    public List<StudyRoom> findVisibleTo(UUID userId, Instant createdFrom) {
        return jdbc.sql("SELECT s.id FROM salas_estudio s JOIN salas_estudio_miembros m ON m.sala_id = s.id"
                        + " WHERE m.usuario_id = :user AND m.estado IN (:statuses) AND s.creado_en >= :from"
                        + " ORDER BY s.creado_en")
                .param("user", userId)
                .param("statuses", TogetherSql.VISIBLE)
                .param("from", JdbcValues.param(createdFrom))
                .query(UUID.class)
                .list().stream().map(this::findById).flatMap(Optional::stream).toList();
    }

    @Override
    public List<UUID> findWithRoundsToCredit(Instant createdFrom) {
        return jdbc.sql("SELECT id FROM salas_estudio WHERE inicio IS NOT NULL AND rondas_contadas < rondas"
                        + " AND creado_en >= :from ORDER BY inicio")
                .param("from", JdbcValues.param(createdFrom))
                .query(UUID.class)
                .list();
    }

    @Override
    public boolean claimCredits(UUID roomId, int from, int to) {
        return jdbc.sql("UPDATE salas_estudio SET rondas_contadas = :to WHERE id = :id AND rondas_contadas = :from")
                .param("to", to)
                .param("id", roomId)
                .param("from", from)
                .update() == 1;
    }

    @Override
    public StudyRoom save(StudyRoom room) {
        boolean exists = jdbc.sql("SELECT count(*) FROM salas_estudio WHERE id = :id").param("id", room.id())
                .query(Long.class).single() > 0;
        if (exists && room.startedAt() != null) {
            jdbc.sql("UPDATE salas_estudio SET inicio = :started WHERE id = :id AND inicio IS NULL")
                    .param("started", JdbcValues.param(room.startedAt()))
                    .param("id", room.id())
                    .update();
        }
        if (!exists) {
            jdbc.sql("INSERT INTO salas_estudio (id, creador_id, duracion, rondas, inicio, rondas_contadas, creado_en)"
                            + " VALUES (:id, :creator, :length, :rounds, :started, :credited, :created)")
                    .param("id", room.id())
                    .param("creator", room.creatorId())
                    .param("length", room.length().name())
                    .param("rounds", room.rounds())
                    .param("started", JdbcValues.param(room.startedAt()))
                    .param("credited", room.creditedRounds())
                    .param("created", JdbcValues.param(room.createdAt()))
                    .update();
        }
        Map<UUID, UUID> subjects = room.subjects();
        Map<UUID, StudyRoom.MemberReaction> reactions = room.reactions();
        Map<UUID, Instant> entered = room.enteredAt();
        for (TogetherMember m : room.members().all()) {
            StudyRoom.MemberReaction reaction = reactions.get(m.userId());
            Map<String, Object> params = memberParams(room.id(), m, subjects.get(m.userId()), reaction,
                    entered.get(m.userId()));
            int rows = jdbc.sql("UPDATE salas_estudio_miembros SET estado = :status, asignatura_id = :subject,"
                            + " reaccion = :reaction, reaccion_en = :reactedAt, actualizado_en = :at,"
                            + " entro_en = :entered WHERE sala_id = :id AND usuario_id = :user")
                    .params(params)
                    .update();
            if (rows == 0) {
                jdbc.sql("INSERT INTO salas_estudio_miembros (sala_id, usuario_id, estado, asignatura_id, reaccion,"
                                + " reaccion_en, actualizado_en, entro_en)"
                                + " VALUES (:id, :user, :status, :subject, :reaction, :reactedAt, :at, :entered)")
                        .params(params)
                        .update();
            }
        }
        return room;
    }

    private static Map<String, Object> memberParams(UUID roomId, TogetherMember m, UUID subject,
                                                    StudyRoom.MemberReaction reaction, Instant entered) {
        Map<String, Object> params = new HashMap<>();
        params.put("id", roomId);
        params.put("user", m.userId());
        params.put("status", m.status().name());
        params.put("subject", subject);
        params.put("reaction", reaction == null ? null : reaction.reaction().name());
        params.put("reactedAt", reaction == null ? null : JdbcValues.param(reaction.at()));
        params.put("at", JdbcValues.param(m.updatedAt()));
        params.put("entered", entered == null ? null : JdbcValues.param(entered));
        return params;
    }

    private StudyRoom toDomain(Head h) {
        List<TogetherMember> members = new ArrayList<>();
        Map<UUID, UUID> subjects = new HashMap<>();
        Map<UUID, StudyRoom.MemberReaction> reactions = new HashMap<>();
        Map<UUID, Instant> entered = new HashMap<>();
        jdbc.sql("SELECT usuario_id, estado, asignatura_id, reaccion, reaccion_en, actualizado_en, entro_en"
                        + " FROM salas_estudio_miembros WHERE sala_id = :id ORDER BY usuario_id")
                .param("id", h.id())
                .query((rs, n) -> {
                    UUID user = rs.getObject("usuario_id", UUID.class);
                    UUID subject = rs.getObject("asignatura_id", UUID.class);
                    if (subject != null) {
                        subjects.put(user, subject);
                    }
                    Instant enteredAt = JdbcValues.instant(rs, "entro_en");
                    if (enteredAt != null) {
                        entered.put(user, enteredAt);
                    }
                    String reaction = rs.getString("reaccion");
                    if (reaction != null) {
                        reactions.put(user, new StudyRoom.MemberReaction(StudyRoomReaction.valueOf(reaction),
                                JdbcValues.instant(rs, "reaccion_en")));
                    }
                    return new TogetherMember(user, MemberStatus.valueOf(rs.getString("estado")),
                            JdbcValues.instant(rs, "actualizado_en"));
                })
                .list()
                .forEach(members::add);
        return new StudyRoom(h.id(), h.creatorId(), h.length(), h.rounds(), h.createdAt(), h.startedAt(),
                h.creditedRounds(), new TogetherMembers(members), subjects, reactions, entered);
    }
}
