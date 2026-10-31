package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Qué dice un aviso automático, como código y datos: el cliente pone el texto en el idioma de quien
 * lo lee (el título y la descripción guardados quedan en español como respaldo). Los avisos escritos a
 * mano (administración) no llevan mensaje.
 *
 * @param params datos del texto (nombre del reto, nivel, persona…), siempre como texto
 */
public record NotificationMessage(Code code, Map<String, String> params) {

    public enum Code {
        CHALLENGE_COMPLETED,
        BADGE_EARNED,
        LEVEL_UP,
        FATIGUE_CHECK_IN,
        OVERTRAINING,
        POST_LIKED,
        POST_COMMENTED,
        FRIEND_REQUEST_RECEIVED,
        FRIEND_REQUEST_ACCEPTED
    }

    public NotificationMessage {
        Guard.notNull(code, "code");
        params = params == null ? Map.of() : Map.copyOf(params);
    }

    public static NotificationMessage of(Code code) {
        return new NotificationMessage(code, Map.of());
    }

    /** Mensaje con un dato ({@code of(LEVEL_UP, "level", "5")}); un valor nulo se omite. */
    public static NotificationMessage of(Code code, String key, String value) {
        Map<String, String> params = new LinkedHashMap<>();
        if (value != null) {
            params.put(key, value);
        }
        return new NotificationMessage(code, params);
    }
}
