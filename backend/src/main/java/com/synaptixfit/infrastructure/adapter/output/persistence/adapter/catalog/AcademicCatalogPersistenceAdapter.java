package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.catalog;

import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.CatalogSubjectDetail;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.catalog.Center;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.University;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.catalog.AcademicCatalogPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.CatalogSubjectEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.CenterEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.DegreeEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.UniversityEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.catalog.CatalogPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.BibliographyJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.CatalogSubjectJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.CenterJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.DegreeJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.EvaluationCriteriaJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.PrerequisiteJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.ProfessorJpaRepository;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.UniversityJpaRepository;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Predicate;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Repository;

/** Implementa {@link AcademicCatalogPort} con JPA (catálogo de solo lectura). */
@Repository
public class AcademicCatalogPersistenceAdapter implements AcademicCatalogPort {

    /** Tildes que se eliminan en BD para comparar nombres sin acentos (unaccent no está garantizado). */
    private static final String ACCENTED = "ÁÉÍÓÚÜÑÀÈÌÒÙáéíóúüñàèìòù";
    private static final String PLAIN = "AEIOUUNAEIOUaeiouunaeiou";
    private static final Sort SUBJECT_ORDER = Sort.by(Sort.Order.asc("curso").nullsLast(),
            Sort.Order.asc("semestre").nullsLast(), Sort.Order.asc("nombre"));

    private final UniversityJpaRepository universities;
    private final CenterJpaRepository centers;
    private final DegreeJpaRepository degrees;
    private final CatalogSubjectJpaRepository subjects;
    private final BibliographyJpaRepository bibliography;
    private final ProfessorJpaRepository professors;
    private final EvaluationCriteriaJpaRepository criteria;
    private final PrerequisiteJpaRepository prerequisites;

    public AcademicCatalogPersistenceAdapter(UniversityJpaRepository universities, CenterJpaRepository centers,
                                             DegreeJpaRepository degrees, CatalogSubjectJpaRepository subjects,
                                             BibliographyJpaRepository bibliography, ProfessorJpaRepository professors,
                                             EvaluationCriteriaJpaRepository criteria,
                                             PrerequisiteJpaRepository prerequisites) {
        this.universities = universities;
        this.centers = centers;
        this.degrees = degrees;
        this.subjects = subjects;
        this.bibliography = bibliography;
        this.professors = professors;
        this.criteria = criteria;
        this.prerequisites = prerequisites;
    }

    @Override
    public List<University> findUniversities(String query) {
        return universities.findAllByOrderByNombreAsc().stream()
                .filter(u -> matches(u.getNombre(), query))
                .map(CatalogPersistenceMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<University> findUniversity(UUID id) {
        return universities.findById(id).map(CatalogPersistenceMapper::toDomain);
    }

    @Override
    public List<Center> findCentersByUniversity(UUID universityId) {
        return centers.findByUniversidadIdOrderByNombreAsc(universityId).stream()
                .map(CatalogPersistenceMapper::toDomain).toList();
    }

    @Override
    public Optional<Center> findCenter(UUID id) {
        return centers.findById(id).map(CatalogPersistenceMapper::toDomain);
    }

    @Override
    public List<Degree> findDegreesByUniversity(UUID universityId, String query) {
        List<CenterEntity> universityCenters = centers.findByUniversidadIdOrderByNombreAsc(universityId);
        if (universityCenters.isEmpty()) {
            return List.of();
        }
        List<DegreeEntity> found = degrees.findByCentroIdInOrderByNombreAsc(
                universityCenters.stream().map(CenterEntity::getId).toList());
        return enrich(found.stream().filter(d -> matches(d.getNombre(), query)).toList());
    }

    @Override
    public List<Degree> findDegreesByCenter(UUID centerId) {
        return enrich(degrees.findByCentroIdInOrderByNombreAsc(List.of(centerId)));
    }

    @Override
    public Optional<Degree> findDegree(UUID id) {
        return degrees.findById(id).map(d -> enrich(List.of(d)).get(0));
    }

    @Override
    public List<Degree> findDegreesByIds(Collection<UUID> ids) {
        return ids.isEmpty() ? List.of() : enrich(degrees.findAllById(ids));
    }

    @Override
    public List<Degree> findDegreesByName(String name) {
        return enrich(degrees.findByNombreIgnoreCase(name.strip()));
    }

    @Override
    public PageResult<CatalogSubject> findSubjects(Collection<UUID> degreeIds, CatalogSubjectFilter filter,
                                                   PageRequest page) {
        Specification<CatalogSubjectEntity> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(root.get("carreraId").in(degreeIds));
            if (filter.course() != null) {
                predicates.add(cb.equal(root.get("curso"), filter.course()));
            }
            if (filter.semester() != null) {
                predicates.add(cb.equal(root.get("semestre"), filter.semester()));
            }
            if (filter.character() != null) {
                Expression<String> character = cb.function("translate", String.class, root.get("caracter"),
                        cb.literal(ACCENTED), cb.literal(PLAIN));
                predicates.add(cb.equal(cb.upper(character), normalize(filter.character()).toUpperCase(Locale.ROOT)));
            }
            if (filter.query() != null) {
                Expression<String> name = cb.function("translate", String.class, root.get("nombre"),
                        cb.literal(ACCENTED), cb.literal(PLAIN));
                predicates.add(cb.like(cb.lower(name), "%" + escapeLike(normalize(filter.query())) + "%", '\\'));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
        Page<CatalogSubjectEntity> result = subjects.findAll(spec,
                org.springframework.data.domain.PageRequest.of(page.page(), page.size(), SUBJECT_ORDER));
        return new PageResult<>(result.getContent().stream().map(CatalogPersistenceMapper::toDomain).toList(),
                page.page(), page.size(), result.getTotalElements());
    }

    @Override
    public Optional<CatalogSubjectDetail> findSubjectDetail(UUID subjectId) {
        return subjects.findById(subjectId).map(s -> new CatalogSubjectDetail(
                CatalogPersistenceMapper.toDomain(s),
                findDegree(s.getCarreraId()).orElse(null),
                bibliography.findByAsignaturaIdOrderByReferenciaAsc(subjectId).stream()
                        .map(b -> b.getReferencia()).toList(),
                professors.findByAsignaturaIdOrderByNombreCompletoAsc(subjectId).stream()
                        .map(p -> p.getNombreCompleto()).toList(),
                criteria.findByAsignaturaId(subjectId).map(CatalogPersistenceMapper::toDomain).orElse(null),
                prerequisites.findByAsignaturaIdOrderByNombreAsignaturaAsc(subjectId).stream()
                        .map(p -> p.getNombreAsignatura()).toList()));
    }

    /** Añade a cada carrera el nombre de su centro y de su universidad (dos consultas en bloque). */
    private List<Degree> enrich(List<DegreeEntity> found) {
        if (found.isEmpty()) {
            return List.of();
        }
        Set<UUID> centerIds = found.stream().map(DegreeEntity::getCentroId).collect(Collectors.toSet());
        Map<UUID, CenterEntity> centerById = centers.findAllById(centerIds).stream()
                .collect(Collectors.toMap(CenterEntity::getId, Function.identity()));
        Set<UUID> universityIds = centerById.values().stream().map(CenterEntity::getUniversidadId)
                .collect(Collectors.toSet());
        Map<UUID, UniversityEntity> universityById = universities.findAllById(universityIds).stream()
                .collect(Collectors.toMap(UniversityEntity::getId, Function.identity()));
        return found.stream().map(d -> {
            CenterEntity center = centerById.get(d.getCentroId());
            UniversityEntity university = center == null ? null : universityById.get(center.getUniversidadId());
            return CatalogPersistenceMapper.toDomain(d, center, university);
        }).toList();
    }

    private static boolean matches(String name, String query) {
        return query == null || normalize(name).contains(normalize(query));
    }

    /** Minúsculas y sin tildes. */
    static String normalize(String text) {
        return Normalizer.normalize(text.strip(), Normalizer.Form.NFD).replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT);
    }

    private static String escapeLike(String text) {
        return text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }
}
