package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.NoteJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.SubjectFileJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.SubjectJpaRepository;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link SubjectRepositoryPort} con JPA. */
@Repository
public class SubjectPersistenceAdapter implements SubjectRepositoryPort {

    private final SubjectJpaRepository subjects;
    private final NoteJpaRepository notes;
    private final SubjectFileJpaRepository files;

    public SubjectPersistenceAdapter(SubjectJpaRepository subjects, NoteJpaRepository notes,
                                     SubjectFileJpaRepository files) {
        this.subjects = subjects;
        this.notes = notes;
        this.files = files;
    }

    @Override
    public Optional<Subject> findByIdAndUser(UUID id, UUID userId) {
        return subjects.findByIdAndUserId(id, userId).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public List<Subject> findByUser(UUID userId, Boolean archived) {
        List<SubjectEntity> rows = archived == null ? subjects.findByUserIdOrderByNameAsc(userId)
                : subjects.findByUserIdAndArchivedOrderByNameAsc(userId, archived);
        return rows.stream().map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public List<Subject> findByUserAndCatalogIds(UUID userId, Collection<UUID> catalogSubjectIds) {
        if (catalogSubjectIds.isEmpty()) {
            return List.of();
        }
        return subjects.findByUserIdAndCatalogSubjectIdIn(userId, catalogSubjectIds).stream()
                .map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public Map<UUID, ContentCount> countContents(UUID userId, Collection<UUID> subjectIds) {
        Map<UUID, ContentCount> result = new HashMap<>();
        if (subjectIds.isEmpty()) {
            return result;
        }
        Map<UUID, Long> noteCounts = toMap(notes.countBySubject(userId, subjectIds));
        Map<UUID, Long> fileCounts = toMap(files.countBySubject(userId, subjectIds));
        for (UUID id : subjectIds) {
            result.put(id, new ContentCount(noteCounts.getOrDefault(id, 0L), fileCounts.getOrDefault(id, 0L)));
        }
        return result;
    }

    @Override
    public Subject save(Subject subject) {
        SubjectEntity entity = subjects.findById(subject.id()).orElseGet(SubjectEntity::new);
        AcademicPersistenceMapper.copy(subject, entity);
        return AcademicPersistenceMapper.toDomain(subjects.save(entity));
    }

    @Override
    public void delete(UUID id) {
        subjects.deleteById(id);
        subjects.flush();
    }

    private static Map<UUID, Long> toMap(List<Object[]> rows) {
        Map<UUID, Long> map = new HashMap<>();
        for (Object[] row : rows) {
            map.put((UUID) row[0], ((Number) row[1]).longValue());
        }
        return map;
    }
}
