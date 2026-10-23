package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseCategory;
import com.synaptixfit.domain.model.training.ExerciseDraft;
import com.synaptixfit.domain.model.training.ExerciseFilterOptions;
import com.synaptixfit.domain.model.training.ExerciseSearchCriteria;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.port.output.training.ExerciseRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SqlLike;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.ExerciseEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingDbValues;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.ExerciseJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.ExerciseSelectionJpaRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Catálogo de ejercicios. Búsqueda con SQL (índice de texto completo en español
 * {@code idx_ejercicios_fts}, con prefijos para coincidencias parciales) y escritura con JPA.
 */
@Repository
public class ExercisePersistenceAdapter implements ExerciseRepositoryPort {

    private static final Pattern WORD = Pattern.compile("[\\p{L}\\p{N}]+");

    private final JdbcClient jdbc;
    private final ExerciseSqlReader reader;
    private final ExerciseJpaRepository repository;
    private final ExerciseSelectionJpaRepository selections;

    public ExercisePersistenceAdapter(JdbcClient jdbc, ExerciseSqlReader reader, ExerciseJpaRepository repository,
                                      ExerciseSelectionJpaRepository selections) {
        this.jdbc = jdbc;
        this.reader = reader;
        this.repository = repository;
        this.selections = selections;
    }

    @Override
    public PageResult<Exercise> search(ExerciseSearchCriteria c, PageRequest page) {
        StringBuilder where = new StringBuilder(" WHERE 1 = 1");
        Map<String, Object> params = new LinkedHashMap<>();
        if (!c.includeInactive()) {
            where.append(" AND COALESCE(e.activo, true)");
        }
        String tsQuery = tsQuery(c.text());
        if (tsQuery != null) {
            // Búsqueda de texto completo propia de PostgreSQL (índice idx_ejercicios_fts). En MySQL se
            // sustituye por MATCH ... AGAINST sobre un índice FULLTEXT (docs/06-ops/database_portability.md).
            where.append(" AND (to_tsvector('spanish'::regconfig, COALESCE(e.nombre, '') || ' ' || COALESCE(e.descripcion, ''))"
                    + " @@ to_tsquery('spanish'::regconfig, :ts) OR ").append(SqlLike.containsIgnoreCase("e.nombre", "like"))
                    .append(")");
            params.put("ts", tsQuery);
            params.put("like", SqlLike.contains(c.text().strip()));
        }
        if (c.bodyPartId() != null) {
            where.append(" AND EXISTS (SELECT 1 FROM ejercicio_parte_cuerpo x WHERE x.ejercicio_id = e.id AND x.parte_cuerpo_id = :bp)");
            params.put("bp", c.bodyPartId());
        }
        if (c.muscleId() != null) {
            where.append(" AND EXISTS (SELECT 1 FROM ejercicio_musculo_objetivo x WHERE x.ejercicio_id = e.id AND x.musculo_id = :mu)");
            params.put("mu", c.muscleId());
        }
        if (c.equipmentId() != null) {
            where.append(" AND EXISTS (SELECT 1 FROM ejercicio_equipamiento x WHERE x.ejercicio_id = e.id AND x.equipamiento_id = :eq)");
            params.put("eq", c.equipmentId());
        }
        if (c.difficulty() != null) {
            where.append(" AND e.dificultad = :dif");
            params.put("dif", TrainingDbValues.toDb(c.difficulty()));
        }
        if (c.modality() != null) {
            where.append(" AND e.modalidad_entrenamiento = :mod");
            params.put("mod", TrainingDbValues.toDb(c.modality()));
        }
        if (c.category() != null) {
            where.append(" AND e.categoria = :cat");
            params.put("cat", TrainingDbValues.toDb(c.category()));
        }
        if (c.purpose() != null) {
            // finalidad es text[] (PostgreSQL); en MySQL sería JSON con JSON_CONTAINS o una tabla puente.
            where.append(" AND :purpose = ANY (e.finalidad)");
            params.put("purpose", c.purpose().label());
        }
        long total = jdbc.sql("SELECT count(*) FROM ejercicios e" + where).params(params)
                .query(Long.class).single();
        // Primero los que tienen vídeo (se aprende mejor el gesto); después, por nombre.
        List<UUID> ids = jdbc.sql("SELECT e.id FROM ejercicios e" + where
                        + " ORDER BY CASE WHEN e.url_gif IS NULL THEN 1 ELSE 0 END, e.nombre, e.id LIMIT :limit OFFSET :offset")
                .params(params).param("limit", page.size()).param("offset", page.offset())
                .query(UUID.class).list();
        return new PageResult<>(reader.byIds(ids), page.page(), page.size(), total);
    }

    /** {@code press banca} → {@code press:* & banca:*}. Null si no hay palabras. */
    static String tsQuery(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }
        List<String> terms = new ArrayList<>();
        Matcher m = WORD.matcher(text);
        while (m.find() && terms.size() < 8) {
            terms.add(m.group() + ":*");
        }
        return terms.isEmpty() ? null : String.join(" & ", terms);
    }

    @Override
    public Optional<Exercise> findById(UUID id) {
        return reader.byIds(List.of(id)).stream().findFirst();
    }

    @Override
    public Map<UUID, Exercise> findByIds(Collection<UUID> ids) {
        Map<UUID, Exercise> result = new LinkedHashMap<>();
        reader.byIds(ids.stream().distinct().toList()).forEach(e -> result.put(e.id(), e));
        return result;
    }

    @Override
    public List<Exercise> findAllActive() {
        return reader.allActive();
    }

    @Override
    public List<Exercise> findActiveByTargetMuscles(Collection<Integer> muscleIds, Set<ExerciseCategory> categories,
            int limit) {
        if (muscleIds.isEmpty() || limit <= 0) {
            return List.of();
        }
        StringBuilder sql = new StringBuilder("SELECT e.id FROM ejercicios e WHERE COALESCE(e.activo, true) AND e.id IN "
                + "(SELECT j.ejercicio_id FROM ejercicio_musculo_objetivo j WHERE j.musculo_id IN (:muscles))");
        Map<String, Object> params = new HashMap<>();
        params.put("muscles", muscleIds);
        if (!categories.isEmpty()) {
            sql.append(" AND e.categoria IN (:cats)");
            params.put("cats", categories.stream().map(TrainingDbValues::toDb).toList());
        }
        sql.append(" ORDER BY CASE WHEN e.url_gif IS NULL THEN 1 ELSE 0 END, e.nombre, e.id LIMIT :limit");
        List<UUID> ids = jdbc.sql(sql.toString()).params(params).param("limit", limit).query(UUID.class).list();
        return List.copyOf(findByIds(ids).values());
    }

    @Override
    public ExerciseFilterOptions filterOptions() {
        return new ExerciseFilterOptions(reader.catalog("partes_cuerpo", false), reader.catalog("musculos", true),
                reader.catalog("equipamientos", false));
    }

    @Override
    public boolean catalogReferencesExist(ExerciseDraft d) {
        return allExist("partes_cuerpo", d.bodyPartIds())
                && allExist("musculos", union(d.targetMuscleIds(), d.secondaryMuscleIds()))
                && allExist("equipamientos", d.equipmentIds());
    }

    private boolean allExist(String table, Collection<Integer> ids) {
        Set<Integer> distinct = new HashSet<>(ids);
        if (distinct.isEmpty()) {
            return true;
        }
        Long found = jdbc.sql("SELECT count(*) FROM " + table + " WHERE id IN (:ids)").param("ids", distinct)
                .query(Long.class).single();
        return found == distinct.size();
    }

    private static Set<Integer> union(List<Integer> a, List<Integer> b) {
        Set<Integer> s = new HashSet<>(a);
        s.addAll(b);
        return s;
    }

    @Override
    public Exercise create(UUID id, ExerciseDraft draft, Instant now) {
        ExerciseEntity entity = new ExerciseEntity();
        entity.setId(id);
        entity.setCreadoEn(now);
        entity.setActivo(true);
        copy(draft, entity, now);
        repository.saveAndFlush(entity);
        return findById(id).orElseThrow();
    }

    @Override
    public Exercise update(UUID id, ExerciseDraft draft, Instant now) {
        ExerciseEntity entity = repository.findById(id).orElseThrow();
        copy(draft, entity, now);
        repository.saveAndFlush(entity);
        return findById(id).orElseThrow();
    }

    private static void copy(ExerciseDraft d, ExerciseEntity e, Instant now) {
        e.setNombre(d.name());
        e.setDescripcion(d.description());
        e.setInstrucciones(d.instructions().toArray(String[]::new));
        e.setDificultad(TrainingDbValues.toDb(d.difficulty()));
        e.setFinalidad(d.purposes().stream().map(TrainingGoal::label).toArray(String[]::new));
        e.setModalidadEntrenamiento(TrainingDbValues.toDb(d.modality()));
        // Un ejercicio creado a mano toma la categoría de su modalidad (los del catálogo ya la traen).
        if (e.getCategoria() == null) {
            e.setCategoria(TrainingDbValues.toDb(ExerciseCategory.of(d.modality())));
        }
        e.setTipoMedicion(TrainingDbValues.measurementTypesToDb(d.measurementTypes()));
        e.setEsCircuito(d.circuit());
        e.setValorMet(d.met());
        e.setUrlGif(d.gifUrl());
        e.setUrlPreview(d.previewUrl());
        e.setActualizadoEn(now);
        replace(e.getBodyPartIds(), d.bodyPartIds());
        replace(e.getTargetMuscleIds(), d.targetMuscleIds());
        replace(e.getSecondaryMuscleIds(), d.secondaryMuscleIds());
        replace(e.getEquipmentIds(), d.equipmentIds());
    }

    private static void replace(Set<Integer> target, List<Integer> values) {
        target.clear();
        target.addAll(values);
    }

    @Override
    public void setActive(UUID id, boolean active, Instant now) {
        repository.findById(id).ifPresent(e -> {
            e.setActivo(active);
            e.setActualizadoEn(now);
            repository.saveAndFlush(e);
        });
    }

    @Override
    public boolean isUsedInRoutines(UUID id) {
        return selections.existsByEjercicioId(id);
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }
}
