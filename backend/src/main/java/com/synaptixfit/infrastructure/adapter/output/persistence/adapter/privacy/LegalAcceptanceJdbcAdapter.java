package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.privacy;

import com.synaptixfit.domain.model.privacy.LegalAcceptance;
import com.synaptixfit.domain.port.output.privacy.LegalAcceptanceRepositoryPort;
import java.sql.Timestamp;
import java.util.Optional;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/** Implementa {@link LegalAcceptanceRepositoryPort} sobre {@code aceptaciones_legales} (V1043). */
@Component
public class LegalAcceptanceJdbcAdapter implements LegalAcceptanceRepositoryPort {

    private final JdbcClient jdbc;

    public LegalAcceptanceJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<LegalAcceptance> latest(UUID userId) {
        return jdbc.sql("SELECT version, aceptada_en FROM aceptaciones_legales WHERE usuario_id = :user"
                        + " ORDER BY aceptada_en DESC FETCH FIRST 1 ROWS ONLY")
                .param("user", userId)
                .query((rs, n) -> new LegalAcceptance(userId, rs.getString("version"),
                        rs.getTimestamp("aceptada_en").toInstant()))
                .optional();
    }

    @Override
    public void save(LegalAcceptance acceptance) {
        // Volver a aceptar la misma versión no añade otra fila: la constancia es la primera vez.
        boolean exists = jdbc.sql("SELECT COUNT(*) FROM aceptaciones_legales WHERE usuario_id = :user"
                        + " AND version = :version")
                .param("user", acceptance.userId())
                .param("version", acceptance.version())
                .query(Long.class)
                .single() > 0;
        if (exists) {
            return;
        }
        try {
            jdbc.sql("INSERT INTO aceptaciones_legales (id, usuario_id, version, aceptada_en)"
                            + " VALUES (:id, :user, :version, :at)")
                    .param("id", UUID.randomUUID())
                    .param("user", acceptance.userId())
                    .param("version", acceptance.version())
                    .param("at", Timestamp.from(acceptance.acceptedAt()))
                    .update();
        } catch (DuplicateKeyException alreadyAccepted) {
            // Dos «Aceptar» casi a la vez: la otra petición ya dejó constancia de esa versión.
        }
    }
}
