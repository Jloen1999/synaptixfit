package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.social.AcceptFriendRequestUseCase;
import com.synaptixfit.application.port.input.social.AddCommentUseCase;
import com.synaptixfit.application.port.input.social.BlockUserUseCase;
import com.synaptixfit.application.port.input.social.CreatePostUseCase;
import com.synaptixfit.application.port.input.social.PublishAchievementPostUseCase;
import com.synaptixfit.application.port.input.social.DeleteCommentUseCase;
import com.synaptixfit.application.port.input.social.DeletePostUseCase;
import com.synaptixfit.application.port.input.social.DismissReportUseCase;
import com.synaptixfit.application.port.input.social.EditCommentUseCase;
import com.synaptixfit.application.port.input.social.EditPostUseCase;
import com.synaptixfit.application.port.input.social.GetFeedUseCase;
import com.synaptixfit.application.port.input.social.GetPostUseCase;
import com.synaptixfit.application.port.input.social.GetPublicProfileUseCase;
import com.synaptixfit.application.port.input.social.LikePostUseCase;
import com.synaptixfit.application.port.input.social.ListCommentsUseCase;
import com.synaptixfit.application.port.input.social.ListFriendshipsUseCase;
import com.synaptixfit.application.port.input.social.ListReportedContentUseCase;
import com.synaptixfit.application.port.input.social.RejectFriendRequestUseCase;
import com.synaptixfit.application.port.input.social.RemoveFriendshipUseCase;
import com.synaptixfit.application.port.input.social.RemoveReportedContentUseCase;
import com.synaptixfit.application.port.input.social.ReportCommentUseCase;
import com.synaptixfit.application.port.input.social.ReportPostUseCase;
import com.synaptixfit.application.port.input.social.SearchUsersUseCase;
import com.synaptixfit.application.port.input.social.SendFriendRequestUseCase;
import com.synaptixfit.application.port.input.social.UnlikePostUseCase;
import com.synaptixfit.application.service.social.CommentService;
import com.synaptixfit.application.service.social.FriendshipService;
import com.synaptixfit.application.service.social.ModerationService;
import com.synaptixfit.application.service.social.PostService;
import com.synaptixfit.application.service.social.SocialProfileService;
import com.synaptixfit.domain.port.output.social.CommentRepositoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.social.ModerationAuditPort;
import com.synaptixfit.domain.port.output.social.PostLikeRepositoryPort;
import com.synaptixfit.domain.port.output.social.PostRepositoryPort;
import com.synaptixfit.domain.port.output.social.ReportedContentQueryPort;
import com.synaptixfit.domain.port.output.social.SocialQueryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición del módulo social (muro, comentarios, amistades, perfiles y moderación). Las
 * notificaciones sociales se generan a través de {@link CreateNotificationUseCase}.
 */
@Configuration
public class SocialBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final PostRepositoryPort posts;
    private final PostLikeRepositoryPort likes;
    private final CommentRepositoryPort comments;
    private final FriendshipRepositoryPort friendships;
    private final SocialQueryPort queries;
    private final ReportedContentQueryPort reported;
    private final ModerationAuditPort audit;
    private final UserRepositoryPort users;
    private final CreateNotificationUseCase notifications;
    private final Clock clock;
    private final ZoneId zone;

    public SocialBeanConfiguration(TransactionalUseCaseFactory tx, PostRepositoryPort posts,
                                   PostLikeRepositoryPort likes, CommentRepositoryPort comments,
                                   FriendshipRepositoryPort friendships, SocialQueryPort queries,
                                   ReportedContentQueryPort reported, ModerationAuditPort audit,
                                   UserRepositoryPort users, CreateNotificationUseCase notifications, Clock clock,
                                   @Value("${synaptixfit.notifications.zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.posts = posts;
        this.likes = likes;
        this.comments = comments;
        this.friendships = friendships;
        this.queries = queries;
        this.reported = reported;
        this.audit = audit;
        this.users = users;
        this.notifications = notifications;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    // ---------------------------------------------------------------- publicaciones y likes

    @Bean(autowireCandidate = false)
    PostService postService() {
        return new PostService(posts, likes, queries, users, friendships, notifications, clock, zone);
    }

    @Bean
    GetFeedUseCase getFeedUseCase() {
        return tx.wrap(GetFeedUseCase.class, postService());
    }

    @Bean
    GetPostUseCase getPostUseCase() {
        return tx.wrap(GetPostUseCase.class, postService());
    }

    @Bean
    CreatePostUseCase createPostUseCase() {
        return tx.wrap(CreatePostUseCase.class, postService());
    }

    @Bean
    PublishAchievementPostUseCase publishAchievementPostUseCase() {
        return tx.wrap(PublishAchievementPostUseCase.class, postService());
    }

    @Bean
    EditPostUseCase editPostUseCase() {
        return tx.wrap(EditPostUseCase.class, postService());
    }

    @Bean
    DeletePostUseCase deletePostUseCase() {
        return tx.wrap(DeletePostUseCase.class, postService());
    }

    @Bean
    ReportPostUseCase reportPostUseCase() {
        return tx.wrap(ReportPostUseCase.class, postService());
    }

    @Bean
    LikePostUseCase likePostUseCase() {
        return tx.wrap(LikePostUseCase.class, postService());
    }

    @Bean
    UnlikePostUseCase unlikePostUseCase() {
        return tx.wrap(UnlikePostUseCase.class, postService());
    }

    // ---------------------------------------------------------------- comentarios

    @Bean(autowireCandidate = false)
    CommentService commentService() {
        return new CommentService(comments, posts, queries, users, friendships, notifications, clock);
    }

    @Bean
    ListCommentsUseCase listCommentsUseCase() {
        return tx.wrap(ListCommentsUseCase.class, commentService());
    }

    @Bean
    AddCommentUseCase addCommentUseCase() {
        return tx.wrap(AddCommentUseCase.class, commentService());
    }

    @Bean
    EditCommentUseCase editCommentUseCase() {
        return tx.wrap(EditCommentUseCase.class, commentService());
    }

    @Bean
    DeleteCommentUseCase deleteCommentUseCase() {
        return tx.wrap(DeleteCommentUseCase.class, commentService());
    }

    @Bean
    ReportCommentUseCase reportCommentUseCase() {
        return tx.wrap(ReportCommentUseCase.class, commentService());
    }

    // ---------------------------------------------------------------- amistades

    @Bean(autowireCandidate = false)
    FriendshipService friendshipService() {
        return new FriendshipService(friendships, users, queries, notifications, clock);
    }

    @Bean
    SendFriendRequestUseCase sendFriendRequestUseCase() {
        return tx.wrap(SendFriendRequestUseCase.class, friendshipService());
    }

    @Bean
    AcceptFriendRequestUseCase acceptFriendRequestUseCase() {
        return tx.wrap(AcceptFriendRequestUseCase.class, friendshipService());
    }

    @Bean
    RejectFriendRequestUseCase rejectFriendRequestUseCase() {
        return tx.wrap(RejectFriendRequestUseCase.class, friendshipService());
    }

    @Bean
    BlockUserUseCase blockUserUseCase() {
        return tx.wrap(BlockUserUseCase.class, friendshipService());
    }

    @Bean
    RemoveFriendshipUseCase removeFriendshipUseCase() {
        return tx.wrap(RemoveFriendshipUseCase.class, friendshipService());
    }

    @Bean
    ListFriendshipsUseCase listFriendshipsUseCase() {
        return tx.wrap(ListFriendshipsUseCase.class, friendshipService());
    }

    // ---------------------------------------------------------------- perfiles

    @Bean(autowireCandidate = false)
    SocialProfileService socialProfileService() {
        return new SocialProfileService(users, friendships, queries);
    }

    @Bean
    SearchUsersUseCase socialSearchUsersUseCase() {
        return tx.wrap(SearchUsersUseCase.class, socialProfileService());
    }

    @Bean
    GetPublicProfileUseCase getPublicProfileUseCase() {
        return tx.wrap(GetPublicProfileUseCase.class, socialProfileService());
    }

    // ---------------------------------------------------------------- moderación

    @Bean(autowireCandidate = false)
    ModerationService moderationService() {
        return new ModerationService(posts, comments, reported, audit);
    }

    @Bean
    ListReportedContentUseCase listReportedContentUseCase() {
        return tx.wrap(ListReportedContentUseCase.class, moderationService());
    }

    @Bean
    DismissReportUseCase dismissReportUseCase() {
        return tx.wrap(DismissReportUseCase.class, moderationService());
    }

    @Bean
    RemoveReportedContentUseCase removeReportedContentUseCase() {
        return tx.wrap(RemoveReportedContentUseCase.class, moderationService());
    }
}
