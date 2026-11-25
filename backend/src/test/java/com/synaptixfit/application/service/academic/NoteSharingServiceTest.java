package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.academic.SendNoteToFriendUseCase;
import com.synaptixfit.application.port.input.academic.ShareNoteOnWallUseCase;
import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.social.PublishAchievementPostUseCase;
import com.synaptixfit.domain.exception.academic.NoteNotFoundException;
import com.synaptixfit.domain.exception.academic.NoteRecipientNotFriendException;
import com.synaptixfit.domain.exception.academic.NoteWallProfilePrivateException;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.academic.NotePdf;
import com.synaptixfit.domain.model.notification.NotificationMessage;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.FriendshipStatus;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostType;
import com.synaptixfit.domain.port.output.academic.NoteRecipientRepositoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** «Compartir» un apunte (ADR 0064): con un amigo, en el muro y en PDF. */
class NoteSharingServiceTest {

    private final AcademicFakes f = new AcademicFakes();
    private final UUID me = UUID.randomUUID();
    private final UUID friend = UUID.randomUUID();
    private final Map<Set<UUID>, Friendship> relations = new HashMap<>();
    private final Set<String> grants = new HashSet<>();
    private final List<CreateNotificationUseCase.Command> sent = new ArrayList<>();
    private final List<PublishAchievementPostUseCase.Command> published = new ArrayList<>();
    private final Set<String> postedMetadata = new HashSet<>();

    private final List<Set<UUID>> revokedPairs = new ArrayList<>();
    private final NoteRecipientRepositoryPort recipients = new NoteRecipientRepositoryPort() {
        public void add(UUID noteId, UUID recipientId, Instant at) { grants.add(noteId + ":" + recipientId); }
        public boolean isRecipient(UUID noteId, UUID userId) { return grants.contains(noteId + ":" + userId); }
        public void deleteBetween(UUID userId, UUID otherUserId) {
            revokedPairs.add(Set.of(userId, otherUserId));
            grants.removeIf(g -> g.endsWith(":" + userId) || g.endsWith(":" + otherUserId));
        }
    };

    private final FriendshipRepositoryPort friendships = new FriendshipRepositoryPort() {
        public Optional<Friendship> findById(UUID id) { return Optional.empty(); }
        public Optional<Friendship> findBetween(UUID a, UUID b) { return Optional.ofNullable(relations.get(Set.of(a, b))); }
        public Friendship save(Friendship fr) { return fr; }
        public void delete(UUID id) { }
    };

    private final NoteSharingService service = new NoteSharingService(f.notes, recipients, friendships, f.users,
            c -> {
                sent.add(c);
                return Optional.empty();
            },
            c -> {
                published.add(c);
                return postedMetadata.add(c.metadata());
            },
            AcademicFakes.CLOCK);

    private Note note(Visibility visibility) {
        return f.notes.save(Note.create(me, null, "Tema 2: SQL", "# SQL", visibility, false, AcademicFakes.NOW));
    }

    private void befriend(FriendshipStatus status) {
        relations.put(Set.of(me, friend), new Friendship(UUID.randomUUID(), me, friend, status, AcademicFakes.NOW,
                AcademicFakes.NOW));
    }

    @Test
    void aFriendReceivesTheNoteAndANotice() {
        Note note = note(Visibility.PRIVATE);
        befriend(FriendshipStatus.ACCEPTED);

        SendNoteToFriendUseCase.SentNote result = service.sendToFriend(me, note.id(), friend);

        assertThat(result.friendId()).isEqualTo(friend);
        assertThat(result.friendName()).isEqualTo("Usuario");
        assertThat(recipients.isRecipient(note.id(), friend)).isTrue();
        assertThat(sent).singleElement().satisfies(c -> {
            assertThat(c.userId()).isEqualTo(friend);
            assertThat(c.actionUrl()).isEqualTo("/academic/notes/shared/" + note.id());
            assertThat(c.message().code()).isEqualTo(NotificationMessage.Code.NOTE_RECEIVED);
            assertThat(c.message().params()).containsEntry("title", "Tema 2: SQL");
        });
    }

    @Test
    void onlyMutualFriendsCanReceiveIt() {
        Note note = note(Visibility.PRIVATE);
        assertThatThrownBy(() -> service.sendToFriend(me, note.id(), friend))
                .isInstanceOf(NoteRecipientNotFriendException.class);
        befriend(FriendshipStatus.PENDING);
        assertThatThrownBy(() -> service.sendToFriend(me, note.id(), friend))
                .isInstanceOf(NoteRecipientNotFriendException.class);
        assertThatThrownBy(() -> service.sendToFriend(me, note.id(), me))
                .isInstanceOf(NoteRecipientNotFriendException.class);
        assertThat(grants).isEmpty();
        assertThat(sent).isEmpty();
    }

    @Test
    void someoneElsesNoteDoesNotExist() {
        Note note = note(Visibility.PUBLIC);
        befriend(FriendshipStatus.ACCEPTED);
        assertThatThrownBy(() -> service.sendToFriend(friend, note.id(), me))
                .isInstanceOf(NoteNotFoundException.class);
        assertThatThrownBy(() -> service.shareOnWall(new ShareNoteOnWallUseCase.Command(friend, note.id(), null)))
                .isInstanceOf(NoteNotFoundException.class);
    }

    @Test
    void theWallOpensThePrivateNoteUpToTheProfileAndDoesNotDuplicateThePost() {
        Note note = note(Visibility.PRIVATE);
        f.privacy.put(me, Visibility.FRIENDS);

        ShareNoteOnWallUseCase.WallShare first = service.shareOnWall(
                new ShareNoteOnWallUseCase.Command(me, note.id(), "  "));
        ShareNoteOnWallUseCase.WallShare again = service.shareOnWall(
                new ShareNoteOnWallUseCase.Command(me, note.id(), "Para el parcial"));

        assertThat(first.alreadyShared()).isFalse();
        assertThat(first.visibility()).isEqualTo(Visibility.FRIENDS);
        assertThat(again.alreadyShared()).isTrue();
        assertThat(f.notes.findByIdAndUser(note.id(), me).orElseThrow().visibility()).isEqualTo(Visibility.FRIENDS);
        assertThat(published).hasSize(2).allSatisfy(c -> {
            assertThat(c.type()).isEqualTo(PostType.NOTE);
            assertThat(c.metadata()).isEqualTo(Post.noteMetadata(note.id()))
                    .isEqualTo("{\"entityType\":\"note\",\"entityId\":\"" + note.id() + "\"}");
        });
        assertThat(published.get(0).description()).isEqualTo("Tema 2: SQL");
        assertThat(published.get(1).description()).isEqualTo("Para el parcial");
    }

    @Test
    void aPublicNoteStaysPublic() {
        Note note = note(Visibility.PUBLIC);
        assertThat(service.shareOnWall(new ShareNoteOnWallUseCase.Command(me, note.id(), null)).visibility())
                .isEqualTo(Visibility.PUBLIC);
    }

    @Test
    void aPrivateProfileCannotShareOnTheWall() {
        Note note = note(Visibility.PRIVATE);
        f.privacy.put(me, Visibility.PRIVATE);
        assertThatThrownBy(() -> service.shareOnWall(new ShareNoteOnWallUseCase.Command(me, note.id(), null)))
                .isInstanceOf(NoteWallProfilePrivateException.class)
                .hasFieldOrPropertyWithValue("code", "NOTE_WALL_PROFILE_PRIVATE");
        assertThat(published).isEmpty();
        assertThat(f.notes.findByIdAndUser(note.id(), me).orElseThrow().visibility()).isEqualTo(Visibility.PRIVATE);
    }

    @Test
    void endingTheFriendshipRevokesWhatWasSentBothWays() {
        Note note = note(Visibility.PRIVATE);
        befriend(FriendshipStatus.ACCEPTED);
        service.sendToFriend(me, note.id(), friend);

        service.revokeBetween(friend, me);

        assertThat(revokedPairs).containsExactly(Set.of(friend, me));
        assertThat(recipients.isRecipient(note.id(), friend)).isFalse();
    }

    @Test
    void thePdfIsReadFromTheOwnNoteAndNamedAfterTheTitle() {
        Note note = note(Visibility.PRIVATE);
        NotePdfExportService export = new NotePdfExportService((userId, noteId) -> f.notes
                .findByIdAndUser(noteId, userId).orElseThrow(() -> new NoteNotFoundException(noteId)),
                (title, markdown) -> ("PDF:" + title).getBytes());

        NotePdf pdf = export.exportPdf(me, note.id());

        assertThat(pdf.fileName()).isEqualTo("Tema 2 SQL.pdf");
        assertThat(new String(pdf.content())).isEqualTo("PDF:Tema 2: SQL");
        assertThatThrownBy(() -> export.exportPdf(friend, note.id())).isInstanceOf(NoteNotFoundException.class);
        assertThat(NotePdf.fileNameFor("  / ? ")).isEqualTo("apunte.pdf");
        assertThat(NotePdf.fileNameFor("x".repeat(200))).hasSize(84);
    }
}
