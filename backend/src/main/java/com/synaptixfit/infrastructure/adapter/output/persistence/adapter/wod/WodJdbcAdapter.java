package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.wod;

import com.synaptixfit.domain.model.wod.Wod;
import com.synaptixfit.domain.model.wod.WodDefinition;
import com.synaptixfit.domain.model.wod.WodDivision;
import com.synaptixfit.domain.model.wod.WodFormat;
import com.synaptixfit.domain.model.wod.WodMark;
import com.synaptixfit.domain.model.wod.WodMovement;
import com.synaptixfit.domain.model.wod.WodResult;
import com.synaptixfit.domain.model.wod.WodScoreType;
import com.synaptixfit.domain.model.wod.WodUnit;
import com.synaptixfit.domain.port.output.wod.WodRepositoryPort;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.json.JsonMapper;

/**
 * Implementa {@link WodRepositoryPort} sobre {@code wods} y {@code resultados_wod} (V1084). Los movimientos van en
 * una columna {@code jsonb}: se leen y se escriben enteros.
 */
@Component
public class WodJdbcAdapter implements WodRepositoryPort {

    private static final String COLUMNS = "id, usuario_id, fecha, titulo, fuerza, formato, limite_segundos, rondas,"
            + " movimientos, plantilla, creado_en, actualizado_en";
    private static final TypeReference<List<Map<String, Object>>> OBJECTS = new TypeReference<>() { };
    /** «Mis marcas» no pagina: con esto sobra para años de WOD y la lectura sigue siendo una sola consulta. */
    private static final int MAX_MARKS = 1000;

    private final JdbcClient jdbc;
    private final JsonMapper json;

    public WodJdbcAdapter(JdbcClient jdbc, JsonMapper json) {
        this.jdbc = jdbc;
        this.json = json;
    }

    @Override
    public Wod save(Wod w) {
        int updated = bind(jdbc.sql("""
                UPDATE wods SET fecha = :date, titulo = :title, fuerza = :strength, formato = :format,
                    limite_segundos = :cap, rondas = :rounds, movimientos = CAST(:movements AS jsonb),
                    plantilla = :template, firma = :signature, actualizado_en = :updatedAt
                WHERE id = :id AND usuario_id = :user
                """), w).update();
        if (updated == 0) {
            bind(jdbc.sql("""
                    INSERT INTO wods (id, usuario_id, fecha, titulo, fuerza, formato, limite_segundos, rondas,
                        movimientos, plantilla, firma, creado_en, actualizado_en)
                    VALUES (:id, :user, :date, :title, :strength, :format, :cap, :rounds,
                        CAST(:movements AS jsonb), :template, :signature, :createdAt, :updatedAt)
                    """), w).param("createdAt", Timestamp.from(w.createdAt())).update();
        }
        return w;
    }

    private JdbcClient.StatementSpec bind(JdbcClient.StatementSpec spec, Wod w) {
        WodDefinition d = w.definition();
        return spec.param("id", w.id())
                .param("user", w.userId())
                .param("date", Date.valueOf(w.date()))
                .param("title", d.title())
                .param("strength", d.strength())
                .param("format", d.format().name())
                .param("cap", d.timeCapSeconds())
                .param("rounds", d.rounds())
                .param("movements", movements(d.movements()))
                .param("template", w.templateCode())
                .param("signature", d.signature())
                .param("updatedAt", Timestamp.from(w.updatedAt()));
    }

    @Override
    public Optional<Wod> findOwned(UUID userId, UUID wodId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM wods WHERE id = :id AND usuario_id = :user")
                .param("id", wodId)
                .param("user", userId)
                .query(this::map)
                .optional();
    }

    @Override
    public Optional<Wod> findOfDay(UUID userId, LocalDate date) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM wods WHERE usuario_id = :user AND fecha = :date"
                        + " ORDER BY actualizado_en DESC FETCH FIRST 1 ROWS ONLY")
                .param("user", userId)
                .param("date", Date.valueOf(date))
                .query(this::map)
                .optional();
    }

    @Override
    public void delete(UUID userId, UUID wodId) {
        jdbc.sql("DELETE FROM wods WHERE id = :id AND usuario_id = :user")
                .param("id", wodId)
                .param("user", userId)
                .update();
    }

    @Override
    public WodResult saveResult(WodResult r) {
        jdbc.sql("""
                        INSERT INTO resultados_wod (id, wod_id, usuario_id, division, tipo_marca, valor, reps_extra,
                            tope, segundos, bloque_id, hecho_en)
                        VALUES (:id, :wod, :user, :division, :type, :value, :extra, :capped, :seconds, :block, :at)
                        """)
                .param("id", r.id())
                .param("wod", r.wodId())
                .param("user", r.userId())
                .param("division", r.division().name())
                .param("type", r.scoreType().name())
                .param("value", r.value())
                .param("extra", r.extraReps())
                .param("capped", r.capped())
                .param("seconds", r.durationSeconds())
                .param("block", r.blockId())
                .param("at", Timestamp.from(r.performedAt()))
                .update();
        return r;
    }

    @Override
    public List<WodMark> findMarks(UUID userId) {
        return jdbc.sql("""
                        SELECT r.id, r.wod_id, r.usuario_id, r.division, r.tipo_marca, r.valor, r.reps_extra, r.tope,
                            r.segundos, r.bloque_id, r.hecho_en, w.firma, w.titulo, w.plantilla, w.formato
                        FROM resultados_wod r JOIN wods w ON w.id = r.wod_id
                        WHERE r.usuario_id = :user
                        ORDER BY r.hecho_en DESC, r.id
                        FETCH FIRST %d ROWS ONLY
                        """.formatted(MAX_MARKS))
                .param("user", userId)
                .query((rs, n) -> new WodMark(new WodResult(rs.getObject("id", UUID.class),
                        rs.getObject("wod_id", UUID.class), rs.getObject("usuario_id", UUID.class),
                        WodDivision.valueOf(rs.getString("division")),
                        WodScoreType.valueOf(rs.getString("tipo_marca")), rs.getInt("valor"),
                        (Integer) rs.getObject("reps_extra"), rs.getBoolean("tope"), rs.getInt("segundos"),
                        rs.getObject("bloque_id", UUID.class), rs.getTimestamp("hecho_en").toInstant()),
                        rs.getString("firma"), rs.getString("titulo"), rs.getString("plantilla"),
                        WodFormat.valueOf(rs.getString("formato")), false))
                .list();
    }

    private Wod map(ResultSet rs, int row) throws SQLException {
        WodDefinition definition = new WodDefinition(rs.getString("titulo"), rs.getString("fuerza"),
                WodFormat.valueOf(rs.getString("formato")), (Integer) rs.getObject("limite_segundos"),
                (Integer) rs.getObject("rondas"), movements(rs.getString("movimientos")));
        return new Wod(rs.getObject("id", UUID.class), rs.getObject("usuario_id", UUID.class),
                rs.getDate("fecha").toLocalDate(), rs.getString("plantilla"), definition,
                rs.getTimestamp("creado_en").toInstant(), rs.getTimestamp("actualizado_en").toInstant());
    }

    private String movements(List<WodMovement> movements) {
        List<Map<String, Object>> rows = new ArrayList<>();
        for (WodMovement m : movements) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("code", m.code());
            row.put("name", m.name());
            row.put("quantity", m.quantity());
            row.put("unit", m.unit().name());
            row.put("rxKg", m.rxKg());
            row.put("scaledKg", m.scaledKg());
            rows.add(row);
        }
        return json.writeValueAsString(rows);
    }

    private List<WodMovement> movements(String value) {
        return json.readValue(value, OBJECTS).stream()
                .map(r -> new WodMovement((String) r.get("code"), (String) r.get("name"),
                        r.get("quantity") == null ? null : ((Number) r.get("quantity")).intValue(),
                        WodUnit.valueOf((String) r.get("unit")), number(r.get("rxKg")), number(r.get("scaledKg"))))
                .toList();
    }

    private static Double number(Object value) {
        return value == null ? null : ((Number) value).doubleValue();
    }
}
