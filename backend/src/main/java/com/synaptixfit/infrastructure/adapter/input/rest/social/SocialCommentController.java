package com.synaptixfit.infrastructure.adapter.input.rest.social;

import com.synaptixfit.application.port.input.social.DeleteCommentUseCase;
import com.synaptixfit.application.port.input.social.EditCommentUseCase;
import com.synaptixfit.application.port.input.social.ReportCommentUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.CommentRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.CommentResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Edición, borrado y reporte de comentarios. */
@Tag(name = "Social - Comments")
@RestController
@RequestMapping("/api/v1/social/comments")
public class SocialCommentController {

    private final EditCommentUseCase editComment;
    private final DeleteCommentUseCase deleteComment;
    private final ReportCommentUseCase reportComment;

    public SocialCommentController(EditCommentUseCase editComment, DeleteCommentUseCase deleteComment,
                                   ReportCommentUseCase reportComment) {
        this.editComment = editComment;
        this.deleteComment = deleteComment;
        this.reportComment = reportComment;
    }

    @PatchMapping("/{commentId}")
    public CommentResponse edit(@CurrentUserId UUID userId, @PathVariable UUID commentId,
                                @Valid @RequestBody CommentRequest request) {
        return CommentResponse.from(editComment.editComment(new EditCommentUseCase.Command(userId, commentId,
                request.text())), userId);
    }

    @DeleteMapping("/{commentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID commentId) {
        deleteComment.deleteComment(userId, commentId);
    }

    @PostMapping("/{commentId}/report")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void report(@CurrentUserId UUID userId, @PathVariable UUID commentId) {
        reportComment.reportComment(userId, commentId);
    }
}
