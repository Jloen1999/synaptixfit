package com.synaptixfit.application.service.social;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.social.PostNotFoundException;
import com.synaptixfit.domain.exception.social.SocialUserNotFoundException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.Comment;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.FriendshipRelation;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PublicProfile;
import com.synaptixfit.domain.model.social.ReportedContentType;
import com.synaptixfit.domain.model.user.User;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class SocialProfileAndModerationServiceTest {

    private record AuditEntry(UUID adminId, String action, String entity, UUID entityId, Map<String, String> detail) {}

    private SocialFakes fakes;
    private SocialProfileService profiles;
    private ModerationService moderation;
    private final List<AuditEntry> audit = new ArrayList<>();
    private User viewer;

    @BeforeEach
    void setUp() {
        fakes = new SocialFakes();
        profiles = new SocialProfileService(fakes.userPort(), fakes.friendshipPort(), fakes.queryPort());
        moderation = new ModerationService(fakes.postPort(), fakes.commentPort(), (type, page) -> null,
                (admin, action, entity, id, detail) -> audit.add(new AuditEntry(admin, action, entity, id, detail)));
        viewer = fakes.user("Viewer", Visibility.PUBLIC);
    }

    @Test
    void publicProfileShowsActivity() {
        User target = fakes.user("Publica", Visibility.PUBLIC);
        fakes.post(target);
        PublicProfile p = profiles.getProfile(viewer.id(), target.id());
        assertThat(p.restricted()).isFalse();
        assertThat(p.postsCount()).isEqualTo(1);
        assertThat(p.relation()).isEqualTo(FriendshipRelation.NONE);
    }

    @Test
    void privateProfileIsRestrictedAndFriendsProfileOpensWithFriendship() {
        User priv = fakes.user("Privada", Visibility.PRIVATE);
        PublicProfile p = profiles.getProfile(viewer.id(), priv.id());
        assertThat(p.restricted()).isTrue();
        assertThat(p.level()).isNull();
        assertThat(p.fullName()).isEqualTo("Privada");

        User friendsOnly = fakes.user("Amigos", Visibility.FRIENDS);
        assertThat(profiles.getProfile(viewer.id(), friendsOnly.id()).restricted()).isTrue();
        Friendship f = fakes.friends(viewer, friendsOnly);
        PublicProfile opened = profiles.getProfile(viewer.id(), friendsOnly.id());
        assertThat(opened.restricted()).isFalse();
        assertThat(opened.relation()).isEqualTo(FriendshipRelation.FRIENDS);
        assertThat(opened.friendshipId()).isEqualTo(f.id());
    }

    @Test
    void shadowbannedOrBlockingUsersDoNotExist() {
        User troll = fakes.user("Troll", Visibility.PUBLIC, true);
        assertThatThrownBy(() -> profiles.getProfile(viewer.id(), troll.id()))
                .isInstanceOf(SocialUserNotFoundException.class);
        assertThat(profiles.getProfile(troll.id(), troll.id()).restricted()).isFalse();

        User blocker = fakes.user("Bloqueadora", Visibility.PUBLIC);
        Friendship block = Friendship.blocking(blocker.id(), viewer.id(), SocialFakes.CLOCK.instant());
        fakes.friendships.put(block.id(), block);
        assertThatThrownBy(() -> profiles.getProfile(viewer.id(), blocker.id()))
                .isInstanceOf(SocialUserNotFoundException.class);
        PublicProfile seenByBlocker = profiles.getProfile(blocker.id(), viewer.id());
        assertThat(seenByBlocker.relation()).isEqualTo(FriendshipRelation.BLOCKED);
        assertThat(seenByBlocker.restricted()).isTrue();
    }

    @Test
    void searchTermNeedsTwoCharacters() {
        assertThatThrownBy(() -> profiles.search(viewer.id(), "a", new PageRequest(0, 20)))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void dismissAndRemoveAreAudited() {
        User author = fakes.user("Autor", Visibility.PUBLIC);
        Post post = fakes.post(author);
        post.report(viewer.id());
        Comment comment = Comment.write(post.id(), author.id(), "malo", SocialFakes.CLOCK.instant());
        comment.report(viewer.id());
        fakes.comments.put(comment.id(), comment);
        UUID admin = UUID.randomUUID();

        moderation.dismiss(admin, ReportedContentType.POST, post.id());
        assertThat(fakes.posts.get(post.id()).reported()).isFalse();

        moderation.remove(admin, ReportedContentType.COMMENT, comment.id());
        assertThat(fakes.comments.get(comment.id()).deleted()).isTrue();
        assertThat(fakes.comments.get(comment.id()).reported()).isFalse();

        moderation.remove(admin, ReportedContentType.POST, post.id());
        assertThat(fakes.posts).isEmpty();

        assertThat(audit).extracting(AuditEntry::action)
                .containsExactly("aprobar_contenido", "eliminar_contenido", "eliminar_contenido");
        assertThat(audit).extracting(AuditEntry::entity)
                .containsExactly("actividades_sociales", "comentarios_feed", "actividades_sociales");
        assertThat(audit.get(0).detail()).containsEntry("autor_id", author.id().toString());
        assertThat(audit).allSatisfy(a -> assertThat(a.adminId()).isEqualTo(admin));

        assertThatThrownBy(() -> moderation.remove(admin, ReportedContentType.POST, post.id()))
                .isInstanceOf(PostNotFoundException.class);
    }
}
