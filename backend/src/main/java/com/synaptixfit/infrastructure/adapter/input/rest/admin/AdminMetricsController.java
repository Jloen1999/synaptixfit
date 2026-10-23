package com.synaptixfit.infrastructure.adapter.input.rest.admin;

import com.synaptixfit.application.port.input.admin.GetActivityTrendUseCase;
import com.synaptixfit.application.port.input.admin.GetPlatformMetricsUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.DailyActivityResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.PlatformMetricsResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Indicadores globales del panel de administración. */
@Tag(name = "Admin - Metrics")
@RestController
@RequestMapping("/api/v1/admin/metrics")
public class AdminMetricsController {

    private final GetPlatformMetricsUseCase getPlatformMetrics;
    private final GetActivityTrendUseCase getActivityTrend;

    public AdminMetricsController(GetPlatformMetricsUseCase getPlatformMetrics,
                                  GetActivityTrendUseCase getActivityTrend) {
        this.getPlatformMetrics = getPlatformMetrics;
        this.getActivityTrend = getActivityTrend;
    }

    @GetMapping
    public PlatformMetricsResponse metrics() {
        return PlatformMetricsResponse.from(getPlatformMetrics.getPlatformMetrics());
    }

    @GetMapping("/trend")
    public List<DailyActivityResponse> trend(@RequestParam(defaultValue = "30") int days) {
        return getActivityTrend.getActivityTrend(days).stream().map(DailyActivityResponse::from).toList();
    }
}
