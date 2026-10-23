package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.port.output.academic.PhysicalLoadPort;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lee {@code registros_carga_fisica} (módulo Indicadores) con SQL de solo lectura. Solo trae las
 * filas; las sumas y el máximo diario los calcula {@link PhysicalLoadHistory} en el caso de uso (no se
 * usa la columna generada {@code carga_diaria}).
 */
@Repository
public class PhysicalLoadJdbcAdapter implements PhysicalLoadPort {

    private final JdbcClient jdbc;

    public PhysicalLoadJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public List<PhysicalLoadHistory.Entry> history(UUID userId) {
        return jdbc.sql("SELECT fecha_registro, rpe_sesion, duracion_minutos FROM registros_carga_fisica"
                        + " WHERE usuario_id = :userId")
                .param("userId", userId)
                .query((rs, n) -> new PhysicalLoadHistory.Entry(rs.getObject("fecha_registro", LocalDate.class),
                        rs.getInt("rpe_sesion"), rs.getInt("duracion_minutos")))
                .list();
    }
}
