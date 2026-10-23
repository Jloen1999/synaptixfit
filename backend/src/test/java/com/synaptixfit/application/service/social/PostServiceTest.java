package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.social.PublishAchievementPostUseCase;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.social.CreatePostUseCase;
import com.synaptixfit.application.port.input.social.EditPostUseCase;
import com.synaptixfit.domain.exception.social.PostForbiddenException;
import com.synaptixfit.domain.exception.social.PostNotFoundException;
import com.synaptixfit.domain.exception.social.SocialCannotReportOwnContentException;
import com.synaptixfit.domain.model.notification.NotificationType;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.LikeStatus;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostType;
import com.synaptixfit.domain.model.social.PostView;
import com.synaptixfit.domain.model.user.User;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class PostServiceTest {

    private SocialFakes fakes;
    private PostService service;
    private User author;
    private User reader;

    @BeforeEach
    void setUp() {
        fakes = new SocialFakes();
        service = new PostService(fakes.postPort(), fakes.likePort(), fakes.queryPort(), fakes.userPort(),
                fakes.friendshipPort(), fakes.notificationPort(), SocialFakes.CLOCK, ZoneOffset.UTC);
        author = fakes.user("Autora", Visibility.PUBLIC);
        reader = fakes.user("Lector", Visibility.PUBLIC);
    }

    @Test
    void createPostReturnsViewOwnedByAuthor() {
        PostView view = service.createPost(new CreatePostUseCase.Command(author.id(), PostType.ROUTINE,
                "Mi rutina", null, "{\"rutinaId\":\"1\"}"));
        assertThat(view.author().id()).isEqualTo(author.id());
        assertThat(view.type()).isEqualTo(PostType.ROUTINE);
        assertThat(fakes.posts).hasSize(1);
    }

    @Test
    void likeIsIdempotentAndNotifiesOnlyOnce() {
        Post post = fakes.post(author);

        LikeStatus first = service.like(reader.id(), post.id());
        LikeStatus second = service.like(reader.id(), post.id());

        assertThat(first.liked()).isTrue();
        assertThat(second.likesCount()).isEqualTo(1);
        assertThat(fakes.notifications).hasSize(1);
        assertThat(fakes.notifications.get(0).userId()).isEqualTo(author.id());
        assertThat(fakes.notifications.get(0).type()).isEqualTo(NotificationType.SOCIAL);
        assertThat(fakes.notifications.get(0).description()).contains("Lector");
    }

    @Test
    void unlikeIsIdempotent() {
        Post post = fakes.post(author);
        service.like(reader.id(), post.id());

        assertThat(service.unlike(reader.id(), post.id()).likesCount()).isZero();
        LikeStatus again = service.unlike(reader.id(), post.id());
        assertThat(again.liked()).isFalse();
        assertThat(again.likesCount()).isZero();
    }

    @Test
    void likingOwnPostDoesNotNotify() {
        Post post = fakes.post(author);
        service.like(author.id(), post.id());
        assertThat(fakes.notifications).isEmpty();
    }

    @Test
    void likesFromShadowbannedUsersAreNotNotified() {
        User troll = fakes.user("Troll", Visibility.PUBLIC, true);
        Post post = fakes.post(author);
        service.like(troll.id(), post.id());
        assertThat(fakes.notifications).isEmpty();
    }

    @Test
    void privateAuthorPostIsNotFoundForOthersButVisibleToAuthor() {
        User hidden = fakes.user("Privada", Visibility.PRIVATE);
        Post post = fakes.post(hidden);

        assertThatThrownBy(() -> service.getPost(reader.id(), post.id()))
                .isInstanceOf(PostNotFoundException.class);
        assertThatThrownBy(() -> service.like(reader.id(), post.id()))
                .isInstanceOf(PostNotFoundException.class);
        assertThat(service.getPost(hidden.id(), post.id()).id()).isEqualTo(post.id());
    }

    @Test
    void friendsOnlyPostRequiresAcceptedFriendship() {
        User friendsOnly = fakes.user("Amigable", Visibility.FRIENDS);
        Post post = fakes.post(friendsOnly);
        assertThatThrownBy(() -> service.getPost(reader.id(), post.id()))
                .isInstanceOf(PostNotFoundException.class);

        fakes.friends(reader, friendsOnly);
        assertThat(service.getPost(reader.id(), post.id()).id()).isEqualTo(post.id());
    }

    @Test
    void shadowbannedAuthorIsOnlyVisibleToThemselves() {
        User troll = fakes.user("Troll", Visibility.PUBLIC, true);
        Post post = fakes.post(troll);
        assertThatThrownBy(() -> service.getPost(reader.id(), post.id()))
                .isInstanceOf(PostNotFoundException.class);
        assertThat(service.getPost(troll.id(), post.id()).id()).isEqualTo(post.id());
    }

    @Test
    void onlyAuthorCanEditOrDelete() {
        Post post = fakes.post(author);

        assertThatThrownBy(() -> service.editPost(new EditPostUseCase.Command(reader.id(), post.id(), "x", null)))
                .isInstanceOf(PostForbiddenException.class);
        assertThatThrownBy(() -> service.deletePost(reader.id(), post.id()))
                .isInstanceOf(PostForbiddenException.class);

        PostView edited = service.editPost(new EditPostUseCase.Command(author.id(), post.id(), "Editado", null));
        assertThat(edited.description()).isEqualTo("Editado");
        assertThat(edited.editedAt()).isEqualTo(SocialFakes.CLOCK.instant());

        service.deletePost(author.id(), post.id());
        assertThat(fakes.posts).isEmpty();
    }

    @Test
    void reportMarksPostButAuthorCannotReportOwnPost() {
        Post post = fakes.post(author);
        assertThatThrownBy(() -> service.reportPost(author.id(), post.id()))
                .isInstanceOf(SocialCannotReportOwnContentException.class);

        service.reportPost(reader.id(), post.id());
        assertThat(fakes.posts.get(post.id()).reported()).isTrue();
        assertThat(fakes.posts.get(post.id()).reportedBy()).isEqualTo(reader.id());
    }

    @Test
    void achievementPostsAreNotDuplicated() {
        var command = new PublishAchievementPostUseCase.Command(author.id(), PostType.CHALLENGE_COMPLETED,
                "Ha completado el reto «Correr»", "{\"challengeId\":\"1\"}");

        assertThat(service.publishAchievement(command)).isTrue();
        assertThat(service.publishAchievement(command)).isFalse();
        assertThat(service.publishAchievement(new PublishAchievementPostUseCase.Command(author.id(),
                PostType.CHALLENGE_COMPLETED, "Otro", "{\"challengeId\":\"2\"}"))).isTrue();
        assertThat(fakes.posts).hasSize(2);
    }
}
