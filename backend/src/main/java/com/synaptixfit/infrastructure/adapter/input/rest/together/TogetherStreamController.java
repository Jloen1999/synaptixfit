package com.synaptixfit.infrastructure.adapter.input.rest.together;

import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * Canal en directo de «Con amigos» (ADR 0047): Server-Sent Events con avisos sin datos de las salas y los entrenos
 * juntos de la persona ({@code change: {type: studyRoom|workout|together, id}}). Lo abre el móvil mientras la app
 * está en primer plano; los permisos siguen en la API de siempre, que es la que vuelve a leer.
 */
@RestController
@RequestMapping("/api/v1/together")
@Tag(name = "Social - Together")
public class TogetherStreamController {

    private final TogetherStreamHub hub;

    public TogetherStreamController(TogetherStreamHub hub) {
        this.hub = hub;
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public ResponseEntity<SseEmitter> stream(@CurrentUserId UUID userId) {
        // X-Accel-Buffering: nginx no guarda el flujo en su búfer aunque la ruta no lo desactive.
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .header("X-Accel-Buffering", "no")
                .body(hub.open(userId));
    }
}
