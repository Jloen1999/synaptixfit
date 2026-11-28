package com.synaptixfit.domain.model.wod;

import java.time.LocalDate;
import java.util.UUID;

/**
 * La pizarra de hoy (ADR 0069): el WOD de la persona o, si no ha puesto ninguno, una plantilla de ejemplo, con su
 * mejor marca en cada división y la de hoy.
 *
 * @param wodId   nulo si es una plantilla de ejemplo todavía sin usar
 * @param example es una plantilla de ejemplo, no un WOD de la persona
 */
public record WodBoard(UUID wodId, LocalDate date, String templateCode, WodDefinition definition, boolean example,
                       WodResult bestRx, WodResult bestScaled, WodResult todayResult) {
}
