package com.synaptixfit.domain.model.admin;

import java.util.Arrays;

/** Tipo de entidad afectada por una acción auditada (código persistido = nombre de la tabla). */
public enum AuditEntity {
    USER("usuarios"),
    PLATFORM_SETTINGS("configuracion_global"),
    EXERCISE("ejercicios"),
    SOCIAL_POST("actividades_sociales"),
    COMMENT("comentarios_feed"),
    OTHER("otra");

    private final String code;

    AuditEntity(String code) {
        this.code = code;
    }

    public String code() {
        return code;
    }

    public static AuditEntity fromCode(String code) {
        return Arrays.stream(values()).filter(a -> a.code.equals(code)).findFirst().orElse(OTHER);
    }
}
