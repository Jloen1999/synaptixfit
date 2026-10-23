package com.synaptixfit.application.port.input.dashboard;

import com.synaptixfit.domain.model.dashboard.Dashboard;
import java.util.UUID;

/** Resumen completo del inicio (saludo, KPIs, estados, plan, retos, eventos de hoy y banner). */
public interface GetDashboardUseCase {

    Dashboard getDashboard(UUID userId, String timeZone);
}
