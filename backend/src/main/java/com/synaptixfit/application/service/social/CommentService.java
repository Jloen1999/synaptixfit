package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.social.AddCommentUseCase;
import com.synaptixfit.application.port.input.social.DeleteCommentUseCase;
import com.synaptixfit.application.port.input.social.EditCommentUseCase;
import com.synaptixfit.application.port.input.social.ListCommentsUseCase;
import com.synaptixfit.application.port.input.social.ReportCommentUseCase;
import com.synaptixfit.domain.exception.social.CommentNotFoundException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.Comment;
import com.synaptixfit.domain.model.social.CommentView;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.port.output.social.CommentRepositoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.social.PostRepositoryPort;
import com.synaptixfit.domain.port.output.social.SocialQueryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.UUID;

/** Comentarios de las publicaciones del muro. */
public class CommentService implements ListCommentsUseCase, AddCommentUseCase, EditCommentUseCase,
        DeleteCommentUseCase, ReportCommentUseCase {

    private final CommentRepositoryPort comments;
    private final PostRepositoryPort posts;
    private final SocialQueryPort queries;
    private final SocialAccess access;
    private final SocialNotifier notifier;
    private final Clock clock;

    public CommentService(CommentRepositoryPort comments, PostRepositoryPort posts, SocialQueryPort queries,
                          UserRepositoryPort users, FriendshipRepositoryPort friendships,
                          CreateNotificationUseCase notifications, Clock clock) {
        this.comments = comments;
        this.posts = posts;
        this.queries = queries;
        this.access = new SocialAccess(posts, users, friendships);
        this.notifier = new SocialNotifier(notifications, users);
        this.clock = clock;
    }

    @Override
    public PageResult<CommentView> listComments(UUID viewerId, UUID postId, PageRequest page) {
        access.visiblePost(viewerId, postId);
        return queries.comments(viewerId, postId, page);
    }

    @Override
    public CommentView addComment(AddCommentUseCase.Command command) {
        Post post = access.visiblePost(command.userId(), command.postId());
        Comment comment = Comment.write(post.id(), command.userId(), command.text(), clock.instant());
        comments.save(comment);
        notifier.postCommented(post.authorId(), post.id(), command.userId());
        return view(comment.id());
    }

    @Override
    public CommentView editComment(EditCommentUseCase.Command command) {
        Comment comment = accessible(command.userId(), command.commentId());
        comment.edit(command.userId(), command.text(), clock.instant());
        comments.save(comment);
        return view(comment.id());
    }

    @Override
    public void deleteComment(UUID userId, UUID commentId) {
        Comment comment = accessible(userId, commentId);
        comment.delete(userId);
        comments.save(comment);
    }

    @Override
    public void reportComment(UUID userId, UUID commentId) {
        Comment comment = accessible(userId, commentId);
        comment.report(userId);
        comments.save(comment);
    }

    /**
     * Comentario no borrado que el usuario puede ver. Su autor siempre lo alcanza (aunque haya
     * perdido acceso a la publicación); el resto necesita ver la publicación y al comentarista.
     */
    private Comment accessible(UUID userId, UUID commentId) {
        Comment comment = comments.findById(commentId)
                .filter(c -> !c.deleted())
                .orElseThrow(() -> new CommentNotFoundException(commentId));
        if (comment.isAuthoredBy(userId)) {
            return comment;
        }
        Post post = posts.findById(comment.postId()).orElseThrow(() -> new CommentNotFoundException(commentId));
        if (!access.canViewContentOf(userId, post.authorId())
                || !access.canSeeInteractionsOf(userId, comment.authorId())) {
            throw new CommentNotFoundException(commentId);
        }
        return comment;
    }

    private CommentView view(UUID commentId) {
        return queries.findComment(commentId).orElseThrow(() -> new CommentNotFoundException(commentId));
    }
}
