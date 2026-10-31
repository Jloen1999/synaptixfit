package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import com.synaptixfit.application.port.input.notification.ConfirmWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.DisableWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.EnableWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.GetWeeklyEmailStatusUseCase;
import com.synaptixfit.application.port.input.notification.UnsubscribeWeeklyEmailUseCase;
import com.synaptixfit.application.port.input.notification.WeeklyEmailStatus;
import com.synaptixfit.domain.exception.notification.WeeklyEmailLinkInvalidException;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.i18n.RequestLanguage;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Resumen semanal por correo (ADR 0022): estado, activar y desactivar desde la app, y las dos páginas públicas
 * que abren los enlaces del correo (confirmar y darse de baja, esta también por POST para la baja con un clic de
 * los clientes de correo).
 */
@Tag(name = "Notifications")
@RestController
@RequestMapping("/api/v1/notifications/weekly-email")
public class WeeklyEmailController {

    private static final MediaType HTML = new MediaType("text", "html", StandardCharsets.UTF_8);

    /** Respuesta de estado: {@code OFF}, {@code PENDING} (falta confirmar por correo) o {@code ACTIVE}. */
    public record WeeklyEmailResponse(WeeklyEmailStatus status) {
    }

    private final GetWeeklyEmailStatusUseCase getStatus;
    private final EnableWeeklyEmailUseCase enable;
    private final DisableWeeklyEmailUseCase disable;
    private final ConfirmWeeklyEmailUseCase confirm;
    private final UnsubscribeWeeklyEmailUseCase unsubscribe;

    public WeeklyEmailController(GetWeeklyEmailStatusUseCase getStatus, EnableWeeklyEmailUseCase enable,
                                 DisableWeeklyEmailUseCase disable, ConfirmWeeklyEmailUseCase confirm,
                                 UnsubscribeWeeklyEmailUseCase unsubscribe) {
        this.getStatus = getStatus;
        this.enable = enable;
        this.disable = disable;
        this.confirm = confirm;
        this.unsubscribe = unsubscribe;
    }

    @GetMapping
    public WeeklyEmailResponse status(@CurrentUserId UUID userId) {
        return new WeeklyEmailResponse(getStatus.getWeeklyEmailStatus(userId));
    }

    /** Activa en el idioma de la app; si el correo no está verificado, queda pendiente de confirmar. */
    @PutMapping
    public WeeklyEmailResponse enable(@CurrentUserId UUID userId) {
        return new WeeklyEmailResponse(enable.enableWeeklyEmail(userId, RequestLanguage.code()));
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void disable(@CurrentUserId UUID userId) {
        disable.disableWeeklyEmail(userId);
    }

    /** Abrir el enlace solo enseña el botón: confirma el POST (ver {@link WeeklyEmailPages}). */
    @GetMapping("/confirm")
    public ResponseEntity<String> confirmPage(@RequestParam(required = false) String token) {
        return html(HttpStatus.OK, WeeklyEmailPages.render(WeeklyEmailPages.Kind.CONFIRM_PROMPT,
                RequestLanguage.code(), token));
    }

    @PostMapping("/confirm")
    public ResponseEntity<String> confirm(@RequestParam(required = false) String token) {
        try {
            return html(HttpStatus.OK, WeeklyEmailPages.render(WeeklyEmailPages.Kind.CONFIRMED,
                    confirm.confirmWeeklyEmail(token), null));
        } catch (WeeklyEmailLinkInvalidException e) {
            return html(HttpStatus.NOT_FOUND, WeeklyEmailPages.render(WeeklyEmailPages.Kind.INVALID,
                    RequestLanguage.code(), null));
        }
    }

    @GetMapping("/unsubscribe")
    public ResponseEntity<String> unsubscribePage(@RequestParam(required = false) String token) {
        return html(HttpStatus.OK, WeeklyEmailPages.render(WeeklyEmailPages.Kind.UNSUBSCRIBE_PROMPT,
                RequestLanguage.code(), token));
    }

    /**
     * Baja con un clic: la piden también los clientes de correo (RFC 8058, {@code List-Unsubscribe-Post}). Es
     * idempotente: con un enlace que ya no existe se muestra igualmente que no hay suscripción.
     */
    @PostMapping("/unsubscribe")
    public ResponseEntity<String> unsubscribe(@RequestParam(required = false) String token) {
        String language;
        try {
            language = unsubscribe.unsubscribeWeeklyEmail(token);
        } catch (WeeklyEmailLinkInvalidException e) {
            language = RequestLanguage.code();
        }
        return html(HttpStatus.OK, WeeklyEmailPages.render(WeeklyEmailPages.Kind.UNSUBSCRIBED, language, null));
    }

    private static ResponseEntity<String> html(HttpStatus status, String body) {
        return ResponseEntity.status(status).contentType(HTML).cacheControl(CacheControl.noStore())
                .header("X-Robots-Tag", "noindex, nofollow").body(body);
    }
}
