package com.synaptixfit.domain.model.catalog;

import java.time.Instant;

/** Carrera vinculada por el usuario. */
public record UserDegree(Degree degree, Instant linkedAt) {
}
