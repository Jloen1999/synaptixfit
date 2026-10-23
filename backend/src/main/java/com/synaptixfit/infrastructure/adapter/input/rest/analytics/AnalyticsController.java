package com.synaptixfit.infrastructure.adapter.input.rest.analytics;

import com.synaptixfit.application.port.input.analytics.GetAnalyticsInsightsUseCase;
import com.synaptixfit.application.port.input.analytics.GetLoadCorrelationUseCase;
import com.synaptixfit.application.port.input.analytics.GetRpeTrendUseCase;
import com.synaptixfit.application.port.input.analytics.GetStudyWeekSummaryUseCase;
import com.synaptixfit.application.port.input.analytics.GetTrainingVolumeUseCase;
import com.synaptixfit.application.port.input.analytics.GetWeeklyAnalyticsUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.analytics.dto.AnalyticsResponses.CorrelationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.analytics.dto.AnalyticsResponses.InsightResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.analytics.dto.AnalyticsResponses.RpeTrendResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.analytics.dto.AnalyticsResponses.StudyWeekResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.analytics.dto.AnalyticsResponses.TrainingVolumeResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.analytics.dto.AnalyticsResponses.WeeklyAnalyticsResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Analítica de entrenamiento y su relación con la carga académica. */
@Tag(name = "Analytics")
@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {

    private static final String PERIOD_DOC = "WEEKLY (4 semanas), MONTHLY (12, por defecto) o QUARTERLY (26)";

    private final GetWeeklyAnalyticsUseCase weekly;
    private final GetRpeTrendUseCase rpeTrend;
    private final GetTrainingVolumeUseCase volume;
    private final GetLoadCorrelationUseCase correlation;
    private final GetAnalyticsInsightsUseCase insights;
    private final GetStudyWeekSummaryUseCase studyWeek;

    public AnalyticsController(GetWeeklyAnalyticsUseCase weekly, GetRpeTrendUseCase rpeTrend,
                               GetTrainingVolumeUseCase volume, GetLoadCorrelationUseCase correlation,
                               GetAnalyticsInsightsUseCase insights, GetStudyWeekSummaryUseCase studyWeek) {
        this.weekly = weekly;
        this.rpeTrend = rpeTrend;
        this.volume = volume;
        this.correlation = correlation;
        this.insights = insights;
        this.studyWeek = studyWeek;
    }

    /** «Tu estudio»: concentración, bloques de estudio, repasos y simulacros de la semana en curso. */
    @GetMapping("/study-week")
    public StudyWeekResponse studyWeek(@CurrentUserId UUID userId) {
        return StudyWeekResponse.from(studyWeek.getStudyWeekSummary(userId));
    }

    @GetMapping("/weekly")
    public WeeklyAnalyticsResponse weekly(@CurrentUserId UUID userId,
                                          @Parameter(description = PERIOD_DOC) @RequestParam(required = false) String period) {
        return WeeklyAnalyticsResponse.from(weekly.getWeeklyAnalytics(userId, period));
    }

    @GetMapping("/rpe-trend")
    public RpeTrendResponse rpeTrend(@CurrentUserId UUID userId,
                                     @Parameter(description = PERIOD_DOC) @RequestParam(required = false) String period) {
        return RpeTrendResponse.from(rpeTrend.getRpeTrend(userId, period));
    }

    @GetMapping("/volume")
    public TrainingVolumeResponse volume(@CurrentUserId UUID userId,
                                         @Parameter(description = PERIOD_DOC) @RequestParam(required = false) String period) {
        return TrainingVolumeResponse.from(volume.getTrainingVolume(userId, period));
    }

    @GetMapping("/correlation")
    public CorrelationResponse correlation(@CurrentUserId UUID userId,
                                           @Parameter(description = "RPE (por defecto) o MINUTES")
                                           @RequestParam(required = false) String metric) {
        return CorrelationResponse.from(correlation.getLoadCorrelation(userId, metric));
    }

    @GetMapping("/insights")
    public List<InsightResponse> insights(@CurrentUserId UUID userId,
                                          @Parameter(description = PERIOD_DOC) @RequestParam(required = false) String period) {
        return insights.getAnalyticsInsights(userId, period).stream().map(InsightResponse::from).toList();
    }
}
