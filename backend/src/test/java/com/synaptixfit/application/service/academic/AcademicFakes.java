package com.synaptixfit.application.service.academic;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.CatalogSubject;
import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionAttempt;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.ReviewRecord;
import com.synaptixfit.domain.model.academic.SharedNote;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.academic.SubjectSemester;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TestSession;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.ExperienceChange;
import com.synaptixfit.domain.port.output.academic.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.port.output.academic.PhysicalLoadPort;
import com.synaptixfit.domain.port.output.academic.QuestionAttemptRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.ReviewRecordRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectSemesterRepositoryPort;
import com.synaptixfit.domain.port.output.academic.TestSessionRepositoryPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Predicate;

/** Dobles en memoria de los puertos del módulo académico (sin Spring ni base de datos). */
final class AcademicFakes {

    static final Instant NOW = Instant.parse("2026-10-18T10:00:00Z");
    static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);

    final Map<UUID, Subject> subjectStore = new LinkedHashMap<>();
    final Map<UUID, SubjectSemester> semesterStore = new LinkedHashMap<>();
    final Map<UUID, Note> noteStore = new LinkedHashMap<>();
    final Map<UUID, SubjectFile> fileStore = new LinkedHashMap<>();
    final Map<UUID, AiDocument> docStore = new LinkedHashMap<>();
    final Map<UUID, StudyMaterial> materialStore = new LinkedHashMap<>();
    final List<ReviewRecord> reviewStore = new ArrayList<>();
    final Map<UUID, QuestionBank> bankStore = new LinkedHashMap<>();
    final Map<UUID, Question> questionStore = new LinkedHashMap<>();
    final List<QuestionAttempt> attemptStore = new ArrayList<>();
    final Map<UUID, TestSession> sessionStore = new LinkedHashMap<>();
    final List<CatalogSubject> catalog = new ArrayList<>();
    final List<DomainEvent> events = new ArrayList<>();
    final Map<UUID, Integer> xp = new HashMap<>();
    final List<String> deletedObjects = new ArrayList<>();
    final Map<String, byte[]> objects = new HashMap<>();
    /** Historial de carga física que devuelve el puerto (el servicio calcula hoy y el máximo). */
    final List<PhysicalLoadHistory.Entry> loadHistory = new ArrayList<>();

    final SubjectRepositoryPort subjects = new SubjectRepositoryPort() {
        public Optional<Subject> findByIdAndUser(UUID id, UUID userId) {
            return Optional.ofNullable(subjectStore.get(id)).filter(s -> s.userId().equals(userId));
        }
        public List<Subject> findByUser(UUID userId, Boolean archived) {
            return subjectStore.values().stream().filter(s -> s.userId().equals(userId))
                    .filter(s -> archived == null || s.archived() == archived)
                    .sorted(Comparator.comparing(Subject::name)).toList();
        }
        public List<Subject> findByUserAndCatalogIds(UUID userId, Collection<UUID> ids) {
            return subjectStore.values().stream().filter(s -> s.userId().equals(userId))
                    .filter(s -> s.catalogSubjectId() != null && ids.contains(s.catalogSubjectId())).toList();
        }
        public Map<UUID, ContentCount> countContents(UUID userId, Collection<UUID> ids) {
            Map<UUID, ContentCount> map = new HashMap<>();
            for (UUID id : ids) {
                long n = noteStore.values().stream().filter(x -> id.equals(x.subjectId())).count();
                long f = fileStore.values().stream().filter(x -> id.equals(x.subjectId())).count();
                map.put(id, new ContentCount(n, f));
            }
            return map;
        }
        public Subject save(Subject s) { subjectStore.put(s.id(), s); return s; }
        public void delete(UUID id) {
            subjectStore.remove(id);
            materialStore.values().removeIf(m -> m.subjectId().equals(id));
        }
    };

    final SubjectSemesterRepositoryPort semesters = new SubjectSemesterRepositoryPort() {
        public List<SubjectSemester> findByUser(UUID userId) {
            return semesterStore.values().stream().filter(s -> s.userId().equals(userId)).toList();
        }
        public Optional<SubjectSemester> findBySubject(UUID userId, UUID subjectId) {
            return semesterStore.values().stream()
                    .filter(s -> s.userId().equals(userId) && s.subjectId().equals(subjectId)).findFirst();
        }
        public SubjectSemester save(SubjectSemester a) { semesterStore.put(a.id(), a); return a; }
        public void deleteBySubject(UUID userId, UUID subjectId) {
            semesterStore.values().removeIf(s -> s.userId().equals(userId) && s.subjectId().equals(subjectId));
        }
    };

    final AcademicCatalogPort catalogPort = new AcademicCatalogPort() {
        public List<CatalogSubject> findByIds(Collection<UUID> ids) {
            return catalog.stream().filter(c -> ids.contains(c.id())).toList();
        }
        public List<CatalogSubject> findForUserDegrees(UUID userId) {
            return List.copyOf(catalog);
        }
    };

    final NoteRepositoryPort notes = new NoteRepositoryPort() {
        public Optional<Note> findByIdAndUser(UUID id, UUID userId) {
            return Optional.ofNullable(noteStore.get(id)).filter(n -> n.userId().equals(userId));
        }
        public PageResult<Note> findByUser(UUID userId, Filter f, PageRequest page) {
            Predicate<Note> p = n -> n.userId().equals(userId)
                    && (f.subjectId() == null || f.subjectId().equals(n.subjectId()))
                    && (!f.quickOnly() || n.quickNote())
                    && (!f.unassignedOnly() || n.subjectId() == null);
            List<Note> all = noteStore.values().stream().filter(p).toList();
            return new PageResult<>(all.stream().skip(page.offset()).limit(page.size()).toList(), page.page(),
                    page.size(), all.size());
        }
        public PageResult<SharedNote> findSharedWith(UUID viewerId, PageRequest page) {
            return new PageResult<>(List.of(), page.page(), page.size(), 0);
        }
        public List<Note> findNonPrivateByUser(UUID userId) {
            return noteStore.values().stream()
                    .filter(n -> n.userId().equals(userId) && n.visibility() != Visibility.PRIVATE).toList();
        }
        public Note save(Note n) { noteStore.put(n.id(), n); return n; }
        public void delete(UUID id) { noteStore.remove(id); }
    };

    final SubjectFileRepositoryPort files = new SubjectFileRepositoryPort() {
        public Optional<SubjectFile> findByIdAndUser(UUID id, UUID userId) {
            return Optional.ofNullable(fileStore.get(id)).filter(f -> f.userId().equals(userId));
        }
        public List<SubjectFile> findBySubject(UUID userId, UUID subjectId) {
            return fileStore.values().stream().filter(f -> f.userId().equals(userId) && f.subjectId().equals(subjectId))
                    .toList();
        }
        public boolean existsByObjectKey(String key) {
            return fileStore.values().stream().anyMatch(f -> f.objectKey().equals(key));
        }
        public SubjectFile save(SubjectFile f) { fileStore.put(f.id(), f); return f; }
        public void delete(UUID id) { fileStore.remove(id); }
    };

    final AiDocumentRepositoryPort aiDocuments = new AiDocumentRepositoryPort() {
        public Optional<AiDocument> find(UUID userId, AiDocumentSource source, String sourceId, AiDocumentType type) {
            return docStore.values().stream().filter(d -> d.userId().equals(userId) && d.source() == source
                    && d.sourceId().equals(sourceId) && d.type() == type).findFirst();
        }
        public Set<AiDocumentType> typesFor(UUID userId, AiDocumentSource source, String sourceId) {
            Set<AiDocumentType> set = EnumSet.noneOf(AiDocumentType.class);
            docStore.values().stream().filter(d -> d.userId().equals(userId) && d.source() == source
                    && d.sourceId().equals(sourceId)).forEach(d -> set.add(d.type()));
            return set;
        }
        public AiDocument save(AiDocument d) { docStore.put(d.id(), d); return d; }
        public void delete(UUID id) { docStore.remove(id); }
        public void deleteBySource(UUID userId, AiDocumentSource source, String sourceId) {
            docStore.values().removeIf(d -> d.userId().equals(userId) && d.source() == source
                    && d.sourceId().equals(sourceId));
        }
    };

    /** Codificación trivial: guarda el objeto en memoria y devuelve su clave. */
    final StudyDocumentCodecPort codec = new StudyDocumentCodecPort() {
        private final Map<String, Object> encoded = new HashMap<>();
        private String put(Object o) {
            String key = "enc:" + UUID.randomUUID();
            encoded.put(key, o);
            return key;
        }
        public String encodeMindMap(MindMap m) { return put(m); }
        public MindMap decodeMindMap(String c) { return (MindMap) encoded.get(c); }
        public String encodeTeachingGuide(TeachingGuide g) { return put(g); }
        public TeachingGuide decodeTeachingGuide(String c) { return (TeachingGuide) encoded.get(c); }
        public String encodePractice(PracticeMarker p) { return put(p); }
        public PracticeMarker decodePractice(String c) { return (PracticeMarker) encoded.get(c); }
    };

    final StudyMaterialRepositoryPort materials = new StudyMaterialRepositoryPort() {
        public Optional<StudyMaterial> findByIdAndUser(UUID id, UUID userId) {
            return Optional.ofNullable(materialStore.get(id)).filter(m -> m.userId().equals(userId));
        }
        public Optional<StudyMaterial> findByOrigin(UUID userId, StudySourceType type, UUID originId) {
            return materialStore.values().stream().filter(m -> m.userId().equals(userId) && m.originType() == type
                    && m.originId().equals(originId)).findFirst();
        }
        public List<StudyMaterial> findByUser(UUID userId, UUID subjectId) {
            return materialStore.values().stream().filter(m -> m.userId().equals(userId)
                    && (subjectId == null || m.subjectId().equals(subjectId))).toList();
        }
        public List<StudyMaterial> findDue(UUID userId, Instant now, int limit) {
            return materialStore.values().stream().filter(m -> m.userId().equals(userId) && m.isDue(now))
                    .sorted(Comparator.comparing(StudyMaterial::nextReviewAt)).limit(limit).toList();
        }
        public StudyMaterial save(StudyMaterial m) { materialStore.put(m.id(), m); return m; }
        public void delete(UUID id) {
            materialStore.remove(id);
            List<UUID> banks = bankStore.values().stream().filter(b -> b.materialId().equals(id))
                    .map(QuestionBank::id).toList();
            banks.forEach(bankStore::remove);
            questionStore.values().removeIf(q -> banks.contains(q.bankId()));
        }
    };

    final ReviewRecordRepositoryPort reviews = new ReviewRecordRepositoryPort() {
        public ReviewRecord save(ReviewRecord r) { reviewStore.add(r); return r; }
        public List<ReviewRecord> findByMaterial(UUID id) {
            return reviewStore.stream().filter(r -> r.studyMaterialId().equals(id)).toList();
        }
    };

    final PhysicalLoadPort physicalLoad = new PhysicalLoadPort() {
        public List<PhysicalLoadHistory.Entry> history(UUID userId) { return loadHistory; }
    };

    final QuestionBankRepositoryPort banks = new QuestionBankRepositoryPort() {
        public Optional<QuestionBank> findByIdAndUser(UUID id, UUID userId) {
            return Optional.ofNullable(bankStore.get(id)).filter(b -> b.userId().equals(userId));
        }
        public Optional<QuestionBank> findByMaterial(UUID materialId) {
            return bankStore.values().stream().filter(b -> b.materialId().equals(materialId)).findFirst();
        }
        public QuestionBank save(QuestionBank b) { bankStore.put(b.id(), b); return b; }
        public void replaceQuestions(UUID bankId, List<Question> list) {
            questionStore.values().removeIf(q -> q.bankId().equals(bankId));
            list.forEach(q -> questionStore.put(q.id(), q));
        }
        public List<Question> findQuestions(UUID bankId) {
            return questionStore.values().stream().filter(q -> q.bankId().equals(bankId))
                    .sorted(Comparator.comparingInt(Question::order)).toList();
        }
        public List<Question> findQuestionsByIds(Collection<UUID> ids) {
            return questionStore.values().stream().filter(q -> ids.contains(q.id())).toList();
        }
        public Optional<Question> findQuestionOfUser(UUID questionId, UUID userId) {
            return Optional.ofNullable(questionStore.get(questionId))
                    .filter(q -> bankStore.get(q.bankId()).userId().equals(userId));
        }
    };

    final QuestionAttemptRepositoryPort attempts = new QuestionAttemptRepositoryPort() {
        public QuestionAttempt save(QuestionAttempt a) { attemptStore.add(a); return a; }
        public List<QuestionAttempt> findByUserAndQuestions(UUID userId, Collection<UUID> ids) {
            return attemptStore.stream().filter(a -> a.userId().equals(userId) && ids.contains(a.questionId()))
                    .toList();
        }
    };

    final TestSessionRepositoryPort sessions = new TestSessionRepositoryPort() {
        public Optional<TestSession> findByIdAndUser(UUID id, UUID userId) {
            return Optional.ofNullable(sessionStore.get(id)).filter(s -> s.userId().equals(userId));
        }
        public Optional<TestSession> findActive(UUID userId, UUID materialId) {
            return sessionStore.values().stream().filter(s -> s.userId().equals(userId)
                    && s.materialId().equals(materialId) && s.status() == TestSessionStatus.IN_PROGRESS).findFirst();
        }
        public List<TestSession> findByUser(UUID userId, UUID materialId, TestSessionStatus status) {
            return sessionStore.values().stream().filter(s -> s.userId().equals(userId)
                    && (materialId == null || s.materialId().equals(materialId))
                    && (status == null || s.status() == status)).toList();
        }
        public TestSession save(TestSession s) { sessionStore.put(s.id(), s); return s; }
    };

    final FileStoragePort storage = new FileStoragePort() {
        public PresignedUrl presignUpload(String key, String contentType, long size, Duration validity) {
            return new PresignedUrl("https://storage.test/" + key, "PUT", Map.of("Content-Type", contentType),
                    NOW.plus(validity));
        }
        public PresignedUrl presignDownload(String key, Duration validity) {
            return new PresignedUrl("https://storage.test/" + key + "?sig", "GET", Map.of(), NOW.plus(validity));
        }
        public byte[] download(String key) { return objects.getOrDefault(key, new byte[]{1, 2, 3}); }
        public void delete(String key) { deletedObjects.add(key); }
        public String publicUrl(String key) { return null; }
    };

    final AwardExperienceUseCase award = (userId, amount) -> {
        xp.merge(userId, amount, Integer::sum);
        return new ExperienceChange(1, xp.get(userId), 0, amount);
    };

    // ------------------------------------------------------------------ datos de prueba

    Subject subject(UUID userId, String name) {
        return subjects.save(Subject.builder().id(UUID.randomUUID()).userId(userId).name(name).createdAt(NOW).build());
    }

    Note note(UUID userId, UUID subjectId, String title) {
        return notes.save(Note.create(userId, subjectId, title, "contenido de " + title, null, false, NOW));
    }

    SubjectFile file(UUID userId, UUID subjectId, String name, String mime) {
        return files.save(new SubjectFile(UUID.randomUUID(), userId, subjectId, name,
                "usuarios/" + userId + "/asignaturas/" + subjectId + "/archivos/1_" + name, "k", 10, mime, NOW));
    }

    StudyMaterial material(UUID userId, UUID subjectId, UUID noteId) {
        return materials.save(StudyMaterial.create(userId, subjectId, StudySourceType.NOTE, noteId, "Material", NOW));
    }
}
