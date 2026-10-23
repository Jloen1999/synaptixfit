package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import com.synaptixfit.application.port.input.academic.GenerateTeachingGuideUseCase;
import com.synaptixfit.application.port.input.academic.GetTeachingGuideUseCase;
import com.synaptixfit.application.port.input.academic.GradeTeachingGuideAssessmentUseCase;
import com.synaptixfit.application.port.input.academic.SetTeachingGuideModeUseCase;
import com.synaptixfit.application.port.input.academic.UpdateTeachingGuideTopicUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.AssessmentGradeRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.EvaluationModeRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.GenerateTeachingGuideRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.TeachingGuideResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.StudyDtos.TopicUpdateRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Guía docente de la asignatura: extracción con IA, rastreador de temario y calculadora de nota. */
@Tag(name = "Academic - Teaching guide")
@RestController
@RequestMapping("/api/v1/subjects/{subjectId}/teaching-guide")
public class TeachingGuideController {

    private final GetTeachingGuideUseCase getGuide;
    private final GenerateTeachingGuideUseCase generateGuide;
    private final UpdateTeachingGuideTopicUseCase updateTopic;
    private final GradeTeachingGuideAssessmentUseCase gradeAssessment;
    private final SetTeachingGuideModeUseCase setMode;

    public TeachingGuideController(GetTeachingGuideUseCase getGuide, GenerateTeachingGuideUseCase generateGuide,
                                   UpdateTeachingGuideTopicUseCase updateTopic,
                                   GradeTeachingGuideAssessmentUseCase gradeAssessment,
                                   SetTeachingGuideModeUseCase setMode) {
        this.getGuide = getGuide;
        this.generateGuide = generateGuide;
        this.updateTopic = updateTopic;
        this.gradeAssessment = gradeAssessment;
        this.setMode = setMode;
    }

    @GetMapping
    public TeachingGuideResponse get(@CurrentUserId UUID userId, @PathVariable UUID subjectId) {
        return TeachingGuideResponse.from(getGuide.getTeachingGuide(userId, subjectId));
    }

    /** Extrae la guía de un PDF o imagen ya subido a los archivos de la asignatura. */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TeachingGuideResponse generate(@CurrentUserId UUID userId, @PathVariable UUID subjectId,
                                          @Valid @RequestBody GenerateTeachingGuideRequest r) {
        return TeachingGuideResponse.from(generateGuide.generateTeachingGuide(userId, subjectId, r.fileId()));
    }

    @PatchMapping("/topics/{index}")
    public TeachingGuideResponse topic(@CurrentUserId UUID userId, @PathVariable UUID subjectId,
                                       @PathVariable int index, @Valid @RequestBody TopicUpdateRequest r) {
        return TeachingGuideResponse.from(updateTopic.setTopicCompleted(userId, subjectId, index, r.completed()));
    }

    @PatchMapping("/assessments/{index}")
    public TeachingGuideResponse grade(@CurrentUserId UUID userId, @PathVariable UUID subjectId,
                                       @PathVariable int index, @Valid @RequestBody AssessmentGradeRequest r) {
        return TeachingGuideResponse.from(gradeAssessment.setAssessmentGrade(userId, subjectId, index, r.grade()));
    }

    /** Modalidad de evaluación (continua o global) con la que se calcula la nota. */
    @PutMapping("/mode")
    public TeachingGuideResponse mode(@CurrentUserId UUID userId, @PathVariable UUID subjectId,
                                      @Valid @RequestBody EvaluationModeRequest r) {
        return TeachingGuideResponse.from(setMode.setMode(userId, subjectId, r.mode()));
    }
}
