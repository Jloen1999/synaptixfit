package com.synaptixfit.infrastructure.adapter.input.scheduler;

import com.synaptixfit.infrastructure.adapter.input.rest.together.TogetherStreamHub;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Latido del canal en directo (ADR 0047) cada 25 s: por debajo de los 60 s de nginx y los 100 s de Cloudflare sin
 * tráfico, así ninguno corta la conexión; y los canales rotos se descubren y se quitan del registro.
 */
@Component
public class TogetherStreamHeartbeat {

    private final TogetherStreamHub hub;

    public TogetherStreamHeartbeat(TogetherStreamHub hub) {
        this.hub = hub;
    }

    @Scheduled(fixedRateString = "${synaptixfit.together.stream-heartbeat-ms:25000}",
            initialDelayString = "${synaptixfit.together.stream-heartbeat-ms:25000}")
    public void beat() {
        hub.heartbeat();
    }
}
