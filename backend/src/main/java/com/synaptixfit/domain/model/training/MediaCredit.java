package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;

/**
 * Quién hizo la foto o el vídeo de un ejercicio y con qué licencia (ADR 0056). Solo los medios añadidos de fuentes
 * abiertas lo tienen; la ficha del ejercicio lo enseña porque las licencias Creative Commons piden atribución.
 *
 * @param source     fuente de la que se tomó («wger», «free-exercise-db»)
 * @param author     autor si la fuente lo da (puede faltar)
 * @param workUrl    página de la obra o de la fuente (puede faltar)
 */
public record MediaCredit(Kind kind, String source, String license, String licenseUrl, String author,
                          String workUrl) {

    /** Si el crédito es de la foto o del vídeo. */
    public enum Kind { PHOTO, VIDEO }

    public MediaCredit {
        Guard.notNull(kind, "kind");
        Guard.notBlank(source, "source");
        Guard.notBlank(license, "license");
        Guard.notBlank(licenseUrl, "licenseUrl");
    }
}
