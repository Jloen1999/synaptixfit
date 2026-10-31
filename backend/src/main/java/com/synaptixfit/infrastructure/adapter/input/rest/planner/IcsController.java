package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.ExportIcsUseCase;
import com.synaptixfit.application.port.input.planner.ImportGeneralCalendarUseCase;
import com.synaptixfit.application.port.input.planner.ImportIcsUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.IcsImportRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.IcsImportResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Importación y exportación iCalendar. */
@Tag(name = "Planner - ICS")
@RestController
@RequestMapping("/api/v1/planner/ics")
public class IcsController {

    private static final MediaType TEXT_CALENDAR = new MediaType("text", "calendar", StandardCharsets.UTF_8);

    private final ImportIcsUseCase importIcs;
    private final ImportGeneralCalendarUseCase importGeneral;
    private final ExportIcsUseCase exportIcs;
    private final Clock clock;

    public IcsController(ImportIcsUseCase importIcs, ImportGeneralCalendarUseCase importGeneral,
                         ExportIcsUseCase exportIcs, Clock clock) {
        this.importIcs = importIcs;
        this.importGeneral = importGeneral;
        this.exportIcs = exportIcs;
        this.clock = clock;
    }

    /** Con {@code subjectId}, el calendario de esa asignatura; sin él, uno general como el del Campus Virtual. */
    @PostMapping("/import")
    public IcsImportResponse importIcs(@CurrentUserId UUID userId, @Valid @RequestBody IcsImportRequest r) {
        if (r.subjectId() == null) {
            return IcsImportResponse.from(importGeneral.importGeneral(
                    new ImportGeneralCalendarUseCase.Command(userId, r.url())));
        }
        return IcsImportResponse.from(importIcs.importIcs(new ImportIcsUseCase.Command(userId, r.subjectId(), r.url(),
                Boolean.TRUE.equals(r.force()))));
    }

    /** Calendario del usuario en [from, to) (por defecto de hace 30 días a dentro de 180; máx. 400 días). */
    @GetMapping("/export")
    public ResponseEntity<String> export(@CurrentUserId UUID userId,
                                         @RequestParam(required = false) Instant from,
                                         @RequestParam(required = false) Instant to) {
        Instant now = clock.instant();
        Instant start = from == null ? now.minus(Duration.ofDays(30)) : from;
        Instant end = to == null ? now.plus(Duration.ofDays(180)) : to;
        return ResponseEntity.ok()
                .contentType(TEXT_CALENDAR)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename("synaptixfit.ics").build().toString())
                .body(exportIcs.exportIcs(userId, start, end));
    }
}
