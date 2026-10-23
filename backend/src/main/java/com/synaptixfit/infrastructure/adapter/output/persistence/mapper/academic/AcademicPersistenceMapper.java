package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic;

import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.Question;
import com.synaptixfit.domain.model.academic.QuestionAttempt;
import com.synaptixfit.domain.model.academic.QuestionBank;
import com.synaptixfit.domain.model.academic.ReviewRecord;
import com.synaptixfit.domain.model.academic.SpacedRepetition;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.Subject;
import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.model.academic.SubjectSemester;
import com.synaptixfit.domain.model.academic.TestSession;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.AiDocumentEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.NoteEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.QuestionAttemptEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.QuestionBankEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.QuestionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.ReviewRecordEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.StudyMaterialEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectFileEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectSemesterEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.TestSessionEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.VisibilityDbMapper;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Modelos del dominio académico ↔ entidades JPA. Sin lógica de negocio. */
public final class AcademicPersistenceMapper {

    private AcademicPersistenceMapper() {
    }

    // ------------------------------------------------------------------ asignaturas

    public static Subject toDomain(SubjectEntity e) {
        return Subject.builder()
                .id(e.getId()).userId(e.getUserId()).name(e.getName()).code(e.getCode())
                .description(e.getDescription()).credits(e.getCredits())
                .perceivedDifficulty(e.getPerceivedDifficulty()).priority(AcademicDbCodes.priority(e.getPriority()))
                .nextAssessmentAt(e.getNextAssessmentAt()).teacher(e.getTeacher()).archived(e.isArchived())
                .catalogSubjectId(e.getCatalogSubjectId()).icsUrl(e.getIcsUrl()).lastSyncedAt(e.getLastSyncedAt())
                .createdAt(e.getCreatedAt())
                .build();
    }

    public static void copy(Subject s, SubjectEntity e) {
        e.setId(s.id());
        e.setUserId(s.userId());
        e.setName(s.name());
        e.setCode(s.code());
        e.setDescription(s.description());
        e.setCredits(s.credits());
        e.setPerceivedDifficulty(s.perceivedDifficulty());
        e.setPriority(AcademicDbCodes.priority(s.priority()));
        e.setNextAssessmentAt(s.nextAssessmentAt());
        e.setTeacher(s.teacher());
        e.setArchived(s.archived());
        e.setCatalogSubjectId(s.catalogSubjectId());
        e.setIcsUrl(s.icsUrl());
        e.setLastSyncedAt(s.lastSyncedAt());
        e.setCreatedAt(s.createdAt());
    }

    public static SubjectSemester toDomain(SubjectSemesterEntity e) {
        return new SubjectSemester(e.getId(), e.getUserId(), e.getSubjectId(), e.getCourse(), e.getSemester(),
                e.getCreatedAt());
    }

    public static void copy(SubjectSemester s, SubjectSemesterEntity e) {
        e.setId(s.id());
        e.setUserId(s.userId());
        e.setSubjectId(s.subjectId());
        e.setCourse(s.course());
        e.setSemester(s.semester());
        e.setCreatedAt(s.createdAt());
    }

    // ------------------------------------------------------------------ apuntes y archivos

    public static Note toDomain(NoteEntity e) {
        return new Note(e.getId(), e.getUserId(), e.getSubjectId(), e.getTitle(), e.getContent(),
                VisibilityDbMapper.toDomain(e.getVisibility()), e.isQuickNote(), e.getCreatedAt(), e.getUpdatedAt());
    }

    public static void copy(Note n, NoteEntity e) {
        e.setId(n.id());
        e.setUserId(n.userId());
        e.setSubjectId(n.subjectId());
        e.setTitle(n.title());
        e.setContent(n.content());
        e.setVisibility(VisibilityDbMapper.toDb(n.visibility()));
        e.setQuickNote(n.quickNote());
        e.setCreatedAt(n.createdAt());
        e.setUpdatedAt(n.updatedAt());
    }

    public static SubjectFile toDomain(SubjectFileEntity e) {
        return new SubjectFile(e.getId(), e.getUserId(), e.getSubjectId(), e.getFileName(), e.getObjectKey(),
                e.getStoredUrl(), e.getSizeBytes(), e.getMimeType(), e.getCreatedAt());
    }

    public static void copy(SubjectFile f, SubjectFileEntity e) {
        e.setId(f.id());
        e.setUserId(f.userId());
        e.setSubjectId(f.subjectId());
        e.setFileName(f.fileName());
        e.setObjectKey(f.objectKey());
        e.setStoredUrl(f.storedUrl());
        e.setSizeBytes(f.sizeBytes());
        e.setMimeType(f.mimeType());
        e.setCreatedAt(f.createdAt());
    }

    // ------------------------------------------------------------------ documentos IA y materiales

    public static AiDocument toDomain(AiDocumentEntity e) {
        return new AiDocument(e.getId(), e.getUserId(), e.getSubjectId(), AcademicDbCodes.documentSource(e.getSourceType()),
                e.getSourceId(), AcademicDbCodes.documentType(e.getType()), e.getSourceTitle(), e.getContent(),
                e.getCreatedAt(), e.getUpdatedAt());
    }

    public static void copy(AiDocument d, AiDocumentEntity e) {
        e.setId(d.id());
        e.setUserId(d.userId());
        e.setSubjectId(d.subjectId());
        e.setSourceType(AcademicDbCodes.documentSource(d.source()));
        e.setSourceId(d.sourceId());
        e.setType(AcademicDbCodes.documentType(d.type()));
        e.setSourceTitle(d.sourceTitle());
        e.setContent(d.content());
        e.setCreatedAt(d.createdAt());
        e.setUpdatedAt(d.updatedAt());
    }

    public static StudyMaterial toDomain(StudyMaterialEntity e) {
        return StudyMaterial.builder()
                .id(e.getId()).userId(e.getUserId()).subjectId(e.getSubjectId())
                .originType(AcademicDbCodes.sourceType(e.getOriginType())).originId(e.getOriginId())
                .title(e.getTitle()).masteryState(AcademicDbCodes.mastery(e.getMasteryState()))
                .lastReviewedAt(e.getLastReviewedAt()).nextReviewAt(e.getNextReviewAt())
                .intervalDays(e.getIntervalDays() == null ? 0 : e.getIntervalDays())
                .easeFactor(e.getEaseFactor() == null ? SpacedRepetition.INITIAL_EASE : e.getEaseFactor())
                .completedReviews(e.getCompletedReviews() == null ? 0 : e.getCompletedReviews())
                .failedReviews(e.getFailedReviews() == null ? 0 : e.getFailedReviews())
                .practiceXpAwarded(e.isPracticeXpAwarded()).createdAt(e.getCreatedAt())
                .build();
    }

    public static void copy(StudyMaterial m, StudyMaterialEntity e) {
        e.setId(m.id());
        e.setUserId(m.userId());
        e.setSubjectId(m.subjectId());
        e.setOriginType(AcademicDbCodes.sourceType(m.originType()));
        e.setOriginId(m.originId());
        e.setTitle(m.title());
        e.setMasteryState(AcademicDbCodes.mastery(m.masteryState()));
        e.setLastReviewedAt(m.lastReviewedAt());
        e.setNextReviewAt(m.nextReviewAt());
        e.setIntervalDays(m.intervalDays());
        e.setEaseFactor((float) m.easeFactor());
        e.setCompletedReviews(m.completedReviews());
        e.setFailedReviews(m.failedReviews());
        e.setPracticeXpAwarded(m.practiceXpAwarded());
        e.setCreatedAt(m.createdAt());
    }

    public static ReviewRecord toDomain(ReviewRecordEntity e) {
        return new ReviewRecord(e.getId(), e.getStudyMaterialId(), e.getReviewedAt(), e.getRealQuality(),
                e.getAdjustedQuality().doubleValue(), e.getFatigueCoefficient().doubleValue());
    }

    public static ReviewRecordEntity toEntity(ReviewRecord r) {
        ReviewRecordEntity e = new ReviewRecordEntity();
        e.setId(r.id());
        e.setStudyMaterialId(r.studyMaterialId());
        e.setReviewedAt(r.reviewedAt());
        e.setRealQuality((short) r.realQuality());
        e.setAdjustedQuality(BigDecimal.valueOf(r.adjustedQuality()).setScale(2, RoundingMode.HALF_UP));
        e.setFatigueCoefficient(BigDecimal.valueOf(r.fatigueCoefficient()).setScale(3, RoundingMode.HALF_UP));
        e.setCreatedAt(r.reviewedAt());
        return e;
    }

    // ------------------------------------------------------------------ preguntas y sesiones

    public static QuestionBank toDomain(QuestionBankEntity e) {
        return new QuestionBank(e.getId(), e.getMaterialId(), e.getUserId(), e.isXpAwarded(), e.getGeneratedAt());
    }

    public static void copy(QuestionBank b, QuestionBankEntity e) {
        e.setId(b.id());
        e.setMaterialId(b.materialId());
        e.setUserId(b.userId());
        e.setXpAwarded(b.xpAwarded());
        e.setGeneratedAt(b.generatedAt());
    }

    public static Question toDomain(QuestionEntity e) {
        return new Question(e.getId(), e.getBankId(), AcademicDbCodes.questionType(e.getType()), e.getStatement(),
                e.getOptions() == null ? List.of() : e.getOptions(), e.getCorrectAnswer(), e.getExplanation(),
                e.getPosition());
    }

    public static QuestionEntity toEntity(Question q) {
        QuestionEntity e = new QuestionEntity();
        e.setId(q.id());
        e.setBankId(q.bankId());
        e.setType(AcademicDbCodes.questionType(q.type()));
        e.setStatement(q.statement());
        e.setOptions(q.options().isEmpty() ? null : q.options());
        e.setCorrectAnswer(q.correctAnswer());
        e.setExplanation(q.explanation());
        e.setPosition(q.order());
        return e;
    }

    public static QuestionAttempt toDomain(QuestionAttemptEntity e) {
        return new QuestionAttempt(e.getId(), e.getUserId(), e.getQuestionId(), e.isCorrect(), e.getAnsweredAt());
    }

    public static QuestionAttemptEntity toEntity(QuestionAttempt a) {
        QuestionAttemptEntity e = new QuestionAttemptEntity();
        e.setId(a.id());
        e.setUserId(a.userId());
        e.setQuestionId(a.questionId());
        e.setCorrect(a.correct());
        e.setAnsweredAt(a.answeredAt());
        return e;
    }

    public static TestSession toDomain(TestSessionEntity e) {
        Map<UUID, String> answers = new LinkedHashMap<>();
        if (e.getAnswers() != null) {
            e.getAnswers().forEach((k, v) -> answers.put(UUID.fromString(k), v));
        }
        Map<UUID, Boolean> results = new LinkedHashMap<>();
        if (e.getResults() != null) {
            e.getResults().forEach((k, v) -> results.put(UUID.fromString(k), Boolean.TRUE.equals(v)));
        }
        List<UUID> ids = e.getQuestionIds() == null ? List.of()
                : e.getQuestionIds().stream().map(UUID::fromString).toList();
        return new TestSession(e.getId(), e.getUserId(), e.getMaterialId(), ids, answers, results, e.getCurrentIndex(),
                AcademicDbCodes.sessionStatus(e.getStatus()), e.getStartedAt(), e.getCompletedAt(), e.isXpAwarded());
    }

    public static void copy(TestSession s, TestSessionEntity e) {
        e.setId(s.id());
        e.setUserId(s.userId());
        e.setMaterialId(s.materialId());
        e.setQuestionIds(s.questionIds().stream().map(UUID::toString).toList());
        Map<String, String> answers = new LinkedHashMap<>();
        s.answers().forEach((k, v) -> answers.put(k.toString(), v));
        e.setAnswers(answers);
        Map<String, Boolean> results = new LinkedHashMap<>();
        s.results().forEach((k, v) -> results.put(k.toString(), v));
        e.setResults(results);
        e.setCurrentIndex(s.currentIndex());
        e.setStatus(AcademicDbCodes.sessionStatus(s.status()));
        e.setScore(s.score());
        e.setTotalQuestions(s.totalQuestions());
        e.setStartedAt(s.startedAt());
        e.setCompletedAt(s.completedAt());
        e.setXpAwarded(s.xpAwarded());
    }
}
