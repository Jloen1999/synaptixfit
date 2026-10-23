package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.ApplyTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.DiscardTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.GetTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.ProcessTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.RequestTeachingGuideUploadUseCase;
import com.synaptixfit.application.port.input.academic.RetryTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.StartTeachingGuideImportUseCase;
import com.synaptixfit.domain.event.academic.TeachingGuideApplied;
import com.synaptixfit.domain.event.academic.TeachingGuideImportRequested;
import com.synaptixfit.domain.exception.DomainException;
import com.synaptixfit.domain.exception.StorageUnavailableException;
import com.synaptixfit.domain.exception.academic.InvalidFileUploadException;
import com.synaptixfit.domain.exception.academic.SubjectNotFoundException;
import com.synaptixfit.domain.exception.academic.TeachingGuideEmptyException;
import com.synaptixfit.domain.exception.academic.TeachingGuideImportAlreadyAppliedException;
import com.synaptixfit.domain.exception.academic.TeachingGuideImportNotFoundException;
import com.synaptixfit.domain.exception.academic.TeachingGuideImportNotReadyException;
import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.FileUploadTicket;
import com.synaptixfit.domain.model.academic.SignedUrl;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TeachingGuideImport;
import com.synaptixfit.domain.model.academic.TeachingGuideImportView;
import com.synaptixfit.domain.model.academic.TeachingGuideUploadPolicy;
import com.synaptixfit.domain.model.academic.CatalogSubject;
import com.synaptixfit.domain.port.output.academic.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.academic.TeachingGuideImportRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Importación del plan docente en PDF: subida firmada, análisis con la IA en segundo plano
 * (publica {@link TeachingGuideImportRequested}), consulta, reintento, descarte y aplicación a una
 * asignatura (publica {@link TeachingGuideApplied} para que el planificador cree las pruebas con fecha).
 */
public class TeachingGuideImportService implements RequestTeachingGuideUploadUseCase,
        StartTeachingGuideImportUseCase, ProcessTeachingGuideImportUseCase, GetTeachingGuideImportUseCase,
        RetryTeachingGuideImportUseCase, ApplyTeachingGuideImportUseCase, DiscardTeachingGuideImportUseCase {

    static final Duration UPLOAD_VALIDITY = Duration.ofMinutes(15);
    /** Hora a la que se fija una prueba cuya guía solo da el día (mañana lectiva típica). */
    static final LocalTime DEFAULT_ASSESSMENT_TIME = LocalTime.of(9, 0);

    private final TeachingGuideImportRepositoryPort imports;
    private final SubjectRepositoryPort subjects;
    private final SubjectFileRepositoryPort files;
    private final AiDocumentRepositoryPort aiDocuments;
    private final StudyDocumentCodecPort codec;
    private final StudyAssistantPort assistant;
    private final FileStoragePort storage;
    private final DomainEventPublisherPort events;
    private final AcademicCatalogPort catalog;
    private final Clock clock;
    private final ZoneId zone;

    private static final System.Logger LOG = System.getLogger(TeachingGuideImportService.class.getName());

    public TeachingGuideImportService(TeachingGuideImportRepositoryPort imports, SubjectRepositoryPort subjects,
                                      SubjectFileRepositoryPort files, AiDocumentRepositoryPort aiDocuments,
                                      StudyDocumentCodecPort codec, StudyAssistantPort assistant,
                                      FileStoragePort storage, DomainEventPublisherPort events,
                                      AcademicCatalogPort catalog, Clock clock, ZoneId zone) {
        this.imports = imports;
        this.subjects = subjects;
        this.files = files;
        this.aiDocuments = aiDocuments;
        this.codec = codec;
        this.assistant = assistant;
        this.storage = storage;
        this.events = events;
        this.catalog = catalog;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public FileUploadTicket requestUpload(UUID userId, String fileName, String mimeType, long sizeBytes) {
        String mime = TeachingGuideUploadPolicy.validate(mimeType, sizeBytes);
        String key = TeachingGuideUploadPolicy.objectKey(userId, fileName, clock.instant());
        PresignedUrl url = storage.presignUpload(key, mime, sizeBytes, UPLOAD_VALIDITY);
        return new FileUploadTicket(key, new SignedUrl(url.url(), url.method(), url.headers(), url.expiresAt()));
    }

    @Override
    public TeachingGuideImportView start(StartTeachingGuideImportUseCase.Command c) {
        String mime = TeachingGuideUploadPolicy.validate(c.mimeType(), c.sizeBytes());
        if (!TeachingGuideUploadPolicy.isKeyOf(c.objectKey(), c.userId())) {
            throw new InvalidFileUploadException(c.objectKey());
        }
        UUID target = c.targetSubjectId() == null ? null : subject(c.userId(), c.targetSubjectId()).id();
        Instant now = clock.instant();
        TeachingGuideImport saved = imports.create(TeachingGuideImport.start(c.userId(), target, c.objectKey(),
                c.fileName(), mime, c.sizeBytes(), now));
        events.publish(new TeachingGuideImportRequested(c.userId(), saved.id(), now));
        return view(saved);
    }

    /**
     * Se ejecuta fuera de la petición del estudiante. Primero reclama la importación
     * (PENDING → PROCESSING de forma atómica: si otro hilo ya la tomó o se descartó, no hace nada).
     * El resultado o el {@code code} del fallo solo se guardan si sigue en PROCESSING, así que un
     * análisis que acaba tarde no resucita una importación descartada.
     */
    @Override
    public void process(UUID importId) {
        Optional<TeachingGuideImport> found = imports.findById(importId);
        if (found.isEmpty()) {
            return;
        }
        TeachingGuideImport running = found.get().processing(clock.instant());
        if (!imports.transition(TeachingGuideImport.Status.PENDING, running)) {
            return;
        }
        TeachingGuideImport finished;
        try {
            byte[] data = storage.download(running.objectKey());
            TeachingGuide guide = assistant.extractTeachingGuide(
                    StudyAssistantPort.Source.binary(running.fileName(), running.mimeType(), data));
            if (guide == null || !guide.hasData()) {
                throw new TeachingGuideEmptyException(importId);
            }
            finished = running.ready(guide, clock.instant());
        } catch (DomainException e) {
            finished = running.failed(e.code(), clock.instant());
        } catch (RuntimeException e) {
            // Fallo inesperado (red, PDF corrupto…): se registra y se guarda como IA no disponible
            // para que el estudiante pueda reintentar.
            LOG.log(System.Logger.Level.WARNING, "Teaching guide import " + importId + " failed", e);
            finished = running.failed(null, clock.instant());
        }
        imports.transition(TeachingGuideImport.Status.PROCESSING, finished);
    }

    @Override
    public TeachingGuideImportView getImport(UUID userId, UUID importId) {
        return view(find(userId, importId));
    }

    @Override
    public TeachingGuideImportView retry(UUID userId, UUID importId) {
        Instant now = clock.instant();
        TeachingGuideImport current = find(userId, importId);
        TeachingGuideImport retried = current.retried(now);
        if (!imports.transition(current.status(), retried)) {
            throw new TeachingGuideImportNotReadyException(importId);
        }
        events.publish(new TeachingGuideImportRequested(userId, retried.id(), now));
        return view(retried);
    }

    @Override
    public Result apply(ApplyTeachingGuideImportUseCase.Command c) {
        Instant now = clock.instant();
        TeachingGuideImport current = find(c.userId(), c.importId());
        current.requireReady(now);
        TeachingGuide guide = c.guide() != null ? c.guide() : current.guide();
        if (guide == null || !guide.hasData()) {
            throw new TeachingGuideEmptyException(current.id());
        }
        // Se reclama antes de crear nada: con dos «aplicar» a la vez, el segundo espera al bloqueo
        // de la fila y, al ver que ya no está lista, falla sin crear otra asignatura.
        TeachingGuideImport claimed = current.applied(guide, now);
        if (!imports.transition(TeachingGuideImport.Status.READY, claimed)) {
            throw new TeachingGuideImportAlreadyAppliedException(current.id());
        }
        boolean created = c.subjectId() == null;
        Subject subject = created ? newSubject(c.userId(), guide, current.fileName(), now)
                : completeSubject(subject(c.userId(), c.subjectId()), guide);
        List<TeachingGuideApplied.DatedAssessment> dated = datedAssessments(guide);
        Instant nextDated = dated.stream().map(TeachingGuideApplied.DatedAssessment::dueAt).filter(now::isBefore)
                .min(Comparator.naturalOrder()).orElse(null);
        // La próxima evaluación solo se adelanta: nunca se pisa una fecha anterior que puso el estudiante.
        if (nextDated != null && (subject.nextAssessmentAt() == null || !subject.nextAssessmentAt().isAfter(now)
                || nextDated.isBefore(subject.nextAssessmentAt()))) {
            subject.scheduleNextAssessment(nextDated);
        }
        subject = subjects.save(subject);

        TeachingGuide finalGuide = guide.keepingProgressOf(previousGuide(c.userId(), subject.id()));
        saveGuide(c.userId(), subject, finalGuide, now);
        attachPdf(current, subject.id(), now);
        imports.transition(TeachingGuideImport.Status.APPLIED, claimed.appliedTo(subject.id(), finalGuide, now));
        if (c.createDeadlines() && !dated.isEmpty()) {
            events.publish(new TeachingGuideApplied(c.userId(), subject.id(), dated, now));
        }
        return new Result(subject.id(), created, c.createDeadlines() ? dated.size() : 0);
    }

    @Override
    public void discard(UUID userId, UUID importId) {
        TeachingGuideImport current = find(userId, importId);
        // No se borra un PDF que ya está entre los archivos de una asignatura.
        if (current.ownsUploadedFile() && !files.existsByObjectKey(current.objectKey())) {
            try {
                storage.delete(current.objectKey());
            } catch (StorageUnavailableException ignored) {
                // Best-effort como al borrar archivos de asignatura: el registro se elimina igualmente.
            }
        }
        imports.delete(current.id());
    }

    // ------------------------------------------------------------------ apoyo

    private Subject subject(UUID userId, UUID subjectId) {
        return subjects.findByIdAndUser(subjectId, userId).orElseThrow(() -> new SubjectNotFoundException(subjectId));
    }

    private TeachingGuideImport find(UUID userId, UUID importId) {
        return imports.findByIdAndUser(importId, userId)
                .orElseThrow(() -> new TeachingGuideImportNotFoundException(importId));
    }

    private TeachingGuideImportView view(TeachingGuideImport i) {
        Instant now = clock.instant();
        Subject suggested = null;
        if (i.targetSubjectId() != null) {
            suggested = subjects.findByIdAndUser(i.targetSubjectId(), i.userId()).orElse(null);
        } else if (i.guide() != null) {
            TeachingGuide.SubjectInfo info = i.guide().subject();
            suggested = subjects.findByUser(i.userId(), false).stream()
                    .filter(s -> info.matches(s.name(), s.code())).findFirst().orElse(null);
        }
        return new TeachingGuideImportView(i, i.effectiveStatus(now), i.effectiveErrorCode(now),
                suggested == null ? null : suggested.id(), suggested == null ? null : suggested.name());
    }

    private Subject newSubject(UUID userId, TeachingGuide guide, String fileName, Instant now) {
        TeachingGuide.SubjectInfo info = guide.subject();
        Integer credits = info.roundedCredits();
        return Subject.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .name(info.name() != null ? info.name() : nameFromFile(fileName))
                .code(info.code())
                .description(info.description())
                .credits(credits == null ? Subject.DEFAULT_CREDITS : credits)
                .perceivedDifficulty(Subject.DEFAULT_DIFFICULTY)
                .teacher(firstProfessor(guide))
                .catalogSubjectId(catalogMatch(userId, info))
                .createdAt(now)
                .build();
    }

    /** Completa solo lo que la asignatura no tiene: nunca pisa lo que escribió el estudiante. */
    private Subject completeSubject(Subject s, TeachingGuide guide) {
        TeachingGuide.SubjectInfo info = guide.subject();
        if (s.code() == null && info.code() != null) {
            s.changeCode(info.code());
        }
        if (s.description() == null && info.description() != null) {
            s.changeDescription(info.description());
        }
        if (s.teacher() == null && firstProfessor(guide) != null) {
            s.changeTeacher(firstProfessor(guide));
        }
        // Los créditos solo se toman de la guía si el estudiante no los cambió (siguen por defecto).
        if (info.roundedCredits() != null && s.credits() == Subject.DEFAULT_CREDITS) {
            s.changeCredits(info.roundedCredits());
        }
        return s;
    }

    /**
     * Enlaza la asignatura nueva con la del plan de estudios de su carrera (mismo código oficial o
     * nombre): así el catálogo la muestra como «ya añadida» y no se duplica al elegir asignaturas.
     */
    private java.util.UUID catalogMatch(UUID userId, TeachingGuide.SubjectInfo info) {
        return catalog.findForUserDegrees(userId).stream().filter(c -> c.matches(info)).map(CatalogSubject::id)
                .findFirst().orElse(null);
    }

    private static String firstProfessor(TeachingGuide guide) {
        return guide.professors().stream().map(TeachingGuide.Professor::name)
                .filter(n -> n != null && !n.isBlank()).findFirst().orElse(null);
    }

    /** «CUM2526_GTI_6_DETH_502376.pdf» → «CUM2526 GTI 6 DETH 502376» si la IA no dio el nombre. */
    private static String nameFromFile(String fileName) {
        String base = fileName.replaceAll("\\.[A-Za-z0-9]{1,5}$", "").replaceAll("[_\\-]+", " ").strip();
        return base.length() < 2 ? "Asignatura" : base.length() > 150 ? base.substring(0, 150) : base;
    }

    private List<TeachingGuideApplied.DatedAssessment> datedAssessments(TeachingGuide guide) {
        return guide.assessments().stream()
                .filter(a -> a.dueDate() != null && guide.isActive(a))
                .map(a -> new TeachingGuideApplied.DatedAssessment(a.name(), a.kind(), atDefaultTime(a.dueDate()),
                        describe(a)))
                .toList();
    }

    private Instant atDefaultTime(LocalDate day) {
        return day.atTime(DEFAULT_ASSESSMENT_TIME).atZone(zone).toInstant();
    }

    /** «30 % de la nota · Temas 1, 2, 3 · 120 min · No recuperable». */
    private static String describe(TeachingGuide.Assessment a) {
        StringBuilder sb = new StringBuilder();
        sb.append(Math.round(a.percentage())).append(" % de la nota");
        if (!a.topicNumbers().isEmpty()) {
            sb.append(" · Temas ").append(a.topicNumbers().stream().map(String::valueOf)
                    .collect(Collectors.joining(", ")));
        }
        if (a.durationMinutes() != null) {
            sb.append(" · ").append(a.durationMinutes()).append(" min");
        }
        if (Boolean.FALSE.equals(a.recoverable())) {
            sb.append(" · No recuperable");
        }
        return sb.toString();
    }

    private TeachingGuide previousGuide(UUID userId, UUID subjectId) {
        return aiDocuments.find(userId, AiDocumentSource.SUBJECT, subjectId.toString(), AiDocumentType.TEACHING_GUIDE)
                .map(d -> codec.decodeTeachingGuide(d.content())).orElse(null);
    }

    private void saveGuide(UUID userId, Subject subject, TeachingGuide guide, Instant now) {
        String content = codec.encodeTeachingGuide(guide);
        AiDocument doc = aiDocuments.find(userId, AiDocumentSource.SUBJECT, subject.id().toString(),
                        AiDocumentType.TEACHING_GUIDE)
                .map(d -> d.withContent(content, subject.name(), subject.id(), now))
                .orElseGet(() -> AiDocument.create(userId, subject.id(), AiDocumentSource.SUBJECT,
                        subject.id().toString(), AiDocumentType.TEACHING_GUIDE, subject.name(), content, now));
        aiDocuments.save(doc);
    }

    /** El PDF queda entre los archivos de la asignatura (sin copiarlo: se registra la misma clave). */
    private void attachPdf(TeachingGuideImport i, UUID subjectId, Instant now) {
        if (files.existsByObjectKey(i.objectKey())) {
            return;
        }
        String publicUrl = storage.publicUrl(i.objectKey());
        files.save(new SubjectFile(UUID.randomUUID(), i.userId(), subjectId, i.fileName(), i.objectKey(),
                publicUrl == null ? i.objectKey() : publicUrl, i.sizeBytes(), i.mimeType(), now));
    }
}
