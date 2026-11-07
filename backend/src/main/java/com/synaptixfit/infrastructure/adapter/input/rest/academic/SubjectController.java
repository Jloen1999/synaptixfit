package com.synaptixfit.infrastructure.adapter.input.rest.academic;

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
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.SubjectDtos.CatalogSubjectResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.SubjectDtos.CreateFromCatalogRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.SubjectDtos.CreateSubjectRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.SubjectDtos.SubjectResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.SubjectDtos.SubjectSemesterRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.SubjectDtos.SubjectSemesterResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.academic.dto.SubjectDtos.UpdateSubjectRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Asignaturas del usuario, creación desde el catálogo y curso/semestre. */
@Tag(name = "Academic - Subjects")
@RestController
@RequestMapping("/api/v1/subjects")
public class SubjectController {

    private final ListSubjectsUseCase listSubjects;
    private final GetSubjectUseCase getSubject;
    private final CreateSubjectUseCase createSubject;
    private final UpdateSubjectUseCase updateSubject;
    private final DeleteSubjectUseCase deleteSubject;
    private final ListCatalogSubjectsUseCase listCatalog;
    private final CreateSubjectsFromCatalogUseCase createFromCatalog;
    private final ListSubjectSemestersUseCase listSemesters;
    private final AssignSubjectSemesterUseCase assignSemester;
    private final RemoveSubjectSemesterUseCase removeSemester;

    public SubjectController(ListSubjectsUseCase listSubjects, GetSubjectUseCase getSubject,
                             CreateSubjectUseCase createSubject, UpdateSubjectUseCase updateSubject,
                             DeleteSubjectUseCase deleteSubject, ListCatalogSubjectsUseCase listCatalog,
                             CreateSubjectsFromCatalogUseCase createFromCatalog,
                             ListSubjectSemestersUseCase listSemesters, AssignSubjectSemesterUseCase assignSemester,
                             RemoveSubjectSemesterUseCase removeSemester) {
        this.listSubjects = listSubjects;
        this.getSubject = getSubject;
        this.createSubject = createSubject;
        this.updateSubject = updateSubject;
        this.deleteSubject = deleteSubject;
        this.listCatalog = listCatalog;
        this.createFromCatalog = createFromCatalog;
        this.listSemesters = listSemesters;
        this.assignSemester = assignSemester;
        this.removeSemester = removeSemester;
    }

    /** {@code archived}: ausente o false → activas; true → archivadas. */
    @GetMapping
    public List<SubjectResponse> list(@CurrentUserId UUID userId,
                                      @RequestParam(defaultValue = "false") boolean archived) {
        return listSubjects.listSubjects(userId, archived).stream().map(SubjectResponse::from).toList();
    }

    @GetMapping("/{subjectId}")
    public SubjectResponse get(@CurrentUserId UUID userId, @PathVariable UUID subjectId) {
        return SubjectResponse.from(getSubject.getSubject(userId, subjectId));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public SubjectResponse create(@CurrentUserId UUID userId, @Valid @RequestBody CreateSubjectRequest r) {
        return SubjectResponse.from(createSubject.createSubject(new CreateSubjectUseCase.Command(userId, r.name(),
                r.code(), r.description(), r.credits(), r.perceivedDifficulty(), r.priority(), r.nextAssessmentAt(),
                r.teacher(), r.icsUrl(), r.room())));
    }

    @PatchMapping("/{subjectId}")
    public SubjectResponse update(@CurrentUserId UUID userId, @PathVariable UUID subjectId,
                                  @Valid @RequestBody UpdateSubjectRequest r) {
        return SubjectResponse.from(updateSubject.updateSubject(new UpdateSubjectUseCase.Command(userId, subjectId,
                r.name(), r.code(), r.description(), r.credits(), r.perceivedDifficulty(), r.priority(),
                r.nextAssessmentAt(), Boolean.TRUE.equals(r.clearNextAssessment()), r.teacher(), r.icsUrl(), r.archived(),
                r.room())));
    }

    @DeleteMapping("/{subjectId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID subjectId) {
        deleteSubject.deleteSubject(userId, subjectId);
    }

    @GetMapping("/catalog")
    public List<CatalogSubjectResponse> catalog(@CurrentUserId UUID userId) {
        return listCatalog.listCatalogSubjects(userId).stream().map(CatalogSubjectResponse::from).toList();
    }

    @PostMapping("/from-catalog")
    @ResponseStatus(HttpStatus.CREATED)
    public List<SubjectResponse> fromCatalog(@CurrentUserId UUID userId,
                                             @Valid @RequestBody CreateFromCatalogRequest r) {
        return createFromCatalog.createFromCatalog(userId, r.catalogSubjectIds()).stream()
                .map(SubjectResponse::from).toList();
    }

    @GetMapping("/semesters")
    public List<SubjectSemesterResponse> semesters(@CurrentUserId UUID userId) {
        return listSemesters.listSemesters(userId).stream().map(SubjectSemesterResponse::from).toList();
    }

    @PutMapping("/{subjectId}/semester")
    public SubjectSemesterResponse assignSemester(@CurrentUserId UUID userId, @PathVariable UUID subjectId,
                                                  @Valid @RequestBody SubjectSemesterRequest r) {
        return SubjectSemesterResponse.from(assignSemester.assignSemester(userId, subjectId, r.course(),
                r.semester()));
    }

    @DeleteMapping("/{subjectId}/semester")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeSemester(@CurrentUserId UUID userId, @PathVariable UUID subjectId) {
        removeSemester.removeSemester(userId, subjectId);
    }
}
