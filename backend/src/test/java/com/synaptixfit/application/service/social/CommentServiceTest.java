package com.synaptixfit.application.service.social;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.social.AddCommentUseCase;
import com.synaptixfit.application.port.input.social.EditCommentUseCase;
import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.social.CommentForbiddenException;
import com.synaptixfit.domain.exception.social.CommentNotFoundException;
import com.synaptixfit.domain.exception.social.PostNotFoundException;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.CommentView;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class CommentServiceTest {

    private SocialFakes fakes;
    private CommentService service;
    private User author;
    private User reader;
    private Post post;

    @BeforeEach
    void setUp() {
        fakes = new SocialFakes();
        service = new CommentService(fakes.commentPort(), fakes.postPort(), fakes.queryPort(), fakes.userPort(),
                fakes.friendshipPort(), fakes.notificationPort(), SocialFakes.CLOCK);
        author = fakes.user("Autora", Visibility.PUBLIC);
        reader = fakes.user("Lector", Visibility.PRIVATE);
        post = fakes.post(author);
    }

    @Test
    void addCommentNotifiesPostAuthor() {
        CommentView view = service.addComment(new AddCommentUseCase.Command(reader.id(), post.id(), "¡Bien!"));
        assertThat(view.author().id()).isEqualTo(reader.id());
        assertThat(fakes.notifications).singleElement()
                .satisfies(n -> assertThat(n.userId()).isEqualTo(author.id()));
        assertThat(service.listComments(author.id(), post.id(), new PageRequest(0, 20)).items()).hasSize(1);
    }

    @Test
    void commentTextMustBeBetween1And500() {
        assertThatThrownBy(() -> service.addComment(new AddCommentUseCase.Command(reader.id(), post.id(),
                "x".repeat(501)))).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void cannotCommentOnInvisiblePost() {
        User hidden = fakes.user("Oculta", Visibility.PRIVATE);
        Post hiddenPost = fakes.post(hidden);
        assertThatThrownBy(() -> service.addComment(new AddCommentUseCase.Command(reader.id(), hiddenPost.id(),
                "hola"))).isInstanceOf(PostNotFoundException.class);
    }

    @Test
    void onlyCommentAuthorEditsOrDeletes() {
        CommentView c = service.addComment(new AddCommentUseCase.Command(reader.id(), post.id(), "Original"));

        assertThatThrownBy(() -> service.editComment(new EditCommentUseCase.Command(author.id(), c.id(), "x")))
                .isInstanceOf(CommentForbiddenException.class);
        // El autor de la publicación tampoco puede borrar comentarios ajenos (igual que antes).
        assertThatThrownBy(() -> service.deleteComment(author.id(), c.id()))
                .isInstanceOf(CommentForbiddenException.class);

        CommentView edited = service.editComment(new EditCommentUseCase.Command(reader.id(), c.id(), "Nuevo"));
        assertThat(edited.text()).isEqualTo("Nuevo");
        assertThat(edited.editedAt()).isNotNull();

        service.deleteComment(reader.id(), c.id());
        assertThat(fakes.comments.get(c.id()).deleted()).isTrue();
        assertThatThrownBy(() -> service.deleteComment(reader.id(), c.id()))
                .isInstanceOf(CommentNotFoundException.class);
    }

    @Test
    void blockedUserCannotReachComment() {
        CommentView c = service.addComment(new AddCommentUseCase.Command(reader.id(), post.id(), "Hola"));
        User third = fakes.user("Tercero", Visibility.PUBLIC);
        Friendship block = Friendship.blocking(reader.id(), third.id(), SocialFakes.CLOCK.instant());
        fakes.friendships.put(block.id(), block);

        assertThatThrownBy(() -> service.reportComment(third.id(), c.id()))
                .isInstanceOf(CommentNotFoundException.class);
    }

    @Test
    void reportMarksComment() {
        CommentView c = service.addComment(new AddCommentUseCase.Command(reader.id(), post.id(), "Spam"));
        service.reportComment(author.id(), c.id());
        assertThat(fakes.comments.get(c.id()).reported()).isTrue();
        assertThat(fakes.comments.get(c.id()).reportedBy()).isEqualTo(author.id());
    }
}
