package com.synaptixfit.domain.model.admin;

import java.util.Arrays;

/**
 * Acción administrativa registrada en la auditoría.
 *
 * <p>Cada valor conserva el código histórico en español que se guarda en
 * {@code admin_auditoria.accion}. Los códigos desconocidos (filas antiguas o de otros módulos)
 * se leen como {@link #OTHER}.
 */
public enum AuditAction {
    UPDATE_NAME("actualizar_nombre"),
    UPDATE_EMAIL("actualizar_email"),
    SET_PROGRESS("cambiar_progreso"),
    RESET_XP("reset_xp"),
    CHANGE_LEVEL("cambiar_nivel"),
    CHANGE_ROLE("cambiar_rol"),
    ACTIVATE_SHADOWBAN("activar_shadowban"),
    DEACTIVATE_SHADOWBAN("desactivar_shadowban"),
    WIPE_USER_DATA("wipe"),
    ANONYMIZE_USER("anonimizar_usuario"),
    DELETE_USER("eliminar_usuario"),
    EXPORT_USER_DATA("exportar_datos"),
    SELF_DELETE_ACCOUNT("baja_voluntaria"),
    ACTIVATE_LOCKDOWN("activar_lockdown"),
    DEACTIVATE_LOCKDOWN("desactivar_lockdown"),
    UPDATE_GLOBAL_SETTINGS("actualizar_config_global"),
    APPROVE_CONTENT("aprobar_contenido"),
    DELETE_CONTENT("eliminar_contenido"),
    CREATE_EXERCISE("crear_ejercicio"),
    EDIT_EXERCISE("editar_ejercicio"),
    ACTIVATE_EXERCISE("activar_ejercicio"),
    DEACTIVATE_EXERCISE("desactivar_ejercicio"),
    DELETE_EXERCISE("eliminar_ejercicio"),
    OTHER("otra");

    private final String code;

    AuditAction(String code) {
        this.code = code;
    }

    /** Código persistido. */
    public String code() {
        return code;
    }

    public static AuditAction fromCode(String code) {
        return Arrays.stream(values()).filter(a -> a.code.equals(code)).findFirst().orElse(OTHER);
    }
}
