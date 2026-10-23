package com.synaptixfit.infrastructure.adapter.input.rest.social;

import com.synaptixfit.application.port.input.social.AddCommentUseCase;
import com.synaptixfit.application.port.input.social.CreatePostUseCase;
import com.synaptixfit.application.port.input.social.DeletePostUseCase;
import com.synaptixfit.application.port.input.social.EditPostUseCase;
import com.synaptixfit.application.port.input.social.GetFeedUseCase;
import com.synaptixfit.application.port.input.social.GetPostUseCase;
import com.synaptixfit.application.port.input.social.LikePostUseCase;
import com.synaptixfit.application.port.input.social.ListCommentsUseCase;
import com.synaptixfit.application.port.input.social.ReportPostUseCase;
import com.synaptixfit.application.port.input.social.UnlikePostUseCase;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.social.FeedPeriod;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.CommentRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.CommentResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.CreatePostRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.EditPostRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.LikeStatusResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.PostResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.Instant;
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

/**
 * Muro social: publicaciones, «me gusta» y comentarios de una publicación. Sustituye a Supabase
 * Realtime: el cliente sondea {@code GET /posts?since=<createdAt más reciente>}.
 */
@Tag(name = "Social - Posts")
@RestController
@RequestMapping("/api/v1/social/posts")
public class SocialPostController {

    private final GetFeedUseCase getFeed;
    private final GetPostUseCase getPost;
    private final CreatePostUseCase createPost;
    private final EditPostUseCase editPost;
    private final DeletePostUseCase deletePost;
    private final ReportPostUseCase reportPost;
    private final LikePostUseCase likePost;
    private final UnlikePostUseCase unlikePost;
    private final ListCommentsUseCase listComments;
    private final AddCommentUseCase addComment;
    private final PostResponseMapper mapper;

    public SocialPostController(GetFeedUseCase getFeed, GetPostUseCase getPost, CreatePostUseCase createPost,
                                EditPostUseCase editPost, DeletePostUseCase deletePost, ReportPostUseCase reportPost,
                                LikePostUseCase likePost, UnlikePostUseCase unlikePost,
                                ListCommentsUseCase listComments, AddCommentUseCase addComment,
                                PostResponseMapper mapper) {
        this.getFeed = getFeed;
        this.getPost = getPost;
        this.createPost = createPost;
        this.editPost = editPost;
        this.deletePost = deletePost;
        this.reportPost = reportPost;
        this.likePost = likePost;
        this.unlikePost = unlikePost;
        this.listComments = listComments;
        this.addComment = addComment;
        this.mapper = mapper;
    }

    @GetMapping
    public PageResponse<PostResponse> feed(@CurrentUserId UUID userId,
                                           @RequestParam(defaultValue = "ALL") FeedPeriod period,
                                           @RequestParam(required = false) Instant since,
                                           @RequestParam(required = false) UUID authorId,
                                           @RequestParam(defaultValue = "0") int page,
                                           @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(getFeed.getFeed(new GetFeedUseCase.Query(userId, period, since, authorId,
                new PageRequest(page, size))), p -> mapper.toResponse(p, userId));
    }

    @GetMapping("/{postId}")
    public PostResponse get(@CurrentUserId UUID userId, @PathVariable UUID postId) {
        return mapper.toResponse(getPost.getPost(userId, postId), userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PostResponse create(@CurrentUserId UUID userId, @Valid @RequestBody CreatePostRequest request) {
        return mapper.toResponse(createPost.createPost(new CreatePostUseCase.Command(userId, request.type(),
                request.description(), request.imageUrl(), mapper.writeMetadata(request.metadata()))), userId);
    }

    @PatchMapping("/{postId}")
    public PostResponse edit(@CurrentUserId UUID userId, @PathVariable UUID postId,
                             @Valid @RequestBody EditPostRequest request) {
        return mapper.toResponse(editPost.editPost(new EditPostUseCase.Command(userId, postId,
                request.description(), request.imageUrl())), userId);
    }

    @DeleteMapping("/{postId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID postId) {
        deletePost.deletePost(userId, postId);
    }

    @PostMapping("/{postId}/report")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void report(@CurrentUserId UUID userId, @PathVariable UUID postId) {
        reportPost.reportPost(userId, postId);
    }

    @PutMapping("/{postId}/like")
    public LikeStatusResponse like(@CurrentUserId UUID userId, @PathVariable UUID postId) {
        return LikeStatusResponse.from(likePost.like(userId, postId));
    }

    @DeleteMapping("/{postId}/like")
    public LikeStatusResponse unlike(@CurrentUserId UUID userId, @PathVariable UUID postId) {
        return LikeStatusResponse.from(unlikePost.unlike(userId, postId));
    }

    @GetMapping("/{postId}/comments")
    public PageResponse<CommentResponse> comments(@CurrentUserId UUID userId, @PathVariable UUID postId,
                                                  @RequestParam(defaultValue = "0") int page,
                                                  @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listComments.listComments(userId, postId, new PageRequest(page, size)),
                c -> CommentResponse.from(c, userId));
    }

    @PostMapping("/{postId}/comments")
    @ResponseStatus(HttpStatus.CREATED)
    public CommentResponse addComment(@CurrentUserId UUID userId, @PathVariable UUID postId,
                                      @Valid @RequestBody CommentRequest request) {
        return CommentResponse.from(addComment.addComment(new AddCommentUseCase.Command(userId, postId,
                request.text())), userId);
    }
}
