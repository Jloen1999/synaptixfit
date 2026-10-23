package com.synaptixfit.domain.model.social;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.social.FriendshipInvalidStateException;
import com.synaptixfit.domain.exception.social.FriendshipNotFoundException;
import com.synaptixfit.domain.exception.social.FriendshipSelfTargetException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.User;
import java.time.Instant;
import java.time.ZoneId;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

/** Reglas de dominio del módulo social: visibilidad, máquina de estados de amistad y límites. */
class SocialDomainTest {

    private static final Instant NOW = Instant.parse("2026-10-15T10:00:00Z");
    private final UUID viewer = UUID.randomUUID();

    private static User user(Visibility privacy, boolean shadowbanned, boolean deleted) {
        return User.builder().id(UUID.randomUUID()).email("u" + UUID.randomUUID() + "@example.com")
                .fullName("Usuario").passwordHash("h").privacy(privacy).shadowbanned(shadowbanned)
                .createdAt(NOW).deletedAt(deleted ? NOW : null).build();
    }

    // ---------------------------------------------------------------- visibilidad

    @ParameterizedTest
    @CsvSource({
            "PUBLIC,  NONE,     true",
            "PUBLIC,  ACCEPTED, true",
            "PUBLIC,  PENDING,  true",
            "PUBLIC,  BLOCKED,  false",
            "FRIENDS, NONE,     false",
            "FRIENDS, PENDING,  false",
            "FRIENDS, REJECTED, false",
            "FRIENDS, ACCEPTED, true",
            "PRIVATE, NONE,     false",
            "PRIVATE, ACCEPTED, false"
    })
    void visibilityDependsOnPrivacyAndFriendship(Visibility privacy, String relation, boolean expected) {
        User author = user(privacy, false, false);
        Friendship f = switch (relation) {
            case "NONE" -> null;
            default -> new Friendship(UUID.randomUUID(), viewer, author.id(), FriendshipStatus.valueOf(relation),
                    NOW, NOW);
        };
        assertThat(ContentVisibility.canView(viewer, author, f)).isEqualTo(expected);
    }

    @Test
    void shadowbannedAuthorsAreOnlyVisibleToThemselves() {
        User troll = user(Visibility.PUBLIC, true, false);
        Friendship friends = new Friendship(UUID.randomUUID(), viewer, troll.id(), FriendshipStatus.ACCEPTED, NOW, NOW);
        assertThat(ContentVisibility.canView(viewer, troll, friends)).isFalse();
        assertThat(ContentVisibility.canView(troll.id(), troll, null)).isTrue();
        assertThat(ContentVisibility.canDiscover(viewer, troll, null)).isFalse();
    }

    @Test
    void deletedAuthorsAreInvisible() {
        assertThat(ContentVisibility.canView(viewer, user(Visibility.PUBLIC, false, true), null)).isFalse();
    }

    @Test
    void blockedUserCannotDiscoverBlockerButBlockerCanSeeBlocked() {
        User blocker = user(Visibility.PUBLIC, false, false);
        Friendship block = Friendship.blocking(blocker.id(), viewer, NOW);
        assertThat(ContentVisibility.canDiscover(viewer, blocker, block)).isFalse();
        User blocked = user(Visibility.PUBLIC, false, false);
        Friendship myBlock = Friendship.blocking(viewer, blocked.id(), NOW);
        assertThat(ContentVisibility.canDiscover(viewer, blocked, myBlock)).isTrue();
        assertThat(ContentVisibility.canView(viewer, blocked, myBlock)).isFalse();
    }

    // ---------------------------------------------------------------- amistad

    @Test
    void friendshipStateMachine() {
        UUID other = UUID.randomUUID();
        Friendship f = Friendship.request(viewer, other, NOW);
        assertThat(f.relationFor(viewer)).isEqualTo(FriendshipRelation.REQUEST_SENT);
        assertThat(f.relationFor(other)).isEqualTo(FriendshipRelation.REQUEST_RECEIVED);
        assertThatThrownBy(() -> f.accept(viewer, NOW)).isInstanceOf(FriendshipInvalidStateException.class);

        f.reject(other, NOW);
        assertThat(f.relationFor(viewer)).isEqualTo(FriendshipRelation.NONE);
        assertThatThrownBy(() -> f.accept(other, NOW)).isInstanceOf(FriendshipInvalidStateException.class);

        f.renewRequest(other, NOW);
        assertThat(f.requesterId()).isEqualTo(other);
        f.accept(viewer, NOW);
        assertThat(f.isAccepted()).isTrue();

        f.blockBy(viewer, NOW);
        assertThat(f.isBlockedBy(viewer)).isTrue();
        assertThat(f.relationFor(other)).isEqualTo(FriendshipRelation.NONE);
        assertThatThrownBy(() -> f.blockBy(other, NOW)).isInstanceOf(FriendshipInvalidStateException.class);
        assertThatThrownBy(() -> f.ensureRemovableBy(other)).isInstanceOf(FriendshipNotFoundException.class);
        f.ensureRemovableBy(viewer);
    }

    @Test
    void cannotBefriendSelf() {
        assertThatThrownBy(() -> Friendship.request(viewer, viewer, NOW))
                .isInstanceOf(FriendshipSelfTargetException.class);
    }

    // ---------------------------------------------------------------- publicaciones y comentarios

    @Test
    void postValidatesDescriptionAndNormalizesImage() {
        assertThatThrownBy(() -> Post.publish(viewer, PostType.ROUTINE, " ", null, null, NOW))
                .isInstanceOf(FieldValidationException.class);
        Post p = Post.publish(viewer, PostType.ROUTINE, "ok", "", null, NOW);
        assertThat(p.imageUrl()).isNull();
        p.edit(viewer, null, "https://img", NOW);
        assertThat(p.description()).isEqualTo("ok");
        assertThat(p.imageUrl()).isEqualTo("https://img");
    }

    @Test
    void commentLengthLimits() {
        UUID post = UUID.randomUUID();
        assertThat(Comment.write(post, viewer, "x".repeat(500), NOW).text()).hasSize(500);
        assertThatThrownBy(() -> Comment.write(post, viewer, "", NOW)).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void feedPeriodsStartAtLocalBoundaries() {
        ZoneId madrid = ZoneId.of("Europe/Madrid");
        // Jueves 15/10/2026 12:00 en Madrid (UTC+2).
        assertThat(FeedPeriod.TODAY.startFrom(NOW, madrid)).isEqualTo(Instant.parse("2026-10-14T22:00:00Z"));
        assertThat(FeedPeriod.WEEK.startFrom(NOW, madrid)).isEqualTo(Instant.parse("2026-10-11T22:00:00Z"));
        assertThat(FeedPeriod.MONTH.startFrom(NOW, madrid)).isEqualTo(Instant.parse("2026-09-30T22:00:00Z"));
        assertThat(FeedPeriod.ALL.startFrom(NOW, madrid)).isNull();
    }
}
