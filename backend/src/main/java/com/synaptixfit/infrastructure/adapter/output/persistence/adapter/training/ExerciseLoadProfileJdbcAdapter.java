package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.load.LoadProfile;
import com.synaptixfit.domain.model.training.load.LoadType;
import com.synaptixfit.domain.port.output.training.ExerciseLoadProfileRepositoryPort;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link ExerciseLoadProfileRepositoryPort} sobre {@code cargas_iniciales_ejercicio} (V1072-V1073, ADR
 * 0054). {@link ExerciseSqlReader} usa las mismas columnas para llevar el perfil en cada ejercicio planificado.
 */
@Component
public class ExerciseLoadProfileJdbcAdapter implements ExerciseLoadProfileRepositoryPort {

    /** Columnas del perfil con el alias {@code c}; todas nulas si el ejercicio no tiene perfil. */
    static final String COLUMNS = "c.tipo_carga, c.fraccion_peso_corporal, c.kg_defecto, c.kg_tope, c.tren_inferior";

    private final JdbcClient jdbc;

    public ExerciseLoadProfileJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Map<UUID, LoadProfile> findByExerciseIds(Collection<UUID> exerciseIds) {
        Map<UUID, LoadProfile> result = new HashMap<>();
        if (exerciseIds == null || exerciseIds.isEmpty()) {
            return result;
        }
        jdbc.sql("SELECT c.ejercicio_id, " + COLUMNS + " FROM cargas_iniciales_ejercicio c"
                        + " WHERE c.ejercicio_id IN (:ids)")
                .param("ids", exerciseIds)
                .query((rs, n) -> {
                    result.put(rs.getObject("ejercicio_id", UUID.class), profile(rs));
                    return null;
                })
                .list();
        return result;
    }

    /** Perfil de la fila actual o nulo si no tiene ({@code tipo_carga} nulo tras un LEFT JOIN). */
    static LoadProfile profile(ResultSet rs) throws SQLException {
        String type = rs.getString("tipo_carga");
        if (type == null) {
            return null;
        }
        return new LoadProfile(LoadType.valueOf(type), number(rs, "fraccion_peso_corporal"),
                number(rs, "kg_defecto"), number(rs, "kg_tope"), rs.getBoolean("tren_inferior"));
    }

    private static Double number(ResultSet rs, String column) throws SQLException {
        BigDecimal value = rs.getBigDecimal(column);
        return value == null ? null : value.doubleValue();
    }
}
