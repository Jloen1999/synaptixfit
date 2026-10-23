package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.UUID;

/**
 * Genera las notificaciones sociales (likes, comentarios y amistad). No se notifica a uno mismo
 * ni las acciones de usuarios con shadowban (son invisibles para los demás). Las preferencias del
 * receptor se aplican en {@link CreateNotificationUseCase}.
 *
 * <p>{@code actionUrl} lleva rutas del cliente: {@code /social/posts/{id}},
 * {@code /social/friends/requests} y {@code /social/users/{id}}.
 */
public final class SocialNotifier {

    private final CreateNotificationUseCase notifications;
    private final UserRepositoryPort users;

    public SocialNotifier(CreateNotificationUseCase notifications, UserRepositoryPort users) {
        this.notifications = notifications;
        this.users = users;
    }

    public void postLiked(UUID postAuthorId, UUID postId, UUID actorId) {
        send(postAuthorId, actorId, "Nuevo me gusta", "%s ha dado me gusta a tu publicación",
                "/social/posts/" + postId, "Ver publicación");
    }

    public void postCommented(UUID postAuthorId, UUID postId, UUID actorId) {
        send(postAuthorId, actorId, "Nuevo comentario", "%s ha comentado tu publicación",
                "/social/posts/" + postId, "Ver comentario");
    }

    public void friendRequestReceived(UUID addresseeId, UUID requesterId) {
        send(addresseeId, requesterId, "Nueva solicitud de amistad", "%s quiere añadirte como amigo",
                "/social/friends/requests", "Ver solicitud");
    }

    public void friendRequestAccepted(UUID requesterId, UUID accepterId) {
        send(requesterId, accepterId, "Solicitud aceptada", "%s ha aceptado tu solicitud de amistad",
                "/social/users/" + accepterId, "Ver perfil");
    }

    private void send(UUID recipientId, UUID actorId, String title, String descriptionPattern, String actionUrl,
                      String actionLabel) {
        if (recipientId.equals(actorId)) {
            return;
        }
        User actor = users.findById(actorId).orElse(null);
        if (actor == null || actor.shadowbanned()) {
            return;
        }
        notifications.create(new CreateNotificationUseCase.Command(recipientId, title,
                String.format(descriptionPattern, actor.fullName()), NotificationPriority.INFORMATIVE,
                NotificationType.SOCIAL, actionUrl, actionLabel));
    }
}
