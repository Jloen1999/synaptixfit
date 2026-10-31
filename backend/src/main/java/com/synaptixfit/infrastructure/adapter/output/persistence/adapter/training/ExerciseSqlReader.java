package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.CatalogItem;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseRef;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingDbValues;
import java.sql.Array;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Lecturas del catálogo de ejercicios con SQL en bloque (5 consultas para cualquier número de
 * ejercicios, en lugar de cargar las colecciones una a una).
 */
@Component
public class ExerciseSqlReader {

    private static final String COLUMNS = "e.id, e.nombre, e.url_gif, e.url_preview, e.instrucciones, e.dificultad, "
            + "e.descripcion, e.finalidad, e.modalidad_entrenamiento, e.tipo_medicion, e.es_circuito, "
            + "COALESCE(e.activo, true) AS activo, e.valor_met, e.creado_en, e.actualizado_en, e.categoria";

    private final JdbcClient jdbc;
    private final ExerciseMediaUrls media;

    public ExerciseSqlReader(JdbcClient jdbc, ExerciseMediaUrls media) {
        this.jdbc = jdbc;
        this.media = media;
    }

    /** Ejercicios completos por id, en el orden de {@code ids}. */
    public List<Exercise> byIds(Collection<UUID> ids) {
        if (ids == null || ids.isEmpty()) {
            return List.of();
        }
        List<Row> rows = jdbc.sql("SELECT " + COLUMNS + " FROM ejercicios e WHERE e.id IN (:ids)")
                .param("ids", ids).query((rs, n) -> row(rs)).list();
        Map<UUID, Exercise> built = assemble(rows, ids);
        List<Exercise> ordered = new ArrayList<>();
        for (UUID id : ids) {
            Exercise e = built.get(id);
            if (e != null) {
                ordered.add(e);
            }
        }
        return ordered;
    }

    public List<Exercise> allActive() {
        List<Row> rows = jdbc.sql("SELECT " + COLUMNS + " FROM ejercicios e WHERE COALESCE(e.activo, true) ORDER BY e.nombre, e.id")
                .query((rs, n) -> row(rs)).list();
        return new ArrayList<>(assemble(rows, null).values());
    }

    /** Referencias ligeras (para ejercicios planificados). */
    public Map<UUID, ExerciseRef> refs(Collection<UUID> ids) {
        Map<UUID, ExerciseRef> result = new HashMap<>();
        if (ids == null || ids.isEmpty()) {
            return result;
        }
        jdbc.sql("SELECT e.id, e.nombre, e.url_gif, e.url_preview, e.modalidad_entrenamiento, e.tipo_medicion, "
                        + "e.es_circuito, e.valor_met, COALESCE(e.activo, true) AS activo FROM ejercicios e WHERE e.id IN (:ids)")
                .param("ids", ids)
                .query((rs, n) -> new ExerciseRef(rs.getObject("id", UUID.class), rs.getString("nombre"),
                        media.resolve(rs.getString("url_gif")), media.resolve(rs.getString("url_preview")),
                        TrainingDbValues.modality(rs.getString("modalidad_entrenamiento")),
                        TrainingDbValues.measurementTypes(strings(rs.getArray("tipo_medicion"))),
                        rs.getBoolean("es_circuito"), rs.getDouble("valor_met"), rs.getBoolean("activo")))
                .list().forEach(r -> result.put(r.id(), r));
        return result;
    }

    public List<CatalogItem> catalog(String table, boolean withImage) {
        String image = withImage ? "url_imagen" : "NULL AS url_imagen";
        return jdbc.sql("SELECT id, nombre, " + image + " FROM " + table + " ORDER BY nombre")
                .query((rs, n) -> new CatalogItem(rs.getInt("id"), rs.getString("nombre"),
                        media.resolve(rs.getString("url_imagen"))))
                .list();
    }

    // ------------------------------------------------------------------ ensamblado

    private record Row(UUID id, String name, String gifUrl, String previewUrl, String[] instructions,
                       String difficulty, String description, String[] purposes, String modality,
                       String[] measurement, boolean circuit, boolean active, double met, Timestamp createdAt,
                       Timestamp updatedAt, String category) {
    }

    private Row row(ResultSet rs) throws SQLException {
        return new Row(rs.getObject("id", UUID.class), rs.getString("nombre"), media.resolve(rs.getString("url_gif")),
                media.resolve(rs.getString("url_preview")), strings(rs.getArray("instrucciones")), rs.getString("dificultad"),
                rs.getString("descripcion"), strings(rs.getArray("finalidad")),
                rs.getString("modalidad_entrenamiento"), strings(rs.getArray("tipo_medicion")),
                rs.getBoolean("es_circuito"), rs.getBoolean("activo"), rs.getDouble("valor_met"),
                rs.getTimestamp("creado_en"), rs.getTimestamp("actualizado_en"), rs.getString("categoria"));
    }

    private Map<UUID, Exercise> assemble(List<Row> rows, Collection<UUID> ids) {
        Map<UUID, List<CatalogItem>> parts = relation("ejercicio_parte_cuerpo", "parte_cuerpo_id", "partes_cuerpo", false, ids);
        Map<UUID, List<CatalogItem>> target = relation("ejercicio_musculo_objetivo", "musculo_id", "musculos", true, ids);
        Map<UUID, List<CatalogItem>> secondary = relation("ejercicio_musculo_secundario", "musculo_id", "musculos", true, ids);
        Map<UUID, List<CatalogItem>> equipment = relation("ejercicio_equipamiento", "equipamiento_id", "equipamientos", false, ids);
        Map<UUID, Exercise> result = new LinkedHashMap<>();
        for (Row r : rows) {
            result.put(r.id(), new Exercise(r.id(), r.name(), r.description(), Arrays.asList(r.instructions()),
                    TrainingDbValues.difficulty(r.difficulty()), Arrays.asList(r.purposes()),
                    TrainingDbValues.modality(r.modality()), TrainingDbValues.measurementTypes(r.measurement()),
                    r.circuit(), r.active(), r.met(), r.gifUrl(), r.previewUrl(),
                    parts.getOrDefault(r.id(), List.of()), target.getOrDefault(r.id(), List.of()),
                    secondary.getOrDefault(r.id(), List.of()), equipment.getOrDefault(r.id(), List.of()),
                    r.createdAt() == null ? null : r.createdAt().toInstant(),
                    r.updatedAt() == null ? null : r.updatedAt().toInstant(),
                    TrainingDbValues.category(r.category())));
        }
        return result;
    }

    private Map<UUID, List<CatalogItem>> relation(String joinTable, String fk, String catalogTable, boolean image,
                                                  Collection<UUID> ids) {
        String sql = "SELECT j.ejercicio_id, c.id, c.nombre, " + (image ? "c.url_imagen" : "NULL AS url_imagen")
                + " FROM " + joinTable + " j JOIN " + catalogTable + " c ON c.id = j." + fk
                + (ids == null ? "" : " WHERE j.ejercicio_id IN (:ids)") + " ORDER BY c.nombre";
        JdbcClient.StatementSpec spec = jdbc.sql(sql);
        if (ids != null) {
            spec = spec.param("ids", ids);
        }
        Map<UUID, List<CatalogItem>> result = new HashMap<>();
        spec.query((ResultSet rs) -> {
            result.computeIfAbsent(rs.getObject("ejercicio_id", UUID.class), k -> new ArrayList<>())
                    .add(new CatalogItem(rs.getInt("id"), rs.getString("nombre"), rs.getString("url_imagen")));
        });
        return result;
    }

    static String[] strings(Array array) throws SQLException {
        if (array == null) {
            return new String[0];
        }
        Object value = array.getArray();
        return value instanceof String[] s ? s : new String[0];
    }
}
