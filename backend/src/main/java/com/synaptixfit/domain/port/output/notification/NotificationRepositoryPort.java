package com.synaptixfit.domain.port.output.notification;

import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.UnreadCounts;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de notificaciones. */
public interface NotificationRepositoryPort {

    Notification save(Notification notification);

    Optional<Notification> findById(UUID id);

    /** Notificaciones del usuario, más recientes primero. {@code priority} nulo = todas. */
    PageResult<Notification> findByUser(UUID userId, boolean unreadOnly, NotificationPriority priority,
                                        PageRequest page);

    UnreadCounts countUnread(UUID userId);

    /** Marca todas como leídas y devuelve cuántas cambiaron. */
    int markAllRead(UUID userId, Instant at);

    void delete(UUID id);

    long countCreatedSince(UUID userId, Instant since);

    /** ¿Tiene ya el usuario una notificación con esa clave de referencia ({@link Notification#referenceKey()})? */
    boolean existsByReferenceKey(UUID userId, String referenceKey);
}
