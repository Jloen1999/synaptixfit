package com.synaptixfit.support;

import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.CatalogSubjectDetail;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.catalog.Center;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.SubjectLink;
import com.synaptixfit.domain.model.catalog.University;
import com.synaptixfit.domain.model.catalog.UserDegreeLink;
import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.model.profile.GoalHistoryEntry;
import com.synaptixfit.domain.model.profile.WeightRecord;
import com.synaptixfit.domain.model.profile.WellnessProfile;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.catalog.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.catalog.UserDegreeRepositoryPort;
import com.synaptixfit.domain.port.output.catalog.UserSubjectLinksPort;
import com.synaptixfit.domain.port.output.profile.AcademicProfileRepositoryPort;
import com.synaptixfit.domain.port.output.profile.GoalHistoryRepositoryPort;
import com.synaptixfit.domain.port.output.profile.WeightHistoryRepositoryPort;
import com.synaptixfit.domain.port.output.profile.WellnessProfileRepositoryPort;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/** Dobles en memoria de los puertos del módulo de perfil y catálogo. */
public final class ProfileTestDoubles {

    private ProfileTestDoubles() {
    }

    public static final class Wellness implements WellnessProfileRepositoryPort {
        public final Map<UUID, WellnessProfile> byUser = new HashMap<>();
        public int saves;

        public Optional<WellnessProfile> findByUserId(UUID userId) { return Optional.ofNullable(byUser.get(userId)); }

        public WellnessProfile save(WellnessProfile p) { saves++; byUser.put(p.userId(), p); return p; }
    }

    public static final class Weights implements WeightHistoryRepositoryPort {
        public final List<WeightRecord> records = new ArrayList<>();

        public WeightRecord append(WeightRecord r) { records.add(r); return r; }

        public List<WeightRecord> findByUser(UUID userId, Instant from, Instant to) {
            return records.stream()
                    .filter(r -> r.userId().equals(userId) && !r.recordedAt().isBefore(from) && r.recordedAt().isBefore(to))
                    .sorted(Comparator.comparing(WeightRecord::recordedAt))
                    .toList();
        }
    }

    public static final class Goals implements GoalHistoryRepositoryPort {
        public final Map<UUID, GoalHistoryEntry> byId = new LinkedHashMap<>();

        public Optional<GoalHistoryEntry> findOpen(UUID userId) {
            return byId.values().stream().filter(e -> e.userId().equals(userId) && e.isOpen())
                    .max(Comparator.comparing(GoalHistoryEntry::createdAt));
        }

        public GoalHistoryEntry save(GoalHistoryEntry e) { byId.put(e.id(), e); return e; }

        public List<GoalHistoryEntry> findByUser(UUID userId) {
            List<GoalHistoryEntry> list = new ArrayList<>(byId.values().stream()
                    .filter(e -> e.userId().equals(userId)).toList());
            java.util.Collections.reverse(list);
            return list;
        }
    }

    public static final class Academic implements AcademicProfileRepositoryPort {
        public final Map<UUID, AcademicProfile> byUser = new HashMap<>();

        public Optional<AcademicProfile> findByUserId(UUID userId) { return Optional.ofNullable(byUser.get(userId)); }

        public AcademicProfile save(AcademicProfile p) { byUser.put(p.userId(), p); return p; }
    }

    public static final class UserDegrees implements UserDegreeRepositoryPort {
        public final List<Object[]> rows = new ArrayList<>();

        public List<UserDegreeLink> findByUser(UUID userId) {
            return rows.stream().filter(r -> r[0].equals(userId))
                    .map(r -> new UserDegreeLink((UUID) r[1], (Instant) r[2])).toList();
        }

        public boolean exists(UUID userId, UUID degreeId) {
            return rows.stream().anyMatch(r -> r[0].equals(userId) && r[1].equals(degreeId));
        }

        public void link(UUID userId, UUID degreeId, Instant when) { rows.add(new Object[]{userId, degreeId, when}); }

        public void unlink(UUID userId, UUID degreeId) {
            rows.removeIf(r -> r[0].equals(userId) && r[1].equals(degreeId));
        }
    }

    public static final class SubjectLinks implements UserSubjectLinksPort {
        public final Map<UUID, SubjectLink> byCatalogId = new HashMap<>();

        public Map<UUID, SubjectLink> findByCatalogSubjects(UUID userId, Collection<UUID> ids) {
            Map<UUID, SubjectLink> result = new HashMap<>();
            ids.forEach(id -> {
                if (byCatalogId.containsKey(id)) {
                    result.put(id, byCatalogId.get(id));
                }
            });
            return result;
        }
    }

    /** Catálogo en memoria con una universidad, un centro y las carreras y asignaturas que se añadan. */
    public static final class Catalog implements AcademicCatalogPort {
        public final University university = new University(UUID.randomUUID(), "Universidad de Granada");
        public final Center center = new Center(UUID.randomUUID(), university.id(), "ETSIIT");
        public final List<Degree> degrees = new ArrayList<>();
        public final List<CatalogSubject> subjects = new ArrayList<>();

        public Degree addDegree(String name) {
            Degree d = new Degree(UUID.randomUUID(), name, 240, 6000, center.id(), center.name(), university.id(),
                    university.name());
            degrees.add(d);
            return d;
        }

        public CatalogSubject addSubject(Degree degree, String name, int course, int semester) {
            CatalogSubject s = new CatalogSubject(UUID.randomUUID(), degree.id(), name, course, semester, "OBLIGATORIA",
                    6.0, 150, null, null, null);
            subjects.add(s);
            return s;
        }

        public List<University> findUniversities(String query) { return List.of(university); }

        public Optional<University> findUniversity(UUID id) {
            return university.id().equals(id) ? Optional.of(university) : Optional.empty();
        }

        public List<Center> findCentersByUniversity(UUID universityId) {
            return university.id().equals(universityId) ? List.of(center) : List.of();
        }

        public Optional<Center> findCenter(UUID id) {
            return center.id().equals(id) ? Optional.of(center) : Optional.empty();
        }

        public List<Degree> findDegreesByUniversity(UUID universityId, String query) {
            return university.id().equals(universityId) ? List.copyOf(degrees) : List.of();
        }

        public List<Degree> findDegreesByCenter(UUID centerId) {
            return center.id().equals(centerId) ? List.copyOf(degrees) : List.of();
        }

        public Optional<Degree> findDegree(UUID id) {
            return degrees.stream().filter(d -> d.id().equals(id)).findFirst();
        }

        public List<Degree> findDegreesByIds(Collection<UUID> ids) {
            return degrees.stream().filter(d -> ids.contains(d.id())).toList();
        }

        public List<Degree> findDegreesByName(String name) {
            return degrees.stream().filter(d -> d.name().equalsIgnoreCase(name)).toList();
        }

        public PageResult<CatalogSubject> findSubjects(Collection<UUID> degreeIds, CatalogSubjectFilter filter,
                                                       PageRequest page) {
            List<CatalogSubject> matching = subjects.stream()
                    .filter(s -> degreeIds.contains(s.degreeId()))
                    .filter(s -> filter.course() == null || Objects.equals(filter.course(), s.course()))
                    .toList();
            List<CatalogSubject> slice = matching.stream().skip(page.offset()).limit(page.size()).toList();
            return new PageResult<>(slice, page.page(), page.size(), matching.size());
        }

        public Optional<CatalogSubjectDetail> findSubjectDetail(UUID subjectId) {
            return subjects.stream().filter(s -> s.id().equals(subjectId)).findFirst()
                    .map(s -> new CatalogSubjectDetail(s, findDegree(s.degreeId()).orElse(null), List.of("Libro"),
                            List.of(), null, List.of()));
        }
    }
}
