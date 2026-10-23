package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import com.synaptixfit.application.port.input.notification.CountUnreadNotificationsUseCase;
import com.synaptixfit.application.port.input.notification.DeleteNotificationUseCase;
import com.synaptixfit.application.port.input.notification.GetNotificationPreferencesUseCase;
import com.synaptixfit.application.port.input.notification.ListNotificationsUseCase;
import com.synaptixfit.application.port.input.notification.MarkAllNotificationsReadUseCase;
import com.synaptixfit.application.port.input.notification.MarkNotificationReadUseCase;
import com.synaptixfit.application.port.input.notification.UpdateNotificationPreferencesUseCase;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.notification.dto.MarkAllReadResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.notification.dto.NotificationPreferencesResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.notification.dto.NotificationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.notification.dto.UnreadCountResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.notification.dto.UpdateNotificationPreferencesRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Centro de notificaciones del usuario y sus preferencias. */
@Tag(name = "Notifications")
@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final ListNotificationsUseCase listNotifications;
    private final CountUnreadNotificationsUseCase countUnread;
    private final MarkNotificationReadUseCase markRead;
    private final MarkAllNotificationsReadUseCase markAllRead;
    private final DeleteNotificationUseCase deleteNotification;
    private final GetNotificationPreferencesUseCase getPreferences;
    private final UpdateNotificationPreferencesUseCase updatePreferences;

    public NotificationController(ListNotificationsUseCase listNotifications,
                                  CountUnreadNotificationsUseCase countUnread, MarkNotificationReadUseCase markRead,
                                  MarkAllNotificationsReadUseCase markAllRead,
                                  DeleteNotificationUseCase deleteNotification,
                                  GetNotificationPreferencesUseCase getPreferences,
                                  UpdateNotificationPreferencesUseCase updatePreferences) {
        this.listNotifications = listNotifications;
        this.countUnread = countUnread;
        this.markRead = markRead;
        this.markAllRead = markAllRead;
        this.deleteNotification = deleteNotification;
        this.getPreferences = getPreferences;
        this.updatePreferences = updatePreferences;
    }

    @GetMapping
    public PageResponse<NotificationResponse> list(@CurrentUserId UUID userId,
                                                   @RequestParam(defaultValue = "false") boolean unreadOnly,
                                                   @RequestParam(required = false) NotificationPriority priority,
                                                   @RequestParam(defaultValue = "0") int page,
                                                   @RequestParam(defaultValue = "20") int size) {
        return PageResponse.from(listNotifications.list(new ListNotificationsUseCase.Query(userId, unreadOnly,
                priority, new PageRequest(page, size))), NotificationResponse::from);
    }

    @GetMapping("/unread-count")
    public UnreadCountResponse unreadCount(@CurrentUserId UUID userId) {
        return UnreadCountResponse.from(countUnread.countUnread(userId));
    }

    @PostMapping("/{notificationId}/read")
    public NotificationResponse markRead(@CurrentUserId UUID userId, @PathVariable UUID notificationId) {
        return NotificationResponse.from(markRead.markRead(userId, notificationId));
    }

    @PostMapping("/read-all")
    public MarkAllReadResponse markAllRead(@CurrentUserId UUID userId) {
        return new MarkAllReadResponse(markAllRead.markAllRead(userId));
    }

    @DeleteMapping("/{notificationId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@CurrentUserId UUID userId, @PathVariable UUID notificationId) {
        deleteNotification.delete(userId, notificationId);
    }

    @GetMapping("/preferences")
    public NotificationPreferencesResponse preferences(@CurrentUserId UUID userId) {
        return NotificationPreferencesResponse.from(getPreferences.getPreferences(userId));
    }

    @PutMapping("/preferences")
    public NotificationPreferencesResponse updatePreferences(@CurrentUserId UUID userId,
                                                             @Valid @RequestBody UpdateNotificationPreferencesRequest r) {
        return NotificationPreferencesResponse.from(updatePreferences.updatePreferences(
                new UpdateNotificationPreferencesUseCase.Command(userId, r.activeCategories(), r.quietHoursStart(),
                        r.quietHoursEnd(), r.dailyLimit(), r.mode())));
    }
}
