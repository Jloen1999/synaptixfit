package com.synaptixfit.infrastructure.adapter.input.rest.dashboard;

import com.synaptixfit.application.port.input.dashboard.GetDashboardUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.dashboard.dto.DashboardResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Resumen del inicio en una sola llamada. */
@Tag(name = "Dashboard")
@RestController
@RequestMapping("/api/v1/dashboard")
public class DashboardController {

    private final GetDashboardUseCase getDashboard;

    public DashboardController(GetDashboardUseCase getDashboard) {
        this.getDashboard = getDashboard;
    }

    @GetMapping
    public DashboardResponse dashboard(@CurrentUserId UUID userId,
                                       @Parameter(description = "Zona horaria IANA del cliente (por defecto Europe/Madrid)")
                                       @RequestParam(required = false) String tz) {
        return DashboardResponse.from(getDashboard.getDashboard(userId, tz));
    }
}
