package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.SharedNote;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.NoteEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.NoteJpaRepository;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link NoteRepositoryPort}: JPA para los apuntes propios y SQL de solo lectura
 * (usuarios y amistades, de otros módulos) para los apuntes compartidos.
 */
@Repository
public class NotePersistenceAdapter implements NoteRepositoryPort {

    private static final String SHARED_FILTER = """
            FROM apuntes a JOIN usuarios u ON u.id = a.usuario_id
            WHERE a.usuario_id <> :viewer
              AND u.eliminado_en IS NULL AND u.is_shadowbanned = false
              AND (a.visibilidad = 'public'
                   OR (a.visibilidad = 'friends' AND EXISTS (
                        SELECT 1 FROM amistades f
                        WHERE f.estado = 'aceptada'
                          AND ((f.solicitante_id = :viewer AND f.receptor_id = a.usuario_id)
                            OR (f.receptor_id = :viewer AND f.solicitante_id = a.usuario_id)))))
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
    public PageResult<SharedNote> findSharedWith(UUID viewerId, PageRequest page) {
        long total = jdbc.sql("SELECT count(*) " + SHARED_FILTER).param("viewer", viewerId)
                .query(Long.class).single();
        var items = jdbc.sql("SELECT a.*, u.nombre_completo AS autor_nombre, u.url_avatar AS autor_avatar "
                        + SHARED_FILTER + " ORDER BY a.actualizado_en DESC LIMIT :limit OFFSET :offset")
                .param("viewer", viewerId)
                .param("limit", page.size())
                .param("offset", page.offset())
                .query(NotePersistenceAdapter::mapShared)
                .list();
        return new PageResult<>(items, page.page(), page.size(), total);
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

    private static SharedNote mapShared(ResultSet rs, int row) throws SQLException {
        Timestamp created = rs.getTimestamp("creado_en");
        Timestamp updated = rs.getTimestamp("actualizado_en");
        Note note = new Note(rs.getObject("id", UUID.class), rs.getObject("usuario_id", UUID.class),
                rs.getObject("asignatura_id", UUID.class), rs.getString("titulo"), rs.getString("contenido"),
                VisibilityDbMapper.toDomain(rs.getString("visibilidad")), rs.getBoolean("es_nota_rapida"),
                created.toInstant(), updated == null ? null : updated.toInstant());
        return new SharedNote(note, rs.getString("autor_nombre"), rs.getString("autor_avatar"));
    }
}
