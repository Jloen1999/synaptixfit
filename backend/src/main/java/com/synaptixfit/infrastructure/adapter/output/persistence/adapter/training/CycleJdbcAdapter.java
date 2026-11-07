package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.CycleDay;
import com.synaptixfit.domain.model.training.CycleEnergy;
import com.synaptixfit.domain.model.training.CycleSymptom;
import com.synaptixfit.domain.model.training.CycleTracking;
import com.synaptixfit.domain.port.output.training.CycleRepositoryPort;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link CycleRepositoryPort} sobre {@code seguimiento_ciclo} y {@code dias_ciclo} (V1040). Las filas se
 * sustituyen con actualizar y, si no había, insertar (SQL estándar). Las molestias van separadas por comas.
 */
@Component
public class CycleJdbcAdapter implements CycleRepositoryPort {

    private final JdbcClient jdbc;

    public CycleJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<CycleTracking> findTracking(UUID userId) {
        return jdbc.sql("SELECT activo, consentimiento_en, consentimiento_retirado_en FROM seguimiento_ciclo"
                        + " WHERE usuario_id = :user")
                .param("user", userId)
                .query((rs, n) -> new CycleTracking(rs.getBoolean("activo"), instant(rs, "consentimiento_en"),
                        instant(rs, "consentimiento_retirado_en")))
                .optional();
    }

    @Override
    public void saveTracking(UUID userId, CycleTracking tracking, Instant now) {
        int updated = jdbc.sql("UPDATE seguimiento_ciclo SET activo = :on, consentimiento_en = :consent,"
                        + " consentimiento_retirado_en = :withdrawn, actualizado_en = :now WHERE usuario_id = :user")
                .param("on", tracking.enabled())
                .param("consent", timestamp(tracking.consentedAt()))
                .param("withdrawn", timestamp(tracking.withdrawnAt()))
                .param("now", Timestamp.from(now))
                .param("user", userId)
                .update();
        if (updated == 0) {
            jdbc.sql("INSERT INTO seguimiento_ciclo (usuario_id, activo, consentimiento_en,"
                            + " consentimiento_retirado_en, actualizado_en)"
                            + " VALUES (:user, :on, :consent, :withdrawn, :now)")
                    .param("user", userId)
                    .param("on", tracking.enabled())
                    .param("consent", timestamp(tracking.consentedAt()))
                    .param("withdrawn", timestamp(tracking.withdrawnAt()))
                    .param("now", Timestamp.from(now))
                    .update();
        }
    }

    @Override
    public List<CycleDay> findDays(UUID userId, LocalDate from, LocalDate to) {
        return jdbc.sql("SELECT fecha, regla, energia, molestias, nota, actualizado_en FROM dias_ciclo"
                        + " WHERE usuario_id = :user AND fecha BETWEEN :from AND :to ORDER BY fecha")
                .param("user", userId)
                .param("from", from)
                .param("to", to)
                .query((rs, n) -> day(rs))
                .list();
    }

    @Override
    public Optional<CycleDay> findDay(UUID userId, LocalDate date) {
        return jdbc.sql("SELECT fecha, regla, energia, molestias, nota, actualizado_en FROM dias_ciclo"
                        + " WHERE usuario_id = :user AND fecha = :date")
                .param("user", userId)
                .param("date", date)
                .query((rs, n) -> day(rs))
                .optional();
    }

    @Override
    public void saveDay(UUID userId, CycleDay day) {
        String symptoms = day.symptoms().isEmpty() ? null
                : day.symptoms().stream().map(Enum::name).sorted().collect(Collectors.joining(","));
        String energy = day.energy() == null ? null : day.energy().name();
        int updated = jdbc.sql("UPDATE dias_ciclo SET regla = :period, energia = :energy, molestias = :symptoms,"
                        + " nota = :note, actualizado_en = :at WHERE usuario_id = :user AND fecha = :date")
                .param("period", day.period())
                .param("energy", energy)
                .param("symptoms", symptoms)
                .param("note", day.note())
                .param("at", Timestamp.from(day.updatedAt()))
                .param("user", userId)
                .param("date", day.date())
                .update();
        if (updated == 0) {
            jdbc.sql("INSERT INTO dias_ciclo (usuario_id, fecha, regla, energia, molestias, nota, actualizado_en)"
                            + " VALUES (:user, :date, :period, :energy, :symptoms, :note, :at)")
                    .param("user", userId)
                    .param("date", day.date())
                    .param("period", day.period())
                    .param("energy", energy)
                    .param("symptoms", symptoms)
                    .param("note", day.note())
                    .param("at", Timestamp.from(day.updatedAt()))
                    .update();
        }
    }

    @Override
    public void deleteDay(UUID userId, LocalDate date) {
        jdbc.sql("DELETE FROM dias_ciclo WHERE usuario_id = :user AND fecha = :date")
                .param("user", userId)
                .param("date", date)
                .update();
    }

    @Override
    public void deleteAllDays(UUID userId) {
        jdbc.sql("DELETE FROM dias_ciclo WHERE usuario_id = :user").param("user", userId).update();
    }

    private static CycleDay day(ResultSet rs) throws SQLException {
        String energy = rs.getString("energia");
        String symptoms = rs.getString("molestias");
        Set<CycleSymptom> parsed = symptoms == null || symptoms.isBlank() ? Set.of()
                : Arrays.stream(symptoms.split(",")).map(String::strip).map(CycleSymptom::valueOf)
                .collect(Collectors.toCollection(() -> EnumSet.noneOf(CycleSymptom.class)));
        return new CycleDay(rs.getObject("fecha", LocalDate.class), rs.getBoolean("regla"),
                energy == null ? null : CycleEnergy.valueOf(energy), parsed, rs.getString("nota"),
                instant(rs, "actualizado_en"));
    }

    private static Instant instant(ResultSet rs, String column) throws SQLException {
        Timestamp t = rs.getTimestamp(column);
        return t == null ? null : t.toInstant();
    }

    private static Timestamp timestamp(Instant instant) {
        return instant == null ? null : Timestamp.from(instant);
    }
}
