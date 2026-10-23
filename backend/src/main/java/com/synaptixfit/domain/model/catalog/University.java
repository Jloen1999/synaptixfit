package com.synaptixfit.domain.model.catalog;

import java.util.UUID;

/**
 * Universidad del catálogo. {@code type} (Pública/Privada) y {@code region} (comunidad autónoma)
 * vienen del RUCT y ayudan a distinguir universidades con nombres parecidos.
 */
public record University(UUID id, String name, String type, String region) {

    public University(UUID id, String name) {
        this(id, name, null, null);
    }
}
