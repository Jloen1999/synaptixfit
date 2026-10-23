package com.synaptixfit.application.port.input.badge;

import com.synaptixfit.domain.model.badge.BadgeView;
import com.synaptixfit.domain.model.badge.StreakStatus;
import java.util.List;

/** Resultado de evaluar las insignias: las recién obtenidas y la racha diaria actualizada. */
public record BadgeEvaluation(List<BadgeView> newlyEarned, StreakStatus streak) {
}
