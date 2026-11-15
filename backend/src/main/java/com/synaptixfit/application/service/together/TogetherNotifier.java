package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.domain.model.notification.NotificationMessage;
import com.synaptixfit.domain.model.notification.NotificationMessage.Code;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Avisos de «Con amigos» (ADR 0044 y 0045): invitaciones y «Recordárselo». Van como avisos sociales, así que se aplican las
 * preferencias de quien los recibe ({@link CreateNotificationUseCase}); nunca llevan cifras ni datos de salud. Quien
 * tiene shadowban no avisa a nadie. {@code actionUrl} son rutas del cliente bajo {@code /social/together}.
 */
public final class TogetherNotifier {

    static final String HUB = "/social/together";

    private final CreateNotificationUseCase notifications;
    private final UserRepositoryPort users;

    public TogetherNotifier(CreateNotificationUseCase notifications, UserRepositoryPort users) {
        this.notifications = notifications;
        this.users = users;
    }

    void challengeInvited(Collection<UUID> invitees, UUID actorId, UUID challengeId, String title) {
        invitees.forEach(id -> send(id, actorId, "Reto con amigos",
                "%s te invita a un reto: " + title.replace("%", "%%"),
                HUB + "/challenges/" + challengeId, "Ver reto", "friend-challenge:" + challengeId,
                Code.FRIEND_CHALLENGE_INVITED, title));
    }

    void streakInvited(UUID friendId, UUID actorId, UUID streakId) {
        send(friendId, actorId, "Racha con un amigo", "%s te propone una racha juntos", HUB, "Ver",
                "friend-streak:" + streakId, Code.FRIEND_STREAK_INVITED, null);
    }

    void workoutInvited(Collection<UUID> invitees, UUID actorId, UUID workoutId, String routineName) {
        invitees.forEach(id -> send(id, actorId, "Entrenamos juntos",
                "%s te invita a entrenar hoy: " + routineName.replace("%", "%%"),
                HUB + "/workouts/" + workoutId, "Ver", "workout-together:" + workoutId,
                Code.WORKOUT_TOGETHER_INVITED, routineName));
    }

    void studyRoomInvited(Collection<UUID> invitees, UUID actorId, UUID roomId) {
        invitees.forEach(id -> send(id, actorId, "Estudiamos juntos", "%s te invita a estudiar juntos",
                HUB + "/study/" + roomId, "Ver", "study-room:" + roomId, Code.STUDY_ROOM_INVITED, null));
    }

    void streakNudged(UUID friendId, UUID actorId, UUID streakId, String day) {
        send(friendId, actorId, "Racha con un amigo", "Racha con %s: te falta tu parte de hoy", HUB, "Ver",
                "friend-streak-nudge:" + streakId + ":" + day, Code.FRIEND_STREAK_NUDGE, null);
    }

    private void send(UUID recipientId, UUID actorId, String title, String descriptionPattern, String actionUrl,
                      String actionLabel, String referenceKey, Code code, String subject) {
        if (recipientId.equals(actorId)) {
            return;
        }
        User actor = users.findById(actorId).orElse(null);
        if (actor == null || actor.shadowbanned()) {
            return;
        }
        Map<String, String> params = new LinkedHashMap<>();
        params.put("name", actor.fullName());
        if (subject != null) {
            params.put("title", subject);
        }
        notifications.create(new CreateNotificationUseCase.Command(recipientId, title,
                String.format(descriptionPattern, actor.fullName()), NotificationPriority.INFORMATIVE,
                NotificationType.SOCIAL, actionUrl, actionLabel, referenceKey, new NotificationMessage(code, params)));
    }
}
