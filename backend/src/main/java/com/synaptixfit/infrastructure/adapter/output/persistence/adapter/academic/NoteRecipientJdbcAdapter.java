package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.port.output.academic.NoteRecipientRepositoryPort;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link NoteRecipientRepositoryPort} sobre {@code apuntes_destinatarios} con SQL estándar (ADR 0012): una
 * tabla de dos claves sin comportamiento no necesita entidad JPA.
 */
@Repository
public class NoteRecipientJdbcAdapter implements NoteRecipientRepositoryPort {

    private final JdbcClient jdbc;

    public NoteRecipientJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void add(UUID noteId, UUID recipientId, Instant at) {
        jdbc.sql("""
                        INSERT INTO apuntes_destinatarios (apunte_id, destinatario_id, creado_en)
                        SELECT :note, :recipient, :at
                        WHERE NOT EXISTS (SELECT 1 FROM apuntes_destinatarios
                                          WHERE apunte_id = :note AND destinatario_id = :recipient)""")
                .param("note", noteId)
                .param("recipient", recipientId)
                .param("at", Timestamp.from(at))
                .update();
    }

    @Override
    public void deleteBetween(UUID userId, UUID otherUserId) {
        jdbc.sql("""
                        DELETE FROM apuntes_destinatarios
                        WHERE (destinatario_id = :other
                               AND apunte_id IN (SELECT id FROM apuntes WHERE usuario_id = :user))
                           OR (destinatario_id = :user
                               AND apunte_id IN (SELECT id FROM apuntes WHERE usuario_id = :other))""")
                .param("user", userId)
                .param("other", otherUserId)
                .update();
    }

    @Override
    public boolean isRecipient(UUID noteId, UUID userId) {
        return jdbc.sql("SELECT count(*) FROM apuntes_destinatarios WHERE apunte_id = :note AND destinatario_id = :user")
                .param("note", noteId)
                .param("user", userId)
                .query(Long.class)
                .single() > 0;
    }
}
