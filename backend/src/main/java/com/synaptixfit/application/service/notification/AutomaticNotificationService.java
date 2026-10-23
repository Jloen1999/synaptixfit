package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.notification.NotifyAchievementUseCase;
import com.synaptixfit.application.port.input.notification.NotifyFatigueAlertUseCase;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import com.synaptixfit.domain.port.output.notification.NotificationRepositoryPort;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Locale;
import java.util.UUID;

/**
 * Notificaciones que genera el sistema a partir de eventos de otros módulos (logros y fatiga). Crea
 * con {@link CreateNotificationUseCase}, que aplica las preferencias del receptor, y evita duplicados
 * con una clave de referencia estable ({@link NotificationRepositoryPort#existsByReferenceKey}): un
 * logro se avisa una sola vez por reto, insignia o nivel, y un aviso de fatiga una vez al día por motivo.
 *
 * <p>{@code actionUrl} lleva rutas del cliente: {@code /challenges/{id}}, {@code /profile},
 * {@code /training} y {@code /progress}.
 */
public class AutomaticNotificationService implements NotifyAchievementUseCase, NotifyFatigueAlertUseCase {

    private final CreateNotificationUseCase notifications;
    private final NotificationRepositoryPort repository;
    private final Clock clock;
    private final ZoneId zone;

    public AutomaticNotificationService(CreateNotificationUseCase notifications, NotificationRepositoryPort repository,
                                        Clock clock, ZoneId zone) {
        this.notifications = notifications;
        this.repository = repository;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public void notifyAchievement(NotifyAchievementUseCase.Command c) {
        switch (c.kind()) {
            case CHALLENGE_COMPLETED -> send(c.userId(), "challenge:" + c.referenceId(), NotificationType.MILESTONE,
                    NotificationPriority.INFORMATIVE, "¡Reto completado!", "Has completado el reto «" + c.name() + "»",
                    "/challenges/" + c.referenceId(), "Ver reto");
            case BADGE_EARNED -> send(c.userId(), "badge:" + c.referenceId(), NotificationType.MILESTONE,
                    NotificationPriority.INFORMATIVE, "¡Nueva insignia!",
                    "Has desbloqueado la insignia «" + c.name() + "»", "/profile", "Ver insignias");
            case LEVEL_UP -> send(c.userId(), "level:" + c.name(), NotificationType.MILESTONE,
                    NotificationPriority.INFORMATIVE, "¡Has subido de nivel!", "Ya eres nivel " + c.name(), "/profile",
                    "Ver perfil");
        }
    }

    @Override
    public void notifyFatigue(NotifyFatigueAlertUseCase.Command c) {
        // El día va en la clave: el mismo motivo puede volver a avisarse mañana.
        String key = "fatigue:" + c.reason().name().toLowerCase(Locale.ROOT) + ":"
                + LocalDate.ofInstant(clock.instant(), zone);
        switch (c.reason()) {
            case CHECK_IN_ADAPTATION -> send(c.userId(), key, NotificationType.FATIGUE_ALERT,
                    NotificationPriority.RECOMMENDED, "Hoy conviene adaptar el entrenamiento",
                    "Tu check-in indica mucha fatiga: baja la intensidad o tómate el día de descanso.",
                    "/training", "Ver entrenamiento");
            case OVERTRAINING -> send(c.userId(), key, NotificationType.FATIGUE_ALERT,
                    NotificationPriority.RECOMMENDED, "Riesgo de sobreentrenamiento",
                    String.format(Locale.ROOT, "Tu carga de esta semana es %.2f veces tu media del mes: prioriza "
                            + "el descanso y acorta los bloques de estudio.", c.acwr() == null ? 0 : c.acwr()),
                    "/progress", "Ver indicadores");
        }
    }

    /**
     * Solo crea la notificación si el usuario no tiene ya una con la misma clave. La clave es el id
     * del reto o la insignia (no su título: dos retos pueden llamarse igual) o el número de nivel.
     */
    private void send(UUID userId, String referenceKey, NotificationType type, NotificationPriority priority,
                      String title, String description, String actionUrl, String actionLabel) {
        if (repository.existsByReferenceKey(userId, referenceKey)) {
            return;
        }
        notifications.create(new CreateNotificationUseCase.Command(userId, title, description, priority, type,
                actionUrl, actionLabel, referenceKey));
    }
}
