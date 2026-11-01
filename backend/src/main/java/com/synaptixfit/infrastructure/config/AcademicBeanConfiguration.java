package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.academic.AbandonTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.AnswerQuestionUseCase;
import com.synaptixfit.application.port.input.academic.AnswerTestQuestionUseCase;
import com.synaptixfit.application.port.input.academic.AssignSubjectSemesterUseCase;
import com.synaptixfit.application.port.input.academic.CompleteBankPracticeUseCase;
import com.synaptixfit.application.port.input.academic.CompleteTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.ConfirmFileUploadUseCase;
import com.synaptixfit.application.port.input.academic.CopySharedNoteUseCase;
import com.synaptixfit.application.port.input.academic.CreateNoteUseCase;
import com.synaptixfit.application.port.input.academic.CreateSubjectUseCase;
import com.synaptixfit.application.port.input.academic.CreateSubjectsFromCatalogUseCase;
import com.synaptixfit.application.port.input.academic.DeleteNoteUseCase;
import com.synaptixfit.application.port.input.academic.PrivatizeUserNotesUseCase;
import com.synaptixfit.application.port.input.academic.AbandonStudyMaterialUseCase;
import com.synaptixfit.application.port.input.academic.DeleteStudyMaterialUseCase;
import com.synaptixfit.application.port.input.academic.DeleteSubjectFileUseCase;
import com.synaptixfit.application.port.input.academic.DeleteSubjectUseCase;
import com.synaptixfit.application.port.input.academic.GenerateQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.GenerateStudyArtifactUseCase;
import com.synaptixfit.application.port.input.academic.GenerateStudyDocumentUseCase;
import com.synaptixfit.application.port.input.academic.GenerateTeachingGuideUseCase;
import com.synaptixfit.application.port.input.academic.GetActiveTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.GetFileDownloadUrlUseCase;
import com.synaptixfit.application.port.input.academic.GetNoteUseCase;
import com.synaptixfit.application.port.input.academic.GetSharedNoteUseCase;
import com.synaptixfit.application.port.input.academic.GetQuestionBankUseCase;
import com.synaptixfit.application.port.input.academic.GetRetentionMetricsUseCase;
import com.synaptixfit.application.port.input.academic.GetStudyDocumentAvailabilityUseCase;
import com.synaptixfit.application.port.input.academic.GetStudyDocumentUseCase;
import com.synaptixfit.application.port.input.academic.GetStudyMaterialUseCase;
import com.synaptixfit.application.port.input.academic.GetSubjectFileUseCase;
import com.synaptixfit.application.port.input.academic.GetSubjectUseCase;
import com.synaptixfit.application.port.input.academic.GetTeachingGuideUseCase;
import com.synaptixfit.application.port.input.academic.GetTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.GradeTeachingGuideAssessmentUseCase;
import com.synaptixfit.application.port.input.academic.SetTeachingGuideModeUseCase;
import com.synaptixfit.application.port.input.academic.ListCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.academic.ListDueStudyMaterialsUseCase;
import com.synaptixfit.application.port.input.academic.ListNotesUseCase;
import com.synaptixfit.application.port.input.academic.ListReviewHistoryUseCase;
import com.synaptixfit.application.port.input.academic.ListSharedNotesUseCase;
import com.synaptixfit.application.port.input.academic.ListStudyMaterialsUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectFilesUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectSemestersUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectsUseCase;
import com.synaptixfit.application.port.input.academic.ListTestSessionsUseCase;
import com.synaptixfit.application.port.input.academic.PreviewReviewIntervalsUseCase;
import com.synaptixfit.application.port.input.academic.RegisterStudyMaterialUseCase;
import com.synaptixfit.application.port.input.academic.RemoveSubjectSemesterUseCase;
import com.synaptixfit.application.port.input.academic.RequestFileUploadUseCase;
import com.synaptixfit.application.port.input.academic.ReviewFlashcardsUseCase;
import com.synaptixfit.application.port.input.academic.ReviewStudyMaterialUseCase;
import com.synaptixfit.application.port.input.academic.SaveArtifactAsNoteUseCase;
import com.synaptixfit.application.port.input.academic.SaveArtifactAsQuizUseCase;
import com.synaptixfit.application.port.input.academic.StartTestSessionUseCase;
import com.synaptixfit.application.port.input.academic.UpdateNoteUseCase;
import com.synaptixfit.application.port.input.academic.UpdateSubjectUseCase;
import com.synaptixfit.application.port.input.academic.UpdateTeachingGuideTopicUseCase;
import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.service.academic.NoteService;
import com.synaptixfit.application.service.academic.QuizService;
import com.synaptixfit.application.service.academic.SharedNoteService;
import com.synaptixfit.application.service.academic.StudyAssistantService;
import com.synaptixfit.application.service.academic.StudyMaterialService;
import com.synaptixfit.application.service.academic.SubjectFileService;
import com.synaptixfit.application.service.academic.SubjectService;
import com.synaptixfit.domain.port.output.academic.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.PhysicalLoadPort;
import com.synaptixfit.domain.port.output.academic.QuestionAttemptRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.ReviewRecordRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectSemesterRepositoryPort;
import com.synaptixfit.domain.port.output.academic.TestSessionRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import java.time.Clock;
import java.time.ZoneId;
import java.util.Random;

/**
 * Raíz de composición del módulo académico (asignaturas, apuntes, archivos, asistente de IA,
 * repaso espaciado y práctica). Sigue el patrón de {@link BeanConfiguration}.
 */
@Configuration
public class AcademicBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final SubjectRepositoryPort subjects;
    private final SubjectSemesterRepositoryPort semesters;
    private final AcademicCatalogPort catalog;
    private final NoteRepositoryPort notes;
    private final SubjectFileRepositoryPort files;
    private final AiDocumentRepositoryPort aiDocuments;
    private final StudyDocumentCodecPort codec;
    private final StudyAssistantPort assistant;
    private final StudyMaterialRepositoryPort materials;
    private final ReviewRecordRepositoryPort reviews;
    private final PhysicalLoadPort physicalLoad;
    private final QuestionBankRepositoryPort banks;
    private final QuestionAttemptRepositoryPort attempts;
    private final TestSessionRepositoryPort sessions;
    private final FileStoragePort storage;
    private final DomainEventPublisherPort events;
    private final AwardExperienceUseCase awardExperience;
    private final UserRepositoryPort users;
    private final Clock clock;
    private final ZoneId zone;

    public AcademicBeanConfiguration(TransactionalUseCaseFactory tx, SubjectRepositoryPort subjects,
                                     SubjectSemesterRepositoryPort semesters, AcademicCatalogPort catalog,
                                     NoteRepositoryPort notes, SubjectFileRepositoryPort files,
                                     AiDocumentRepositoryPort aiDocuments, StudyDocumentCodecPort codec,
                                     StudyAssistantPort assistant, StudyMaterialRepositoryPort materials,
                                     ReviewRecordRepositoryPort reviews, PhysicalLoadPort physicalLoad,
                                     QuestionBankRepositoryPort banks, QuestionAttemptRepositoryPort attempts,
                                     TestSessionRepositoryPort sessions, FileStoragePort storage,
                                     DomainEventPublisherPort events, AwardExperienceUseCase awardExperience,
                                     UserRepositoryPort users,
                                     Clock clock,
                                     @Value("${synaptixfit.insights.default-zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.subjects = subjects;
        this.semesters = semesters;
        this.catalog = catalog;
        this.notes = notes;
        this.files = files;
        this.aiDocuments = aiDocuments;
        this.codec = codec;
        this.assistant = assistant;
        this.materials = materials;
        this.reviews = reviews;
        this.physicalLoad = physicalLoad;
        this.banks = banks;
        this.attempts = attempts;
        this.sessions = sessions;
        this.storage = storage;
        this.events = events;
        this.awardExperience = awardExperience;
        this.users = users;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    // ---------------------------------------------------------------- subjectService

    @Bean(autowireCandidate = false)
    SubjectService subjectService() {
        return new SubjectService(subjects, semesters, catalog, files, aiDocuments, storage, events, clock);
    }

    @Bean
    ListSubjectsUseCase listSubjectsUseCase() {
        return tx.wrap(ListSubjectsUseCase.class, subjectService());
    }

    @Bean
    GetSubjectUseCase getSubjectUseCase() {
        return tx.wrap(GetSubjectUseCase.class, subjectService());
    }

    @Bean
    CreateSubjectUseCase createSubjectUseCase() {
        return tx.wrap(CreateSubjectUseCase.class, subjectService());
    }

    @Bean
    UpdateSubjectUseCase updateSubjectUseCase() {
        return tx.wrap(UpdateSubjectUseCase.class, subjectService());
    }

    @Bean
    DeleteSubjectUseCase deleteSubjectUseCase() {
        return tx.wrap(DeleteSubjectUseCase.class, subjectService());
    }

    @Bean
    ListCatalogSubjectsUseCase listCatalogSubjectsUseCase() {
        return tx.wrap(ListCatalogSubjectsUseCase.class, subjectService());
    }

    @Bean
    CreateSubjectsFromCatalogUseCase createSubjectsFromCatalogUseCase() {
        return tx.wrap(CreateSubjectsFromCatalogUseCase.class, subjectService());
    }

    @Bean
    ListSubjectSemestersUseCase listSubjectSemestersUseCase() {
        return tx.wrap(ListSubjectSemestersUseCase.class, subjectService());
    }

    @Bean
    AssignSubjectSemesterUseCase assignSubjectSemesterUseCase() {
        return tx.wrap(AssignSubjectSemesterUseCase.class, subjectService());
    }

    @Bean
    RemoveSubjectSemesterUseCase removeSubjectSemesterUseCase() {
        return tx.wrap(RemoveSubjectSemesterUseCase.class, subjectService());
    }

    // ---------------------------------------------------------------- noteService

    @Bean(autowireCandidate = false)
    NoteService noteService() {
        return new NoteService(notes, subjects, materials, aiDocuments, users, clock);
    }

    @Bean
    ListNotesUseCase listNotesUseCase() {
        return tx.wrap(ListNotesUseCase.class, noteService());
    }

    @Bean(autowireCandidate = false)
    SharedNoteService sharedNoteService() {
        return new SharedNoteService(notes, subjects, clock);
    }

    @Bean
    ListSharedNotesUseCase listSharedNotesUseCase() {
        return tx.wrap(ListSharedNotesUseCase.class, sharedNoteService());
    }

    @Bean
    GetSharedNoteUseCase getSharedNoteUseCase() {
        return tx.wrap(GetSharedNoteUseCase.class, sharedNoteService());
    }

    @Bean
    CopySharedNoteUseCase copySharedNoteUseCase() {
        return tx.wrap(CopySharedNoteUseCase.class, sharedNoteService());
    }

    @Bean
    GetNoteUseCase getNoteUseCase() {
        return tx.wrap(GetNoteUseCase.class, noteService());
    }

    @Bean
    CreateNoteUseCase createNoteUseCase() {
        return tx.wrap(CreateNoteUseCase.class, noteService());
    }

    @Bean
    UpdateNoteUseCase updateNoteUseCase() {
        return tx.wrap(UpdateNoteUseCase.class, noteService());
    }

    @Bean
    DeleteNoteUseCase deleteNoteUseCase() {
        return tx.wrap(DeleteNoteUseCase.class, noteService());
    }

    @Bean
    PrivatizeUserNotesUseCase privatizeUserNotesUseCase() {
        return tx.wrap(PrivatizeUserNotesUseCase.class, noteService());
    }

    // ---------------------------------------------------------------- subjectFileService

    @Bean(autowireCandidate = false)
    SubjectFileService subjectFileService() {
        return new SubjectFileService(files, subjects, materials, aiDocuments, storage, clock);
    }

    @Bean
    ListSubjectFilesUseCase listSubjectFilesUseCase() {
        return tx.wrap(ListSubjectFilesUseCase.class, subjectFileService());
    }

    @Bean
    GetSubjectFileUseCase getSubjectFileUseCase() {
        return tx.wrap(GetSubjectFileUseCase.class, subjectFileService());
    }

    @Bean
    RequestFileUploadUseCase requestFileUploadUseCase() {
        return tx.wrap(RequestFileUploadUseCase.class, subjectFileService());
    }

    @Bean
    ConfirmFileUploadUseCase confirmFileUploadUseCase() {
        return tx.wrap(ConfirmFileUploadUseCase.class, subjectFileService());
    }

    @Bean
    GetFileDownloadUrlUseCase getFileDownloadUrlUseCase() {
        return tx.wrap(GetFileDownloadUrlUseCase.class, subjectFileService());
    }

    @Bean
    DeleteSubjectFileUseCase deleteSubjectFileUseCase() {
        return tx.wrap(DeleteSubjectFileUseCase.class, subjectFileService());
    }

    // ---------------------------------------------------------------- studyAssistantService

    @Bean(autowireCandidate = false)
    StudyAssistantService studyAssistantService() {
        return new StudyAssistantService(subjects, notes, files, materials, banks, aiDocuments, codec, assistant, storage,
                clock);
    }

    @Bean
    GetStudyDocumentUseCase getStudyDocumentUseCase() {
        return tx.wrap(GetStudyDocumentUseCase.class, studyAssistantService());
    }

    @Bean
    GenerateStudyDocumentUseCase generateStudyDocumentUseCase() {
        return tx.wrap(GenerateStudyDocumentUseCase.class, studyAssistantService());
    }

    @Bean
    GetStudyDocumentAvailabilityUseCase getStudyDocumentAvailabilityUseCase() {
        return tx.wrap(GetStudyDocumentAvailabilityUseCase.class, studyAssistantService());
    }

    @Bean
    GenerateStudyArtifactUseCase generateStudyArtifactUseCase() {
        return tx.wrap(GenerateStudyArtifactUseCase.class, studyAssistantService());
    }

    @Bean
    SaveArtifactAsNoteUseCase saveArtifactAsNoteUseCase() {
        return tx.wrap(SaveArtifactAsNoteUseCase.class, studyAssistantService());
    }

    @Bean
    SaveArtifactAsQuizUseCase saveArtifactAsQuizUseCase() {
        return tx.wrap(SaveArtifactAsQuizUseCase.class, studyAssistantService());
    }

    @Bean
    GetTeachingGuideUseCase getTeachingGuideUseCase() {
        return tx.wrap(GetTeachingGuideUseCase.class, studyAssistantService());
    }

    @Bean
    GenerateTeachingGuideUseCase generateTeachingGuideUseCase() {
        return tx.wrap(GenerateTeachingGuideUseCase.class, studyAssistantService());
    }

    @Bean
    UpdateTeachingGuideTopicUseCase updateTeachingGuideTopicUseCase() {
        return tx.wrap(UpdateTeachingGuideTopicUseCase.class, studyAssistantService());
    }

    @Bean
    GradeTeachingGuideAssessmentUseCase gradeTeachingGuideAssessmentUseCase() {
        return tx.wrap(GradeTeachingGuideAssessmentUseCase.class, studyAssistantService());
    }

    @Bean
    SetTeachingGuideModeUseCase setTeachingGuideModeUseCase() {
        return tx.wrap(SetTeachingGuideModeUseCase.class, studyAssistantService());
    }

    // ---------------------------------------------------------------- studyMaterialService

    @Bean(autowireCandidate = false)
    StudyMaterialService studyMaterialService() {
        return new StudyMaterialService(materials, reviews, physicalLoad, subjects, notes, files, aiDocuments, events,
                awardExperience, clock, zone);
    }

    @Bean
    RegisterStudyMaterialUseCase registerStudyMaterialUseCase() {
        return tx.wrap(RegisterStudyMaterialUseCase.class, studyMaterialService());
    }

    @Bean
    ListStudyMaterialsUseCase listStudyMaterialsUseCase() {
        return tx.wrap(ListStudyMaterialsUseCase.class, studyMaterialService());
    }

    @Bean
    ListDueStudyMaterialsUseCase listDueStudyMaterialsUseCase() {
        return tx.wrap(ListDueStudyMaterialsUseCase.class, studyMaterialService());
    }

    @Bean
    GetStudyMaterialUseCase getStudyMaterialUseCase() {
        return tx.wrap(GetStudyMaterialUseCase.class, studyMaterialService());
    }

    @Bean
    AbandonStudyMaterialUseCase abandonStudyMaterialUseCase() {
        return tx.wrap(AbandonStudyMaterialUseCase.class, studyMaterialService());
    }

    @Bean
    DeleteStudyMaterialUseCase deleteStudyMaterialUseCase() {
        return tx.wrap(DeleteStudyMaterialUseCase.class, studyMaterialService());
    }

    @Bean
    GetRetentionMetricsUseCase getRetentionMetricsUseCase() {
        return tx.wrap(GetRetentionMetricsUseCase.class, studyMaterialService());
    }

    @Bean
    PreviewReviewIntervalsUseCase previewReviewIntervalsUseCase() {
        return tx.wrap(PreviewReviewIntervalsUseCase.class, studyMaterialService());
    }

    @Bean
    ReviewStudyMaterialUseCase reviewStudyMaterialUseCase() {
        return tx.wrap(ReviewStudyMaterialUseCase.class, studyMaterialService());
    }

    @Bean
    ListReviewHistoryUseCase listReviewHistoryUseCase() {
        return tx.wrap(ListReviewHistoryUseCase.class, studyMaterialService());
    }

    @Bean
    ReviewFlashcardsUseCase reviewFlashcardsUseCase() {
        return tx.wrap(ReviewFlashcardsUseCase.class, studyMaterialService());
    }

    // ---------------------------------------------------------------- quizService

    @Bean(autowireCandidate = false)
    QuizService quizService() {
        return new QuizService(banks, attempts, sessions, materials, subjects, notes, files, aiDocuments, codec, assistant,
                storage, awardExperience, events, clock, new Random());
    }

    @Bean
    GetQuestionBankUseCase getQuestionBankUseCase() {
        return tx.wrap(GetQuestionBankUseCase.class, quizService());
    }

    @Bean
    GenerateQuestionBankUseCase generateQuestionBankUseCase() {
        return tx.wrap(GenerateQuestionBankUseCase.class, quizService());
    }

    @Bean
    AnswerQuestionUseCase answerQuestionUseCase() {
        return tx.wrap(AnswerQuestionUseCase.class, quizService());
    }

    @Bean
    CompleteBankPracticeUseCase completeBankPracticeUseCase() {
        return tx.wrap(CompleteBankPracticeUseCase.class, quizService());
    }

    @Bean
    StartTestSessionUseCase startTestSessionUseCase() {
        return tx.wrap(StartTestSessionUseCase.class, quizService());
    }

    @Bean
    GetTestSessionUseCase getTestSessionUseCase() {
        return tx.wrap(GetTestSessionUseCase.class, quizService());
    }

    @Bean
    GetActiveTestSessionUseCase getActiveTestSessionUseCase() {
        return tx.wrap(GetActiveTestSessionUseCase.class, quizService());
    }

    @Bean
    ListTestSessionsUseCase listTestSessionsUseCase() {
        return tx.wrap(ListTestSessionsUseCase.class, quizService());
    }

    @Bean
    AnswerTestQuestionUseCase answerTestQuestionUseCase() {
        return tx.wrap(AnswerTestQuestionUseCase.class, quizService());
    }

    @Bean
    CompleteTestSessionUseCase completeTestSessionUseCase() {
        return tx.wrap(CompleteTestSessionUseCase.class, quizService());
    }

    @Bean
    AbandonTestSessionUseCase abandonTestSessionUseCase() {
        return tx.wrap(AbandonTestSessionUseCase.class, quizService());
    }
}
