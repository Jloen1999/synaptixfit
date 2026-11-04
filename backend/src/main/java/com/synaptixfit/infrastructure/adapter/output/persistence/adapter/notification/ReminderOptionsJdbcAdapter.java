package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.notification;

import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/** Implementa {@link ReminderOptionsRepositoryPort} sobre {@code opciones_avisos} (V1042), con actualizar o insertar. */
@Component
public class ReminderOptionsJdbcAdapter implements ReminderOptionsRepositoryPort {

    private final JdbcClient jdbc;

    public ReminderOptionsJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<ReminderOptions> find(UUID userId) {
        return jdbc.sql("SELECT racha, registro_diario, clases FROM opciones_avisos WHERE usuario_id = :user")
                .param("user", userId)
                .query((rs, n) -> new ReminderOptions(rs.getBoolean("racha"), rs.getBoolean("registro_diario"),
                        rs.getBoolean("clases")))
                .optional();
    }

    @Override
    public void save(UUID userId, ReminderOptions options, Instant now) {
        int updated = jdbc.sql("UPDATE opciones_avisos SET racha = :streak, registro_diario = :checkIn,"
                        + " clases = :classes, actualizado_en = :now WHERE usuario_id = :user")
                .param("streak", options.streak())
                .param("checkIn", options.checkIn())
                .param("classes", options.classes())
                .param("now", Timestamp.from(now))
                .param("user", userId)
                .update();
        if (updated == 0) {
            jdbc.sql("INSERT INTO opciones_avisos (usuario_id, racha, registro_diario, clases, actualizado_en)"
                            + " VALUES (:user, :streak, :checkIn, :classes, :now)")
                    .param("user", userId)
                    .param("streak", options.streak())
                    .param("checkIn", options.checkIn())
                    .param("classes", options.classes())
                    .param("now", Timestamp.from(now))
                    .update();
        }
    }
}
