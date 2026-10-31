package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.notification;

import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationMessage;
import com.synaptixfit.domain.model.notification.NotificationMode;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification.NotificationEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.notification.NotificationPreferencesEntity;
import java.util.Arrays;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

/** Notificaciones y preferencias de dominio ↔ entidades. Enums en minúsculas en la base de datos. */
public final class NotificationPersistenceMapper {

    private NotificationPersistenceMapper() {
    }

    public static String toDb(Enum<?> value) {
        return value.name().toLowerCase(Locale.ROOT);
    }

    public static NotificationPriority priorityFromDb(String value) {
        return NotificationPriority.valueOf(value.toUpperCase(Locale.ROOT));
    }

    public static NotificationType typeFromDb(String value) {
        return NotificationType.valueOf(value.toUpperCase(Locale.ROOT));
    }

    public static String modeToDb(NotificationMode mode) {
        return switch (mode) {
            case NORMAL -> "normal";
            case EXAMS -> "examenes";
            case REST -> "descanso";
        };
    }

    public static NotificationMode modeFromDb(String value) {
        return switch (value) {
            case "examenes" -> NotificationMode.EXAMS;
            case "descanso" -> NotificationMode.REST;
            default -> NotificationMode.NORMAL;
        };
    }

    public static Notification toDomain(NotificationEntity e) {
        return new Notification(e.getId(), e.getUsuarioId(), e.getTitulo(), e.getDescripcion(),
                priorityFromDb(e.getPrioridad()), typeFromDb(e.getTipo()), e.getUrlAccion(), e.getEtiquetaAccion(),
                e.getClaveReferencia(), messageFromDb(e.getCodigoMensaje(), e.getParametrosMensaje()), e.isEstaLeida(),
                e.getCreadoEn(), e.getLeidaEn());
    }

    /** Un código que ya no existe se ignora: queda el texto guardado. */
    static NotificationMessage messageFromDb(String code, Map<String, String> params) {
        if (code == null) {
            return null;
        }
        try {
            return new NotificationMessage(NotificationMessage.Code.valueOf(code), params);
        } catch (IllegalArgumentException unknown) {
            return null;
        }
    }

    public static void copyToEntity(Notification n, NotificationEntity e) {
        e.setId(n.id());
        e.setUsuarioId(n.userId());
        e.setTitulo(n.title());
        e.setDescripcion(n.description());
        e.setPrioridad(toDb(n.priority()));
        e.setTipo(toDb(n.type()));
        e.setUrlAccion(n.actionUrl());
        e.setEtiquetaAccion(n.actionLabel());
        e.setClaveReferencia(n.referenceKey());
        e.setCodigoMensaje(n.message() == null ? null : n.message().code().name());
        e.setParametrosMensaje(n.message() == null ? null : n.message().params());
        e.setEstaLeida(n.read());
        e.setCreadoEn(n.createdAt());
        e.setLeidaEn(n.readAt());
    }

    /** Ignora categorías desconocidas que pudieran quedar de datos heredados. */
    public static NotificationPreferences toDomain(NotificationPreferencesEntity e) {
        var categories = Arrays.stream(e.getCategoriasActivas() == null ? new String[0] : e.getCategoriasActivas())
                .map(NotificationPersistenceMapper::typeOrNull)
                .filter(Objects::nonNull)
                .toList();
        return new NotificationPreferences(e.getId(), e.getUsuarioId(), categories, e.getHoraSilencioInicio(),
                e.getHoraSilencioFin(), e.getLimiteDiario(), modeFromDb(e.getModoActual()), e.getCreadoEn(),
                e.getActualizadoEn());
    }

    public static void copyToEntity(NotificationPreferences p, NotificationPreferencesEntity e) {
        e.setId(p.id());
        e.setUsuarioId(p.userId());
        e.setCategoriasActivas(p.activeCategories().stream().sorted().map(NotificationPersistenceMapper::toDb)
                .toArray(String[]::new));
        e.setHoraSilencioInicio(p.quietHoursStart());
        e.setHoraSilencioFin(p.quietHoursEnd());
        e.setLimiteDiario(p.dailyLimit());
        e.setModoActual(modeToDb(p.mode()));
        e.setCreadoEn(p.createdAt());
        e.setActualizadoEn(p.updatedAt());
    }

    private static NotificationType typeOrNull(String value) {
        try {
            return typeFromDb(value);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
