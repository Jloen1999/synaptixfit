package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.AssignSubjectSemesterUseCase;
import com.synaptixfit.application.port.input.academic.CreateSubjectUseCase;
import com.synaptixfit.application.port.input.academic.CreateSubjectsFromCatalogUseCase;
import com.synaptixfit.application.port.input.academic.DeleteSubjectUseCase;
import com.synaptixfit.application.port.input.academic.GetSubjectUseCase;
import com.synaptixfit.application.port.input.academic.ListCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectSemestersUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectsUseCase;
import com.synaptixfit.application.port.input.academic.RemoveSubjectSemesterUseCase;
import com.synaptixfit.application.port.input.academic.UpdateSubjectUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.StorageUnavailableException;
import com.synaptixfit.domain.exception.academic.CatalogSubjectNotFoundException;
import com.synaptixfit.domain.exception.academic.SubjectSemesterNotFoundException;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.CatalogSubject;
import com.synaptixfit.domain.model.academic.CatalogSubjectSelection;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.academic.SubjectSemester;
import com.synaptixfit.domain.model.academic.SubjectAgenda;
import com.synaptixfit.domain.model.academic.SubjectSummary;
import com.synaptixfit.domain.port.output.academic.SubjectAgendaPort;
import com.synaptixfit.domain.port.output.academic.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectSemesterRepositoryPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.event.academic.SubjectDeleted;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import com.synaptixfit.domain.model.insights.TimeZones;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Asignaturas del usuario, creación desde el catálogo y asignación a curso y semestre. */
public class SubjectService implements ListSubjectsUseCase, GetSubjectUseCase, CreateSubjectUseCase,
        UpdateSubjectUseCase, DeleteSubjectUseCase, ListCatalogSubjectsUseCase, CreateSubjectsFromCatalogUseCase,
        ListSubjectSemestersUseCase, AssignSubjectSemesterUseCase, RemoveSubjectSemesterUseCase {

    static final int MAX_CATALOG_BATCH = 50;
    /** Ventana para buscar la próxima clase: un cuatrimestre con vacaciones de por medio. */
    static final int CLASS_LOOKAHEAD_DAYS = 60;

    private final SubjectRepositoryPort subjects;
    private final SubjectSemesterRepositoryPort semesters;
    private final AcademicCatalogPort catalog;
    private final SubjectFileRepositoryPort files;
    private final AiDocumentRepositoryPort aiDocuments;
    private final FileStoragePort storage;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final AcademicLookups lookups;
    private final SubjectAgendaPort agenda;
    private final ZoneId zone;

    public SubjectService(SubjectRepositoryPort subjects, SubjectSemesterRepositoryPort semesters,
                          AcademicCatalogPort catalog, SubjectFileRepositoryPort files,
                          AiDocumentRepositoryPort aiDocuments, FileStoragePort storage,
                          DomainEventPublisherPort events, Clock clock) {
        this(subjects, semesters, catalog, files, aiDocuments, storage, events, clock, null, ZoneId.of("UTC"));
    }

    /** Con la agenda de cada asignatura (próxima clase, días de clase y próxima entrega, ADR 0036). */
    public SubjectService(SubjectRepositoryPort subjects, SubjectSemesterRepositoryPort semesters,
                          AcademicCatalogPort catalog, SubjectFileRepositoryPort files,
                          AiDocumentRepositoryPort aiDocuments, FileStoragePort storage,
                          DomainEventPublisherPort events, Clock clock, SubjectAgendaPort agenda, ZoneId zone) {
        this.agenda = agenda;
        this.zone = zone;
        this.subjects = subjects;
        this.events = events;
        this.semesters = semesters;
        this.catalog = catalog;
        this.files = files;
        this.aiDocuments = aiDocuments;
        this.storage = storage;
        this.clock = clock;
        this.lookups = new AcademicLookups(subjects, null, null, null, null, clock);
    }

    @Override
    public List<SubjectSummary> listSubjects(UUID userId, Boolean archived, String zone) {
        return summarize(userId, subjects.findByUser(userId, archived), zone);
    }

    @Override
    public SubjectSummary getSubject(UUID userId, UUID subjectId, String zone) {
        return summarize(userId, List.of(lookups.subject(userId, subjectId)), zone).getFirst();
    }

    @Override
    public Subject createSubject(CreateSubjectUseCase.Command c) {
        Subject subject = Subject.builder()
                .id(UUID.randomUUID())
                .userId(c.userId())
                .name(c.name())
                .code(c.code())
                .description(c.description())
                .credits(c.credits() == null ? Subject.DEFAULT_CREDITS : c.credits())
                .perceivedDifficulty(c.perceivedDifficulty() == null ? Subject.DEFAULT_DIFFICULTY
                        : c.perceivedDifficulty())
                .priority(c.priority())
                .nextAssessmentAt(c.nextAssessmentAt())
                .teacher(c.teacher())
                .room(c.room())
                .icsUrl(c.icsUrl())
                .createdAt(clock.instant())
                .build();
        return subjects.save(subject);
    }

    @Override
    public SubjectSummary updateSubject(UpdateSubjectUseCase.Command c) {
        Subject s = lookups.subject(c.userId(), c.subjectId());
        if (c.name() != null) {
            s.rename(c.name());
        }
        if (c.code() != null) {
            s.changeCode(c.code());
        }
        if (c.description() != null) {
            s.changeDescription(c.description());
        }
        if (c.credits() != null) {
            s.changeCredits(c.credits());
        }
        if (c.perceivedDifficulty() != null) {
            s.changePerceivedDifficulty(c.perceivedDifficulty());
        }
        if (c.priority() != null) {
            s.changePriority(c.priority());
        }
        if (c.clearNextAssessment()) {
            s.scheduleNextAssessment(null);
        } else if (c.nextAssessmentAt() != null) {
            s.scheduleNextAssessment(c.nextAssessmentAt());
        }
        if (c.room() != null) {
            s.changeRoom(c.room());
        }
        if (c.teacher() != null) {
            s.changeTeacher(c.teacher());
        }
        if (c.icsUrl() != null) {
            s.changeIcsUrl(c.icsUrl());
        }
        if (Boolean.TRUE.equals(c.archived())) {
            s.archive();
        } else if (Boolean.FALSE.equals(c.archived())) {
            s.unarchive();
        }
        return summarize(c.userId(), List.of(subjects.save(s)), c.zone()).getFirst();
    }

    @Override
    public void deleteSubject(UUID userId, UUID subjectId) {
        Subject s = lookups.subject(userId, subjectId);
        for (SubjectFile f : files.findBySubject(userId, s.id())) {
            deleteObjectQuietly(f.objectKey());
            aiDocuments.deleteBySource(userId, AiDocumentSource.FILE, f.id().toString());
            files.delete(f.id());
        }
        aiDocuments.deleteBySource(userId, AiDocumentSource.SUBJECT, s.id().toString());
        semesters.deleteBySubject(userId, s.id());
        // Antes del borrado físico: los bloques del calendario caerían en cascada sin restar su XP ni
        // avisar a retos e indicadores; el planificador los borra por su caso de uso al oír el evento.
        events.publish(new SubjectDeleted(userId, s.id(), clock.instant()));
        // Materiales, bancos y sesiones caen en cascada (FK); los apuntes quedan sin asignatura.
        subjects.delete(s.id());
    }

    @Override
    public List<CatalogSubjectSelection> listCatalogSubjects(UUID userId) {
        List<CatalogSubject> available = catalog.findForUserDegrees(userId);
        if (available.isEmpty()) {
            return List.of();
        }
        Map<UUID, Subject> linked = subjects.findByUserAndCatalogIds(userId,
                        available.stream().map(CatalogSubject::id).toList()).stream()
                .collect(Collectors.toMap(Subject::catalogSubjectId, Function.identity(), (a, b) -> a));
        return available.stream().map(cs -> {
            Subject s = linked.get(cs.id());
            return new CatalogSubjectSelection(cs, s == null ? null : s.id(), s != null && !s.archived());
        }).toList();
    }

    @Override
    public List<Subject> createFromCatalog(UUID userId, List<UUID> catalogSubjectIds) {
        Guard.notNull(catalogSubjectIds, "catalogSubjectIds");
        List<UUID> ids = new ArrayList<>(new LinkedHashSet<>(catalogSubjectIds));
        if (ids.isEmpty() || ids.size() > MAX_CATALOG_BATCH) {
            throw new FieldValidationException("catalogSubjectIds",
                    "INVALID_LENGTH", "between 1 and " + MAX_CATALOG_BATCH + " catalog subjects are required");
        }
        Map<UUID, CatalogSubject> found = catalog.findByIds(ids).stream()
                .collect(Collectors.toMap(CatalogSubject::id, Function.identity()));
        for (UUID id : ids) {
            if (!found.containsKey(id)) {
                throw new CatalogSubjectNotFoundException(id);
            }
        }
        Map<UUID, Subject> existing = subjects.findByUserAndCatalogIds(userId, ids).stream()
                .collect(Collectors.toMap(Subject::catalogSubjectId, Function.identity(), (a, b) -> a));
        List<Subject> result = new ArrayList<>();
        for (UUID id : ids) {
            Subject current = existing.get(id);
            if (current != null) {
                // Ya enlazada: se reactiva en lugar de duplicarla (comportamiento del selector antiguo).
                if (current.archived()) {
                    current.unarchive();
                    current = subjects.save(current);
                }
                result.add(current);
                continue;
            }
            CatalogSubject cs = found.get(id);
            result.add(subjects.save(Subject.builder()
                    .id(UUID.randomUUID())
                    .userId(userId)
                    .name(cs.name())
                    .description(cs.describe())
                    .credits(cs.creditsForSubject())
                    .catalogSubjectId(cs.id())
                    .createdAt(clock.instant())
                    .build()));
        }
        return result;
    }

    @Override
    public List<SubjectSemester> listSemesters(UUID userId) {
        return semesters.findByUser(userId);
    }

    @Override
    public SubjectSemester assignSemester(UUID userId, UUID subjectId, int course, int semester) {
        Subject s = lookups.subject(userId, subjectId);
        SubjectSemester assignment = semesters.findBySubject(userId, s.id())
                .map(a -> a.reassign(course, semester))
                .orElseGet(() -> new SubjectSemester(UUID.randomUUID(), userId, s.id(), course, semester,
                        clock.instant()));
        return semesters.save(assignment);
    }

    @Override
    public void removeSemester(UUID userId, UUID subjectId) {
        Subject s = lookups.subject(userId, subjectId);
        if (semesters.findBySubject(userId, s.id()).isEmpty()) {
            throw new SubjectSemesterNotFoundException(subjectId);
        }
        semesters.deleteBySubject(userId, s.id());
    }

    /**
     * Cuenta el contenido y arma la agenda de cada asignatura. Los días de clase y «en N días» se cuentan en la zona
     * del móvil ({@code zone}, IANA) como el resto de endpoints que la reciben; sin ella o inválida, la del servidor.
     */
    private List<SubjectSummary> summarize(UUID userId, List<Subject> list, String zoneId) {
        if (list.isEmpty()) {
            return List.of();
        }
        List<UUID> ids = list.stream().map(Subject::id).toList();
        Map<UUID, SubjectRepositoryPort.ContentCount> counts = subjects.countContents(userId, ids);
        Instant now = clock.instant();
        ZoneId userZone = TimeZones.resolve(zoneId, zone);
        // Hasta dónde se miran clases: la próxima puede estar tras unas vacaciones; los días, dos semanas desde ella.
        Map<UUID, List<SubjectAgenda.ClassSlot>> classes = agenda == null ? Map.of()
                : agenda.upcomingClasses(userId, ids, now, now.plus(Duration.ofDays(CLASS_LOOKAHEAD_DAYS)));
        Map<UUID, List<SubjectAgenda.Deadline>> deadlines = agenda == null ? Map.of()
                : agenda.pendingDeadlines(userId, ids, now);
        return list.stream().map(s -> {
            SubjectRepositoryPort.ContentCount c = counts.getOrDefault(s.id(),
                    new SubjectRepositoryPort.ContentCount(0, 0));
            SubjectAgenda next = SubjectAgenda.of(classes.getOrDefault(s.id(), List.of()),
                    deadlines.getOrDefault(s.id(), List.of()), s.room(), s.nextAssessmentAt(), now, userZone);
            return new SubjectSummary(s, c.notes(), c.files(), next);
        }).toList();
    }

    /** El borrado del objeto es best-effort: un fallo del almacenamiento no bloquea el borrado de datos. */
    private void deleteObjectQuietly(String objectKey) {
        try {
            storage.delete(objectKey);
        } catch (StorageUnavailableException ignored) {
            // El objeto huérfano no es accesible: su clave ya no está registrada.
        }
    }
}
