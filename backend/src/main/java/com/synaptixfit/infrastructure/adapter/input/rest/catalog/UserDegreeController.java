package com.synaptixfit.infrastructure.adapter.input.rest.catalog;

import com.synaptixfit.application.port.input.catalog.LinkDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.ListMyCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.catalog.ListMyDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.UnlinkDegreeUseCase;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto.UserCatalogSubjectResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto.UserDegreeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Carreras vinculadas por el usuario y su plan de estudios (selector de asignaturas). */
@Tag(name = "Profile degrees")
@RestController
@RequestMapping("/api/v1/profile/degrees")
public class UserDegreeController {

    private final ListMyDegreesUseCase listMyDegrees;
    private final LinkDegreeUseCase linkDegree;
    private final UnlinkDegreeUseCase unlinkDegree;
    private final ListMyCatalogSubjectsUseCase listMySubjects;

    public UserDegreeController(ListMyDegreesUseCase listMyDegrees, LinkDegreeUseCase linkDegree,
                                UnlinkDegreeUseCase unlinkDegree, ListMyCatalogSubjectsUseCase listMySubjects) {
        this.listMyDegrees = listMyDegrees;
        this.linkDegree = linkDegree;
        this.unlinkDegree = unlinkDegree;
        this.listMySubjects = listMySubjects;
    }

    @GetMapping
    public List<UserDegreeResponse> list(@CurrentUserId UUID userId) {
        return listMyDegrees.listMyDegrees(userId).stream().map(UserDegreeResponse::from).toList();
    }

    @PutMapping("/{degreeId}")
    public UserDegreeResponse link(@CurrentUserId UUID userId, @PathVariable UUID degreeId) {
        return UserDegreeResponse.from(linkDegree.linkDegree(userId, degreeId));
    }

    @DeleteMapping("/{degreeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void unlink(@CurrentUserId UUID userId, @PathVariable UUID degreeId) {
        unlinkDegree.unlinkDegree(userId, degreeId);
    }

    @GetMapping("/subjects")
    public PageResponse<UserCatalogSubjectResponse> subjects(@CurrentUserId UUID userId,
                                                             @RequestParam(required = false) Integer course,
                                                             @RequestParam(required = false) Integer semester,
                                                             @RequestParam(required = false) String character,
                                                             @RequestParam(required = false) String q,
                                                             @RequestParam(defaultValue = "0") int page,
                                                             @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listMySubjects.listMyCatalogSubjects(userId,
                new CatalogSubjectFilter(course, semester, character, q), new PageRequest(page, size)),
                UserCatalogSubjectResponse::from);
    }
}
