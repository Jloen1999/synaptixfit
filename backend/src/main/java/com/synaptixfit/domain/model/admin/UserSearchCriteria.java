package com.synaptixfit.domain.model.admin;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.user.Role;

/**
 * Búsqueda de usuarios del panel. {@code text} busca por nombre o email sin distinguir
 * mayúsculas; los filtros nulos no aplican.
 */
public record UserSearchCriteria(String text, Role role, Boolean shadowbanned, Status status, Integer minLevel,
                                 Integer maxLevel, SortField sort, SortDirection direction) {

    /** Estado de la cuenta: activa, eliminada/anonimizada o todas. */
    public enum Status { ACTIVE, DELETED, ALL }

    /** Campo de ordenación. {@code XP} ordena por experiencia total. */
    public enum SortField { CREATED_AT, LEVEL, XP, NAME, STREAK }

    /** Sentido de la ordenación. */
    public enum SortDirection { ASC, DESC }

    public UserSearchCriteria {
        text = text == null || text.isBlank() ? null : text.strip();
        if (text != null && text.length() > 120) {
            throw new FieldValidationException("query", "INVALID_LENGTH", "query is too long");
        }
        status = status == null ? Status.ACTIVE : status;
        sort = sort == null ? SortField.CREATED_AT : sort;
        direction = direction == null ? SortDirection.DESC : direction;
        if (minLevel != null && minLevel < 1) {
            throw new FieldValidationException("minLevel", "OUT_OF_RANGE", "minLevel must be >= 1");
        }
        if (maxLevel != null && maxLevel < 1) {
            throw new FieldValidationException("maxLevel", "OUT_OF_RANGE", "maxLevel must be >= 1");
        }
        if (minLevel != null && maxLevel != null && minLevel > maxLevel) {
            throw new FieldValidationException("minLevel", "OUT_OF_RANGE", "minLevel must be <= maxLevel");
        }
    }
}
