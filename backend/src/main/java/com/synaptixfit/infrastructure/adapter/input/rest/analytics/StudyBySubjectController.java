package com.synaptixfit.infrastructure.adapter.input.rest.analytics;

import com.synaptixfit.application.port.input.analytics.GetStudyBySubjectUseCase;
import com.synaptixfit.domain.model.analytics.StudyBySubject;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Analítica de estudio por asignatura: horas por semana y cómo van los repasos. */
@Tag(name = "Analytics")
@RestController
@RequestMapping("/api/v1/analytics")
public class StudyBySubjectController {

    /** Asignatura: {@code subjectId} nulo = lo estudiado sin asignatura; {@code name} nulo = archivada. */
    public record SubjectResponse(UUID subjectId, String name, int totalMinutes, List<Integer> minutesByWeek,
                                  int reviews, Double recallRate, boolean weak) {
    }

    public record StudyBySubjectResponse(LocalDate firstWeek, int weeks, List<SubjectResponse> subjects) {

        static StudyBySubjectResponse from(StudyBySubject s) {
            return new StudyBySubjectResponse(s.firstWeek(), s.weeks(), s.subjects().stream()
                    .map(x -> new SubjectResponse(x.subjectId(), x.name(), x.totalMinutes(), x.minutesByWeek(),
                            x.reviews(), x.recallRate(), x.weak()))
                    .toList());
        }
    }

    private final GetStudyBySubjectUseCase studyBySubject;

    public StudyBySubjectController(GetStudyBySubjectUseCase studyBySubject) {
        this.studyBySubject = studyBySubject;
    }

    @GetMapping("/study-subjects")
    public StudyBySubjectResponse studySubjects(@CurrentUserId UUID userId,
                                                @RequestParam(defaultValue = "4") int weeks,
                                                @RequestParam(required = false) String zone) {
        return StudyBySubjectResponse.from(studyBySubject.getStudyBySubject(userId, weeks, zone));
    }
}
