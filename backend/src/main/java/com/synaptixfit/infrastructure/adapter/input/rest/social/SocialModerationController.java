package com.synaptixfit.infrastructure.adapter.input.rest.social;

import com.synaptixfit.application.port.input.social.DismissReportUseCase;
import com.synaptixfit.application.port.input.social.ListReportedContentUseCase;
import com.synaptixfit.application.port.input.social.RemoveReportedContentUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.social.ReportedContentType;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.ReportedContentResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Moderación de contenido social reportado (solo ADMIN; lo exige {@code SecurityConfig}). */
@Tag(name = "Admin - Social moderation")
@RestController
@RequestMapping("/api/v1/admin/social")
public class SocialModerationController {

    private final ListReportedContentUseCase listReported;
    private final DismissReportUseCase dismissReport;
    private final RemoveReportedContentUseCase removeContent;

    public SocialModerationController(ListReportedContentUseCase listReported, DismissReportUseCase dismissReport,
                                      RemoveReportedContentUseCase removeContent) {
        this.listReported = listReported;
        this.dismissReport = dismissReport;
        this.removeContent = removeContent;
    }

    @GetMapping("/reports")
    public PageResponse<ReportedContentResponse> reports(@RequestParam(required = false) ReportedContentType type,
                                                         @RequestParam(defaultValue = "0") int page,
                                                         @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listReported.listReported(type, new PageRequest(page, size)),
                ReportedContentResponse::from);
    }

    @PostMapping("/posts/{postId}/dismiss-report")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void dismissPostReport(@CurrentUserId UUID adminId, @PathVariable UUID postId) {
        dismissReport.dismiss(adminId, ReportedContentType.POST, postId);
    }

    @DeleteMapping("/posts/{postId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removePost(@CurrentUserId UUID adminId, @PathVariable UUID postId) {
        removeContent.remove(adminId, ReportedContentType.POST, postId);
    }

    @PostMapping("/comments/{commentId}/dismiss-report")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void dismissCommentReport(@CurrentUserId UUID adminId, @PathVariable UUID commentId) {
        dismissReport.dismiss(adminId, ReportedContentType.COMMENT, commentId);
    }

    @DeleteMapping("/comments/{commentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeComment(@CurrentUserId UUID adminId, @PathVariable UUID commentId) {
        removeContent.remove(adminId, ReportedContentType.COMMENT, commentId);
    }
}
