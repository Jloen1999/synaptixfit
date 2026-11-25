package com.synaptixfit.application.service.academic;

import com.synaptixfit.application.port.input.academic.RevokeNoteRecipientsUseCase;
import com.synaptixfit.application.port.input.academic.SendNoteToFriendUseCase;
import com.synaptixfit.application.port.input.academic.ShareNoteOnWallUseCase;
import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.social.PublishAchievementPostUseCase;
import com.synaptixfit.domain.exception.academic.NoteNotFoundException;
import com.synaptixfit.domain.exception.academic.NoteRecipientNotFriendException;
import com.synaptixfit.domain.exception.academic.NoteWallProfilePrivateException;
import com.synaptixfit.domain.model.academic.Note;
import com.synaptixfit.domain.model.notification.NotificationMessage;
import com.synaptixfit.domain.model.notification.NotificationMessage.Code;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import com.synaptixfit.domain.model.shared.EffectiveVisibility;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostType;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.academic.NoteRecipientRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * «Compartir» un apunte propio (ADR 0064): pasarlo a un amigo ({@link NoteRecipientRepositoryPort} y un aviso con
 * {@link CreateNotificationUseCase}), publicarlo en el muro ({@link PublishAchievementPostUseCase}, idempotente) y
 * quitar lo pasado entre dos personas que dejan de ser amigas. Un apunte ajeno se trata como inexistente. Las dos
 * llamadas a otros módulos son síncronas a propósito (ver {@code events.md}).
 */
public class NoteSharingService implements SendNoteToFriendUseCase, ShareNoteOnWallUseCase,
        RevokeNoteRecipientsUseCase {

    /** Ruta del cliente que abre un apunte ajeno (la lectura de «Apuntes compartidos»). */
    static final String SHARED_NOTE_PATH = "/academic/notes/shared/";

    private final NoteRepositoryPort notes;
    private final NoteRecipientRepositoryPort recipients;
    private final FriendshipRepositoryPort friendships;
    private final UserRepositoryPort users;
    private final CreateNotificationUseCase notifications;
    private final PublishAchievementPostUseCase posts;
    private final Clock clock;

    public NoteSharingService(NoteRepositoryPort notes, NoteRecipientRepositoryPort recipients,
                              FriendshipRepositoryPort friendships, UserRepositoryPort users,
                              CreateNotificationUseCase notifications, PublishAchievementPostUseCase posts,
                              Clock clock) {
        this.notes = notes;
        this.recipients = recipients;
        this.friendships = friendships;
        this.users = users;
        this.notifications = notifications;
        this.posts = posts;
        this.clock = clock;
    }

    @Override
    public SentNote sendToFriend(UUID userId, UUID noteId, UUID friendId) {
        Note note = ownNote(userId, noteId);
        // Solo amigos mutuos, como en «Con amigos» (ADR 0044): amistad aceptada, sin bloqueo y cuenta activa.
        User friend = friendId.equals(userId) ? null : users.findById(friendId).filter(User::isActive).orElse(null);
        boolean friends = friend != null
                && friendships.findBetween(userId, friendId).map(Friendship::isAccepted).orElse(false);
        if (!friends) {
            throw new NoteRecipientNotFriendException(friendId);
        }
        recipients.add(note.id(), friendId, clock.instant());
        notifyFriend(userId, friendId, note);
        return new SentNote(friendId, friend.fullName());
    }

    @Override
    public WallShare shareOnWall(ShareNoteOnWallUseCase.Command c) {
        Note note = ownNote(c.userId(), c.noteId());
        // Quien ve el muro tiene que poder abrir el apunte: se abre a todos, con el tope que pone el perfil (el muro
        // sigue la misma regla, ContentVisibility).
        Visibility profile = users.findById(c.userId()).map(User::privacy).orElse(Visibility.PRIVATE);
        if (profile == Visibility.PRIVATE) {
            // Nadie más ve el muro ni el apunte: no se publica algo que nadie puede abrir.
            throw new NoteWallProfilePrivateException();
        }
        Visibility wanted = EffectiveVisibility.of(Visibility.PUBLIC, profile);
        if (note.visibility().isLessOpenThan(wanted)) {
            note.changeVisibility(wanted);
            note.touch(clock.instant());
            notes.save(note);
        }
        String comment = c.comment() == null ? "" : c.comment().strip();
        String description = comment.isEmpty() ? note.title() : comment;
        if (description.length() > Post.MAX_DESCRIPTION) {
            description = description.substring(0, Post.MAX_DESCRIPTION);
        }
        // Llamada directa a Social (no un evento): la respuesta depende de si ya estaba publicado (events.md).
        boolean published = posts.publishAchievement(new PublishAchievementPostUseCase.Command(c.userId(),
                PostType.NOTE, description, Post.noteMetadata(note.id())));
        return new WallShare(!published, note.visibility());
    }

    @Override
    public void revokeBetween(UUID userId, UUID otherUserId) {
        recipients.deleteBetween(userId, otherUserId);
    }

    private Note ownNote(UUID userId, UUID noteId) {
        return notes.findByIdAndUser(noteId, userId).orElseThrow(() -> new NoteNotFoundException(noteId));
    }

    /** Aviso social a quien lo recibe (respeta sus preferencias); quien tiene shadowban no avisa a nadie. */
    private void notifyFriend(UUID userId, UUID friendId, Note note) {
        User actor = users.findById(userId).orElse(null);
        if (actor == null || actor.shadowbanned()) {
            return;
        }
        Map<String, String> params = new LinkedHashMap<>();
        params.put("name", actor.fullName());
        params.put("title", note.title());
        notifications.create(new CreateNotificationUseCase.Command(friendId, "Te han pasado un apunte",
                actor.fullName() + " te ha pasado un apunte: " + note.title(), NotificationPriority.INFORMATIVE,
                NotificationType.SOCIAL, SHARED_NOTE_PATH + note.id(), "Ver", "note-sent:" + note.id() + ":" + friendId,
                new NotificationMessage(Code.NOTE_RECEIVED, params)));
    }
}
