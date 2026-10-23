package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.DailyActivityPoint;
import java.util.List;

/** Tendencia diaria de los últimos {@code days} días (1-90), hoy incluido. */
public interface GetActivityTrendUseCase {

    List<DailyActivityPoint> getActivityTrend(int days);
}
