package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.social.CreatePostUseCase;
import com.synaptixfit.application.port.input.social.DeletePostUseCase;
import com.synaptixfit.application.port.input.social.EditPostUseCase;
import com.synaptixfit.application.port.input.social.GetFeedUseCase;
import com.synaptixfit.application.port.input.social.GetPostUseCase;
import com.synaptixfit.application.port.input.social.LikePostUseCase;
import com.synaptixfit.application.port.input.social.PublishAchievementPostUseCase;
import com.synaptixfit.application.port.input.social.ReportPostUseCase;
import com.synaptixfit.application.port.input.social.UnlikePostUseCase;
import com.synaptixfit.domain.exception.social.PostAlreadySharedException;
import com.synaptixfit.domain.exception.social.PostNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.FeedPeriod;
import com.synaptixfit.domain.model.social.FeedQuery;
import com.synaptixfit.domain.model.social.LikeStatus;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostView;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.social.PostLikeRepositoryPort;
import com.synaptixfit.domain.port.output.social.PostRepositoryPort;
import com.synaptixfit.domain.port.output.social.SocialQueryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.UUID;

/** Muro social: publicaciones (también las automáticas de logros, sin duplicados) y «me gusta». */
public class PostService implements GetFeedUseCase, GetPostUseCase, CreatePostUseCase, EditPostUseCase,
        DeletePostUseCase, ReportPostUseCase, LikePostUseCase, UnlikePostUseCase, PublishAchievementPostUseCase {

    private final PostRepositoryPort posts;
    private final PostLikeRepositoryPort likes;
    private final SocialQueryPort queries;
    private final SocialAccess access;
    private final SocialNotifier notifier;
    private final Clock clock;
    private final ZoneId zone;

    public PostService(PostRepositoryPort posts, PostLikeRepositoryPort likes, SocialQueryPort queries,
                       UserRepositoryPort users, FriendshipRepositoryPort friendships,
                       CreateNotificationUseCase notifications, Clock clock, ZoneId zone) {
        this.posts = posts;
        this.likes = likes;
        this.queries = queries;
        this.access = new SocialAccess(posts, users, friendships);
        this.notifier = new SocialNotifier(notifications, users);
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public PageResult<PostView> getFeed(GetFeedUseCase.Query query) {
        Guard.notNull(query.page(), "page");
        FeedPeriod period = query.period() == null ? FeedPeriod.ALL : query.period();
        Instant from = period.startFrom(clock.instant(), zone);
        return queries.feed(new FeedQuery(query.viewerId(), query.authorId(), from, query.since(), query.page()));
    }

    @Override
    public PostView getPost(UUID viewerId, UUID postId) {
        Post post = access.visiblePost(viewerId, postId);
        return view(viewerId, post.id());
    }

    @Override
    public PostView createPost(CreatePostUseCase.Command command) {
        if (Post.uniquePerMetadata(command.type(), command.metadata())
                && posts.existsByAuthorTypeAndMetadata(command.userId(), command.type(), command.metadata())) {
            throw new PostAlreadySharedException();
        }
        Post post = Post.publish(command.userId(), command.type(), command.description(), command.imageUrl(),
                command.metadata(), clock.instant());
        posts.save(post);
        return view(command.userId(), post.id());
    }

    @Override
    public boolean publishAchievement(PublishAchievementPostUseCase.Command command) {
        if (posts.existsByAuthorTypeAndMetadata(command.userId(), command.type(), command.metadata())) {
            return false;
        }
        posts.save(Post.publish(command.userId(), command.type(), command.description(), null, command.metadata(),
                clock.instant()));
        return true;
    }

    @Override
    public PostView editPost(EditPostUseCase.Command command) {
        Post post = access.visiblePost(command.userId(), command.postId());
        post.edit(command.userId(), command.description(), command.imageUrl(), clock.instant());
        posts.save(post);
        return view(command.userId(), post.id());
    }

    @Override
    public void deletePost(UUID userId, UUID postId) {
        Post post = access.visiblePost(userId, postId);
        post.ensureCanBeDeletedBy(userId);
        posts.delete(post.id());
    }

    @Override
    public void reportPost(UUID userId, UUID postId) {
        Post post = access.visiblePost(userId, postId);
        post.report(userId);
        posts.save(post);
    }

    @Override
    public LikeStatus like(UUID userId, UUID postId) {
        Post post = access.visiblePost(userId, postId);
        if (!likes.exists(postId, userId)) {
            likes.add(postId, userId, clock.instant());
            notifier.postLiked(post.authorId(), postId, userId);
        }
        return new LikeStatus(postId, true, likes.countByPost(postId));
    }

    /** Quitar el «me gusta» solo exige que la publicación exista (aunque ya no sea visible). */
    @Override
    public LikeStatus unlike(UUID userId, UUID postId) {
        posts.findById(postId).orElseThrow(() -> new PostNotFoundException(postId));
        likes.remove(postId, userId);
        return new LikeStatus(postId, false, likes.countByPost(postId));
    }

    private PostView view(UUID viewerId, UUID postId) {
        return queries.findPost(viewerId, postId).orElseThrow(() -> new PostNotFoundException(postId));
    }
}
