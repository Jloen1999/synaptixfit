package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import com.synaptixfit.application.port.input.planner.CreateCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.GetCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.ReadCalendarFeedUseCase;
import com.synaptixfit.application.port.input.planner.RevokeCalendarFeedUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.CalendarFeedDtos.CalendarFeedCreatedResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.planner.dto.CalendarFeedDtos.CalendarFeedStatusResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Suscripción al calendario: el usuario crea, consulta o revoca su enlace privado; Google, Apple u Outlook
 * leen el {@code .ics} sin sesión con ese enlace (ruta pública en {@code SecurityConfig}).
 */
@Tag(name = "Planner - calendar feed")
@RestController
@RequestMapping("/api/v1/planner/calendar-feed")
public class CalendarFeedController {

    private static final MediaType TEXT_CALENDAR = new MediaType("text", "calendar", StandardCharsets.UTF_8);

    private final CreateCalendarFeedUseCase create;
    private final RevokeCalendarFeedUseCase revoke;
    private final GetCalendarFeedUseCase status;
    private final ReadCalendarFeedUseCase read;

    public CalendarFeedController(CreateCalendarFeedUseCase create, RevokeCalendarFeedUseCase revoke,
                                  GetCalendarFeedUseCase status, ReadCalendarFeedUseCase read) {
        this.create = create;
        this.revoke = revoke;
        this.status = status;
        this.read = read;
    }

    @GetMapping
    public CalendarFeedStatusResponse status(@CurrentUserId UUID userId) {
        Instant since = status.activeSince(userId).orElse(null);
        return new CalendarFeedStatusResponse(since != null, since);
    }

    /** Crea el enlace (si había otro, deja de funcionar). */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CalendarFeedCreatedResponse create(@CurrentUserId UUID userId) {
        CreateCalendarFeedUseCase.Result r = create.createFeed(userId);
        return new CalendarFeedCreatedResponse(r.token(), r.createdAt());
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@CurrentUserId UUID userId) {
        revoke.revokeFeed(userId);
    }

    /** Calendario público del enlace (sin sesión). Los calendarios externos lo vuelven a pedir cada pocas horas. */
    @GetMapping("/{token}.ics")
    public ResponseEntity<String> feed(@PathVariable String token) {
        return ResponseEntity.ok()
                .contentType(TEXT_CALENDAR)
                .cacheControl(CacheControl.noStore())
                .header("X-Robots-Tag", "noindex, nofollow")
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"synaptixfit.ics\"")
                .body(read.readFeed(token));
    }
}
