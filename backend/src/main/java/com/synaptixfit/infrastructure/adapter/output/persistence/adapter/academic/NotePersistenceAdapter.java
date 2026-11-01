package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.AuthoredNote;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.SharedNoteSummary;
import com.synaptixfit.domain.model.shared.AudienceScope;
import com.synaptixfit.domain.model.shared.EffectiveVisibility;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.SharedContentSql;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.NoteEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.NoteJpaRepository;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link NoteRepositoryPort}: JPA para los apuntes propios y SQL de solo lectura para los
 * compartidos, que leen {@code usuarios} y {@code amistades} (otros módulos) y la asignatura del
 * catálogo ({@code asignaturas_catalogo}). La visibilidad se filtra con {@link SharedContentSql}.
 */
@Repository
public class NotePersistenceAdapter implements NoteRepositoryPort {

    private static final String SHARED_FROM = """
             FROM apuntes a JOIN usuarios u ON u.id = a.usuario_id
             LEFT JOIN asignaturas s ON s.id = a.asignatura_id
             LEFT JOIN asignaturas_catalogo c ON c.id = s.catalogo_asignatura_id
            """;

    private static final String AUTHOR_COLUMNS = """
            u.nombre_completo AS autor_nombre, u.url_avatar AS autor_avatar,
            c.id AS catalogo_id, c.nombre AS catalogo_nombre
            """;

    private final NoteJpaRepository repository;
    private final JdbcClient jdbc;

    public NotePersistenceAdapter(NoteJpaRepository repository, JdbcClient jdbc) {
        this.repository = repository;
        this.jdbc = jdbc;
    }

    @Override
    public Optional<Note> findByIdAndUser(UUID id, UUID userId) {
        return repository.findByIdAndUserId(id, userId).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public List<Note> findNonPrivateByUser(UUID userId) {
        return repository.findByUserIdAndVisibilityNot(userId, VisibilityDbMapper.toDb(Visibility.PRIVATE)).stream()
                .map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public PageResult<Note> findByUser(UUID userId, Filter filter, PageRequest page) {
        Specification<NoteEntity> spec = (root, query, cb) -> cb.equal(root.get("userId"), userId);
        if (filter.subjectId() != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("subjectId"), filter.subjectId()));
        }
        if (filter.unassignedOnly()) {
            spec = spec.and((root, query, cb) -> cb.isNull(root.get("subjectId")));
        }
        if (filter.quickOnly()) {
            spec = spec.and((root, query, cb) -> cb.isTrue(root.get("quickNote")));
        }
        Page<NoteEntity> result = repository.findAll(spec, org.springframework.data.domain.PageRequest.of(
                page.page(), page.size(), Sort.by(Sort.Direction.DESC, "updatedAt")));
        return new PageResult<>(result.getContent().stream().map(AcademicPersistenceMapper::toDomain).toList(),
                page.page(), page.size(), result.getTotalElements());
    }

    @Override
    public PageResult<SharedNoteSummary> findShared(UUID viewerId, SharedFilter filter, PageRequest page) {
        Map<String, Object> params = new HashMap<>();
        params.put("viewer", viewerId);
        AudienceScope scope = filter.scope() == null ? AudienceScope.ALL : filter.scope();
        StringBuilder where = new StringBuilder(" WHERE a.usuario_id <> :viewer AND ")
                .append(SharedContentSql.visible(scope, "a.visibilidad", "a.usuario_id", "u"));
        params.putAll(SharedContentSql.params(scope));
        if (filter.authorId() != null) {
            where.append(" AND a.usuario_id = :author");
            params.put("author", filter.authorId());
        }
        return summaries(where, params, filter.catalogSubjectId(), page);
    }

    @Override
    public PageResult<SharedNoteSummary> findOwnShared(UUID userId, Set<Visibility> levels, UUID catalogSubjectId,
                                                       PageRequest page) {
        Map<String, Object> params = new HashMap<>();
        params.put("viewer", userId);
        params.put("levels", SharedContentSql.toDb(levels));
        StringBuilder where = new StringBuilder(" WHERE a.usuario_id = :viewer AND a.visibilidad IN (:levels)"
                + " AND u.nivel_privacidad IN (:levels)");
        return summaries(where, params, catalogSubjectId, page);
    }

    private PageResult<SharedNoteSummary> summaries(StringBuilder where, Map<String, Object> params,
                                                    UUID catalogSubjectId, PageRequest page) {
        if (catalogSubjectId != null) {
            where.append(" AND s.catalogo_asignatura_id = :catalog");
            params.put("catalog", catalogSubjectId);
        }
        long total = jdbc.sql("SELECT count(*)" + SHARED_FROM + where).params(params).query(Long.class).single();
        params.put("limit", page.size());
        params.put("offset", page.offset());
        List<SharedNoteSummary> items = jdbc.sql("SELECT a.id, a.usuario_id, a.titulo, a.visibilidad, a.creado_en,"
                        + " a.actualizado_en, u.nivel_privacidad, SUBSTRING(a.contenido FROM 1 FOR "
                        + SharedNoteSummary.SOURCE_LENGTH + ") AS inicio, " + AUTHOR_COLUMNS + SHARED_FROM + where
                        + " ORDER BY a.actualizado_en DESC, a.id DESC LIMIT :limit OFFSET :offset")
                .params(params)
                .query(NotePersistenceAdapter::mapSummary)
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
    }

    @Override
    public Optional<AuthoredNote> findAuthored(UUID viewerId, UUID noteId) {
        return jdbc.sql("SELECT a.*, " + AUTHOR_COLUMNS + ", "
                        + SharedContentSql.audienceColumns("a.usuario_id", "u") + SHARED_FROM + " WHERE a.id = :id")
                .param("viewer", viewerId)
                .param("id", noteId)
                .query(NotePersistenceAdapter::mapAuthored)
                .optional();
    }

    @Override
    public Note save(Note note) {
        NoteEntity entity = repository.findById(note.id()).orElseGet(NoteEntity::new);
        AcademicPersistenceMapper.copy(note, entity);
        return AcademicPersistenceMapper.toDomain(repository.save(entity));
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
    }

    private static SharedNoteSummary mapSummary(ResultSet rs, int row) throws SQLException {
        Visibility effective = EffectiveVisibility.of(VisibilityDbMapper.toDomain(rs.getString("visibilidad")),
                VisibilityDbMapper.toDomain(rs.getString("nivel_privacidad")));
        Instant updated = instant(rs, "actualizado_en");
        return new SharedNoteSummary(rs.getObject("id", UUID.class), rs.getObject("usuario_id", UUID.class),
                rs.getString("autor_nombre"), rs.getString("autor_avatar"), rs.getObject("catalogo_id", UUID.class),
                rs.getString("catalogo_nombre"), rs.getString("titulo"),
                SharedNoteSummary.excerptOf(rs.getString("inicio")), effective,
                updated == null ? instant(rs, "creado_en") : updated);
    }

    private static AuthoredNote mapAuthored(ResultSet rs, int row) throws SQLException {
        Note note = new Note(rs.getObject("id", UUID.class), rs.getObject("usuario_id", UUID.class),
                rs.getObject("asignatura_id", UUID.class), rs.getString("titulo"), rs.getString("contenido"),
                VisibilityDbMapper.toDomain(rs.getString("visibilidad")), rs.getBoolean("es_nota_rapida"),
                instant(rs, "creado_en"), instant(rs, "actualizado_en"));
        return new AuthoredNote(note, rs.getString("autor_nombre"), rs.getString("autor_avatar"),
                rs.getObject("catalogo_id", UUID.class), rs.getString("catalogo_nombre"), SharedContentSql.audience(rs));
    }

    private static Instant instant(ResultSet rs, String column) throws SQLException {
        Timestamp value = rs.getTimestamp(column);
        return value == null ? null : value.toInstant();
    }
}
