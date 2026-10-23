package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.ScanScheduleUseCase;
import com.synaptixfit.application.port.input.planner.SuggestWeekPlanUseCase;
import com.synaptixfit.domain.exception.planner.ScheduleFileTooLargeException;
import com.synaptixfit.domain.exception.planner.UnsupportedScheduleFileException;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.ScheduleScanResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.SuggestionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.SuggestionResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.io.IOException;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/** Funciones de IA del planificador: escaneo de horarios y sugerencias de planificación semanal. */
@Tag(name = "Planner - AI")
@RestController
@RequestMapping("/api/v1/planner")
public class PlannerAiController {

    private final ScanScheduleUseCase scanSchedule;
    private final SuggestWeekPlanUseCase suggestWeekPlan;

    public PlannerAiController(ScanScheduleUseCase scanSchedule, SuggestWeekPlanUseCase suggestWeekPlan) {
        this.scanSchedule = scanSchedule;
        this.suggestWeekPlan = suggestWeekPlan;
    }

    /** Escanea un horario (PDF o imagen, máx. 10 MB, campo {@code file}) y crea las clases del semestre. */
    @PostMapping(value = "/schedule-scan", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ScheduleScanResponse scan(@CurrentUserId UUID userId, @RequestPart("file") MultipartFile file) {
        if (file.isEmpty()) {
            throw new UnsupportedScheduleFileException();
        }
        if (file.getSize() > ScanScheduleUseCase.MAX_BYTES) {
            throw new ScheduleFileTooLargeException();
        }
        byte[] content;
        try {
            content = file.getBytes();
        } catch (IOException e) {
            throw new UnsupportedScheduleFileException();
        }
        return ScheduleScanResponse.from(scanSchedule.scan(
                new ScanScheduleUseCase.Command(userId, content, file.getContentType())));
    }

    /** Propuesta (no guardada) de bloques de estudio y deporte para la semana. */
    @PostMapping("/suggestions")
    public SuggestionResponse suggest(@CurrentUserId UUID userId, @Valid @RequestBody SuggestionRequest r) {
        return SuggestionResponse.from(suggestWeekPlan.suggest(new SuggestWeekPlanUseCase.Command(userId,
                r.weekStart(), r.studyHours(), r.sportSessions(),
                r.minutesPerSportSession() == null ? 60 : r.minutesPerSportSession(),
                r.maxStudyBlockMinutes() == null ? 90 : r.maxStudyBlockMinutes())));
    }
}
