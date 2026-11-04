package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.AuthorSummary;
import com.synaptixfit.domain.model.social.Comment;
import com.synaptixfit.domain.model.social.CommentView;
import com.synaptixfit.domain.model.social.FeedQuery;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.FriendshipListKind;
import com.synaptixfit.domain.model.social.FriendshipView;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostType;
import com.synaptixfit.domain.model.social.PostView;
import com.synaptixfit.domain.model.social.PublicBadge;
import com.synaptixfit.domain.model.social.UserCard;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.social.CommentRepositoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.social.PostLikeRepositoryPort;
import com.synaptixfit.domain.port.output.social.PostRepositoryPort;
import com.synaptixfit.domain.port.output.social.SocialQueryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Dobles en memoria de los puertos del módulo social para las pruebas de servicios. */
final class SocialFakes {

    static final Clock CLOCK = Clock.fixed(Instant.parse("2026-10-18T10:00:00Z"), ZoneOffset.UTC);

    final Map<UUID, User> users = new HashMap<>();
    final Map<UUID, Post> posts = new HashMap<>();
    final Map<UUID, Comment> comments = new HashMap<>();
    final Map<UUID, Friendship> friendships = new HashMap<>();
    final Set<String> likes = new HashSet<>();
    final List<CreateNotificationUseCase.Command> notifications = new ArrayList<>();
    /** Insignias visibles por usuario (lo que devolvería la consulta de gamificación). */
    final Map<UUID, List<PublicBadge>> badges = new HashMap<>();

    User user(String name, Visibility privacy) {
        return user(name, privacy, false);
    }

    User user(String name, Visibility privacy, boolean shadowbanned) {
        User u = User.builder().id(UUID.randomUUID()).email(name.toLowerCase() + "@example.com").fullName(name)
                .passwordHash("h").privacy(privacy).shadowbanned(shadowbanned).createdAt(CLOCK.instant()).build();
        users.put(u.id(), u);
        return u;
    }

    Post post(User author) {
        Post p = Post.publish(author.id(), com.synaptixfit.domain.model.social.PostType.MILESTONE_REACHED,
                "Hola mundo", null, null, CLOCK.instant());
        posts.put(p.id(), p);
        return p;
    }

    Friendship friends(User a, User b) {
        Friendship f = Friendship.request(a.id(), b.id(), CLOCK.instant());
        f.accept(b.id(), CLOCK.instant());
        friendships.put(f.id(), f);
        return f;
    }

    UserRepositoryPort userPort() {
        return new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return Optional.ofNullable(users.get(id)); }
            public Optional<User> findByEmail(String e) { return Optional.empty(); }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return false; }
            public User save(User u) { users.put(u.id(), u); return u; }
        };
    }

    PostRepositoryPort postPort() {
        return new PostRepositoryPort() {
            public Optional<Post> findById(UUID id) { return Optional.ofNullable(posts.get(id)); }
            public Post save(Post p) { posts.put(p.id(), p); return p; }
            public boolean existsByAuthorTypeAndMetadata(UUID userId, PostType type, String metadata) {
                return posts.values().stream().anyMatch(p -> p.authorId().equals(userId) && p.type() == type
                        && java.util.Objects.equals(p.metadata(), metadata));
            }
            public void delete(UUID id) { posts.remove(id); }
        };
    }

    CommentRepositoryPort commentPort() {
        return new CommentRepositoryPort() {
            public Optional<Comment> findById(UUID id) { return Optional.ofNullable(comments.get(id)); }
            public Comment save(Comment c) { comments.put(c.id(), c); return c; }
        };
    }

    PostLikeRepositoryPort likePort() {
        return new PostLikeRepositoryPort() {
            public boolean exists(UUID postId, UUID userId) { return likes.contains(postId + ":" + userId); }
            public void add(UUID postId, UUID userId, Instant at) { likes.add(postId + ":" + userId); }
            public void remove(UUID postId, UUID userId) { likes.remove(postId + ":" + userId); }
            public long countByPost(UUID postId) {
                return likes.stream().filter(k -> k.startsWith(postId + ":")).count();
            }
        };
    }

    FriendshipRepositoryPort friendshipPort() {
        return new FriendshipRepositoryPort() {
            public Optional<Friendship> findById(UUID id) { return Optional.ofNullable(friendships.get(id)); }
            public Optional<Friendship> findBetween(UUID a, UUID b) {
                return friendships.values().stream()
                        .filter(f -> f.involves(a) && f.involves(b)).findFirst();
            }
            public Friendship save(Friendship f) { friendships.put(f.id(), f); return f; }
            public void delete(UUID id) { friendships.remove(id); }
        };
    }

    CreateNotificationUseCase notificationPort() {
        return command -> {
            notifications.add(command);
            return Optional.of(Notification.create(command.userId(), command.title(), command.description(),
                    command.priority(), command.type(), command.actionUrl(), command.actionLabel(),
                    CLOCK.instant()));
        };
    }

    /** Solo resuelve publicaciones y comentarios sueltos a partir de los mapas en memoria. */
    SocialQueryPort queryPort() {
        return new SocialQueryPort() {
            public PageResult<PostView> feed(FeedQuery query) { throw new UnsupportedOperationException(); }

            public Optional<PostView> findPost(UUID viewerId, UUID postId) {
                return Optional.ofNullable(posts.get(postId)).map(p -> new PostView(p.id(), author(p.authorId()),
                        p.type(), p.description(), p.imageUrl(), p.metadata(), p.createdAt(), p.editedAt(),
                        likePort().countByPost(p.id()), 0, likePort().exists(p.id(), viewerId)));
            }

            public PageResult<CommentView> comments(UUID viewerId, UUID postId, PageRequest page) {
                List<CommentView> items = comments.values().stream()
                        .filter(c -> c.postId().equals(postId) && !c.deleted())
                        .map(c -> findComment(c.id()).orElseThrow()).toList();
                return new PageResult<>(items, page.page(), page.size(), items.size());
            }

            public Optional<CommentView> findComment(UUID commentId) {
                return Optional.ofNullable(comments.get(commentId)).filter(c -> !c.deleted())
                        .map(c -> new CommentView(c.id(), c.postId(), author(c.authorId()), c.text(), c.createdAt(),
                                c.editedAt()));
            }

            public PageResult<UserCard> searchUsers(UUID v, String t, PageRequest p) {
                throw new UnsupportedOperationException();
            }

            public PageResult<FriendshipView> friendships(UUID v, FriendshipListKind k, PageRequest p) {
                throw new UnsupportedOperationException();
            }

            public long countPosts(UUID authorId) {
                return posts.values().stream().filter(p -> p.authorId().equals(authorId)).count();
            }

            public long countFriends(UUID userId) {
                return friendships.values().stream().filter(f -> f.involves(userId) && f.isAccepted()).count();
            }

            public List<PublicBadge> visibleBadges(UUID userId) {
                return badges.getOrDefault(userId, List.of());
            }
        };
    }

    private AuthorSummary author(UUID id) {
        User u = users.get(id);
        return new AuthorSummary(id, u.fullName(), u.avatarUrl());
    }
}
