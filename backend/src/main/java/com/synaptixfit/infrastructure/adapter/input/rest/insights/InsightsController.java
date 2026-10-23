package com.synaptixfit.infrastructure.adapter.input.rest.insights;

import com.synaptixfit.application.port.input.insights.GetCognitiveStateUseCase;
import com.synaptixfit.application.port.input.insights.GetCrossRegulationUseCase;
import com.synaptixfit.application.port.input.insights.GetPhysicalLoadUseCase;
import com.synaptixfit.application.port.input.insights.GetStudyCaloriesTodayUseCase;
import com.synaptixfit.application.port.input.insights.GetWellbeingUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.CognitiveStateResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.CrossRegulationResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.PhysicalLoadResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.StudyCaloriesResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.insights.dto.InsightsResponses.WellbeingResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Indicadores neurofisiológicos del usuario autenticado. El parámetro opcional {@code tz} (zona IANA,
 * p. ej. {@code Europe/Madrid}) define qué es "hoy".
 */
@Tag(name = "Insights")
@RestController
@RequestMapping("/api/v1/insights")
public class InsightsController {

    private static final String TZ_DOC = "Zona horaria IANA del cliente (por defecto Europe/Madrid)";

    private final GetCrossRegulationUseCase crossRegulation;
    private final GetPhysicalLoadUseCase physicalLoad;
    private final GetCognitiveStateUseCase cognitiveState;
    private final GetStudyCaloriesTodayUseCase studyCalories;
    private final GetWellbeingUseCase wellbeing;

    public InsightsController(GetCrossRegulationUseCase crossRegulation, GetPhysicalLoadUseCase physicalLoad,
                              GetCognitiveStateUseCase cognitiveState, GetStudyCaloriesTodayUseCase studyCalories,
                              GetWellbeingUseCase wellbeing) {
        this.crossRegulation = crossRegulation;
        this.physicalLoad = physicalLoad;
        this.cognitiveState = cognitiveState;
        this.studyCalories = studyCalories;
        this.wellbeing = wellbeing;
    }

    @GetMapping("/cross-regulation")
    public CrossRegulationResponse crossRegulation(@CurrentUserId UUID userId,
                                                   @Parameter(description = TZ_DOC) @RequestParam(required = false) String tz) {
        return CrossRegulationResponse.from(crossRegulation.getCrossRegulation(userId, tz));
    }

    @GetMapping("/physical-load")
    public PhysicalLoadResponse physicalLoad(@CurrentUserId UUID userId,
                                             @Parameter(description = TZ_DOC) @RequestParam(required = false) String tz) {
        return PhysicalLoadResponse.from(physicalLoad.getPhysicalLoad(userId, tz));
    }

    @GetMapping("/cognitive-state")
    public CognitiveStateResponse cognitiveState(@CurrentUserId UUID userId,
                                                 @Parameter(description = TZ_DOC) @RequestParam(required = false) String tz) {
        return CognitiveStateResponse.from(cognitiveState.getCognitiveState(userId, tz));
    }

    @GetMapping("/study-calories/today")
    public StudyCaloriesResponse studyCaloriesToday(@CurrentUserId UUID userId,
                                                    @Parameter(description = TZ_DOC) @RequestParam(required = false) String tz) {
        return StudyCaloriesResponse.from(studyCalories.getStudyCaloriesToday(userId, tz));
    }

    @GetMapping("/wellbeing")
    public WellbeingResponse wellbeing(@CurrentUserId UUID userId,
                                       @Parameter(description = TZ_DOC) @RequestParam(required = false) String tz) {
        return WellbeingResponse.from(wellbeing.getWellbeing(userId, tz));
    }
}
