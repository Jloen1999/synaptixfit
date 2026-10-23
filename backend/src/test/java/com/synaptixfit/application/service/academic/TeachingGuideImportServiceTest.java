package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.academic.ApplyTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.StartTeachingGuideImportUseCase;
import com.synaptixfit.domain.event.academic.TeachingGuideApplied;
import com.synaptixfit.domain.event.academic.TeachingGuideImportRequested;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.academic.FileTypeNotAllowedException;
import com.synaptixfit.domain.exception.academic.InvalidFileUploadException;
import com.synaptixfit.domain.exception.academic.TeachingGuideImportAlreadyAppliedException;
import com.synaptixfit.domain.exception.academic.TeachingGuideImportNotFoundException;
import com.synaptixfit.domain.exception.academic.TeachingGuideImportNotReadyException;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TeachingGuide.AssessmentKind;
import com.synaptixfit.domain.model.academic.TeachingGuide.EvaluationMode;
import com.synaptixfit.domain.model.academic.TeachingGuideImport;
import com.synaptixfit.domain.model.academic.TeachingGuideImportView;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.TeachingGuideImportRepositoryPort;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class TeachingGuideImportServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final StudyAssistantPort assistant = mock(StudyAssistantPort.class);
    private final Map<UUID, TeachingGuideImport> store = new HashMap<>();
    private final TeachingGuideImportRepositoryPort imports = new TeachingGuideImportRepositoryPort() {
        public Optional<TeachingGuideImport> findById(UUID id) { return Optional.ofNullable(store.get(id)); }
        public Optional<TeachingGuideImport> findByIdAndUser(UUID id, UUID userId) {
            return findById(id).filter(i -> i.userId().equals(userId));
        }
        public TeachingGuideImport create(TeachingGuideImport i) { store.put(i.id(), i); return i; }
        public boolean transition(TeachingGuideImport.Status expected, TeachingGuideImport i) {
            TeachingGuideImport current = store.get(i.id());
            if (current == null || current.status() != expected) {
                return false;
            }
            store.put(i.id(), i);
            return true;
        }
        public void delete(UUID id) { store.remove(id); }
    };
    private final TeachingGuideImportService service = new TeachingGuideImportService(imports, f.subjects, f.files,
            f.aiDocuments, f.codec, assistant, f.storage, f.events::add, f.catalogPort, AcademicFakes.CLOCK,
            ZoneId.of("Europe/Madrid"));
    private final UUID user = UUID.randomUUID();

    private TeachingGuide guide(LocalDate examDay) {
        return new TeachingGuide(
                new TeachingGuide.SubjectInfo("Diseño y evaluación de tecnologías Hardware", "502376", 4.5, null, 6,
                        "Obligatoria", null, null, "Universidad de Extremadura", "2025/2026", null, "Arquitecturas"),
                List.of(new TeachingGuide.Professor("Juan Ángel García", null, "12")),
                List.of(new TeachingGuide.Topic("Tema 1", TeachingGuide.TopicKind.THEORY, false)),
                List.of(new TeachingGuide.Assessment("Prueba 1", 30, null, EvaluationMode.CONTINUOUS,
                                AssessmentKind.EXAM, 120, List.of(1), Boolean.TRUE, examDay),
                        new TeachingGuide.Assessment("Global", 100, null, EvaluationMode.GLOBAL, AssessmentKind.EXAM,
                                240, List.of(1), null, examDay)),
                List.of(), null);
    }

    private TeachingGuideImportView start(UUID targetSubject) {
        String key = service.requestUpload(user, "plan docente.pdf", "application/pdf", 1000).objectKey();
        return service.start(new StartTeachingGuideImportUseCase.Command(user, key, "plan docente.pdf",
                "application/pdf", 1000, targetSubject));
    }

    @Test
    void uploadOnlyAcceptsPdfsUnderTheUserPrefix() {
        assertThatThrownBy(() -> service.requestUpload(user, "a.docx", "application/msword", 10))
                .isInstanceOf(FileTypeNotAllowedException.class);
        assertThatThrownBy(() -> service.start(new StartTeachingGuideImportUseCase.Command(user,
                "usuarios/" + UUID.randomUUID() + "/planes-docentes/1_a.pdf", "a.pdf", "application/pdf", 10, null)))
                .isInstanceOf(InvalidFileUploadException.class);
    }

    @Test
    void importIsAnalysedInBackgroundAndAppliedAsNewSubjectWithDeadlines() {
        TeachingGuideImportView started = start(null);
        assertThat(started.status()).isEqualTo(TeachingGuideImport.Status.PENDING);
        assertThat(f.events).singleElement().isInstanceOf(TeachingGuideImportRequested.class);
        assertThatThrownBy(() -> service.apply(new ApplyTeachingGuideImportUseCase.Command(user,
                started.guideImport().id(), null, null, true))).isInstanceOf(TeachingGuideImportNotReadyException.class);

        when(assistant.extractTeachingGuide(any())).thenReturn(guide(LocalDate.of(2026, 11, 20)));
        service.process(started.guideImport().id());
        service.process(started.guideImport().id());
        TeachingGuideImportView ready = service.getImport(user, started.guideImport().id());
        assertThat(ready.status()).isEqualTo(TeachingGuideImport.Status.READY);

        ApplyTeachingGuideImportUseCase.Result result = service.apply(new ApplyTeachingGuideImportUseCase.Command(user,
                ready.guideImport().id(), null, null, true));

        Subject created = f.subjectStore.get(result.subjectId());
        assertThat(result.subjectCreated()).isTrue();
        assertThat(created.name()).isEqualTo("Diseño y evaluación de tecnologías Hardware");
        assertThat(created.credits()).isEqualTo(5);
        assertThat(created.teacher()).isEqualTo("Juan Ángel García");
        assertThat(created.nextAssessmentAt()).isNotNull();
        assertThat(f.aiDocuments.find(user, AiDocumentSource.SUBJECT, created.id().toString(),
                AiDocumentType.TEACHING_GUIDE)).isPresent();
        assertThat(f.files.findBySubject(user, created.id())).singleElement()
                .satisfies(file -> assertThat(file.objectKey()).startsWith("usuarios/" + user + "/planes-docentes/"));
        // Solo la prueba de la modalidad activa (continua) pasa al planificador.
        assertThat(f.events).filteredOn(TeachingGuideApplied.class::isInstance).singleElement()
                .satisfies(e -> assertThat(((TeachingGuideApplied) e).assessments()).singleElement()
                        .satisfies(a -> assertThat(a.description()).contains("30 % de la nota", "Temas 1", "120 min")));
        assertThat(service.getImport(user, ready.guideImport().id()).status())
                .isEqualTo(TeachingGuideImport.Status.APPLIED);
    }

    @Test
    void applyingToAnExistingSubjectOnlyFillsWhatIsMissing() {
        Subject mine = f.subject(user, "Hardware (mi nombre)");
        TeachingGuideImportView started = start(mine.id());
        when(assistant.extractTeachingGuide(any())).thenReturn(guide(null));
        service.process(started.guideImport().id());

        TeachingGuideImportView ready = service.getImport(user, started.guideImport().id());
        assertThat(ready.suggestedSubjectId()).isEqualTo(mine.id());
        ApplyTeachingGuideImportUseCase.Result result = service.apply(new ApplyTeachingGuideImportUseCase.Command(user,
                ready.guideImport().id(), mine.id(), null, true));

        assertThat(result.subjectCreated()).isFalse();
        assertThat(result.deadlinesRequested()).isZero();
        Subject updated = f.subjectStore.get(mine.id());
        assertThat(updated.name()).isEqualTo("Hardware (mi nombre)");
        assertThat(updated.code()).isEqualTo("502376");
        assertThat(f.events).noneMatch(TeachingGuideApplied.class::isInstance);
    }

    @Test
    void aiFailuresAreStoredWithTheirCodeAndCanBeRetried() {
        TeachingGuideImportView started = start(null);
        when(assistant.extractTeachingGuide(any())).thenThrow(new AiQuotaExceededException());
        service.process(started.guideImport().id());

        TeachingGuideImportView failed = service.getImport(user, started.guideImport().id());
        assertThat(failed.status()).isEqualTo(TeachingGuideImport.Status.FAILED);
        assertThat(failed.errorCode()).isEqualTo("AI_QUOTA_EXCEEDED");

        assertThat(service.retry(user, started.guideImport().id()).status())
                .isEqualTo(TeachingGuideImport.Status.PENDING);
        assertThat(f.events).filteredOn(TeachingGuideImportRequested.class::isInstance).hasSize(2);
    }

    @Test
    void discardDeletesTheUploadedPdfAndHidesForeignImports() {
        TeachingGuideImportView started = start(null);
        UUID stranger = UUID.randomUUID();
        assertThatThrownBy(() -> service.getImport(stranger, started.guideImport().id()))
                .isInstanceOf(TeachingGuideImportNotFoundException.class);

        service.discard(user, started.guideImport().id());

        assertThat(store).isEmpty();
        assertThat(f.deletedObjects).containsExactly(started.guideImport().objectKey());
    }

    @Test
    void secondApplyFailsWithoutCreatingAnotherSubject() {
        TeachingGuideImportView started = start(null);
        when(assistant.extractTeachingGuide(any())).thenReturn(guide(null));
        service.process(started.guideImport().id());
        UUID id = started.guideImport().id();

        service.apply(new ApplyTeachingGuideImportUseCase.Command(user, id, null, null, false));

        assertThatThrownBy(() -> service.apply(new ApplyTeachingGuideImportUseCase.Command(user, id, null, null,
                false))).isInstanceOf(TeachingGuideImportAlreadyAppliedException.class);
        assertThat(f.subjectStore).hasSize(1);
    }

    @Test
    void analysisFinishingAfterDiscardDoesNotResurrectTheImport() {
        TeachingGuideImportView started = start(null);
        UUID id = started.guideImport().id();
        when(assistant.extractTeachingGuide(any())).thenAnswer(inv -> {
            service.discard(user, id);
            return guide(null);
        });

        service.process(id);

        assertThat(store).isEmpty();
    }

    @Test
    void existingCreditsAndEarlierAssessmentAreKept() {
        Subject mine = f.subjectStore.values().stream().findFirst().orElseGet(() -> f.subject(user, "Hardware"));
        mine.changeCredits(9);
        TeachingGuideImportView started = start(mine.id());
        when(assistant.extractTeachingGuide(any())).thenReturn(guide(LocalDate.of(2026, 11, 20)));
        service.process(started.guideImport().id());

        service.apply(new ApplyTeachingGuideImportUseCase.Command(user, started.guideImport().id(), mine.id(), null,
                false));

        assertThat(f.subjectStore.get(mine.id()).credits()).isEqualTo(9);
    }

    @Test
    void newSubjectIsLinkedToTheCatalogSubjectWithTheSameOfficialCode() {
        com.synaptixfit.domain.model.academic.CatalogSubject official =
                new com.synaptixfit.domain.model.academic.CatalogSubject(UUID.randomUUID(), UUID.randomUUID(),
                        "Diseño y evaluación de tecnologías hardware", 3, 2, "Obligatoria", 6.0, 150, null, "502376");
        f.catalog.add(official);
        TeachingGuideImportView started = start(null);
        when(assistant.extractTeachingGuide(any())).thenReturn(guide(null));
        service.process(started.guideImport().id());

        ApplyTeachingGuideImportUseCase.Result result = service.apply(new ApplyTeachingGuideImportUseCase.Command(user,
                started.guideImport().id(), null, null, false));

        assertThat(f.subjectStore.get(result.subjectId()).catalogSubjectId()).isEqualTo(official.id());
    }
}
