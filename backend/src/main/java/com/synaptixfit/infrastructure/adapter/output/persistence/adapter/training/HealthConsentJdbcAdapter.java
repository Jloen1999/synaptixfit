package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.HealthConsent;
import com.synaptixfit.domain.port.output.training.HealthConsentRepositoryPort;
import java.sql.Timestamp;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link HealthConsentRepositoryPort} sobre {@code consentimientos_salud} (V1044; versión del texto, V1076):
 * una fila por persona,
 * que se actualiza al retirar o volver a dar el consentimiento (actualizar y, si no había, insertar).
 */
@Component
public class HealthConsentJdbcAdapter implements HealthConsentRepositoryPort {

    private final JdbcClient jdbc;

    public HealthConsentJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<HealthConsent> find(UUID userId) {
        return jdbc.sql("SELECT consentido_en, retirado_en, version_texto FROM consentimientos_salud"
                        + " WHERE usuario_id = :user")
                .param("user", userId)
                .query((rs, n) -> {
                    Timestamp withdrawn = rs.getTimestamp("retirado_en");
                    return new HealthConsent(userId, rs.getTimestamp("consentido_en").toInstant(),
                            withdrawn == null ? null : withdrawn.toInstant(), rs.getInt("version_texto"));
                })
                .optional();
    }

    @Override
    public void save(HealthConsent consent) {
        Timestamp withdrawn = consent.withdrawnAt() == null ? null : Timestamp.from(consent.withdrawnAt());
        int updated = jdbc.sql("UPDATE consentimientos_salud SET consentido_en = :given, retirado_en = :withdrawn,"
                        + " version_texto = :version WHERE usuario_id = :user")
                .param("given", Timestamp.from(consent.givenAt()))
                .param("withdrawn", withdrawn)
                .param("version", consent.textVersion())
                .param("user", consent.userId())
                .update();
        if (updated == 0) {
            jdbc.sql("INSERT INTO consentimientos_salud (usuario_id, consentido_en, retirado_en, version_texto)"
                            + " VALUES (:user, :given, :withdrawn, :version)")
                    .param("user", consent.userId())
                    .param("given", Timestamp.from(consent.givenAt()))
                    .param("withdrawn", withdrawn)
                    .param("version", consent.textVersion())
                    .update();
        }
    }
}
