package com.synaptixfit.infrastructure.adapter.input.rest.together;

import com.synaptixfit.domain.model.together.TogetherLiveChange;
import java.io.IOException;
import java.time.Duration;
import java.util.Collection;
import java.util.Deque;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.function.Supplier;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * Registro en memoria de los canales en directo abiertos (SSE, ADR 0047), por persona. Vale porque el backend corre en
 * una sola instancia: con varias, cada una solo conocería sus conexiones y haría falta un bus común (REQUISITOS-INFRA).
 * Solo manda avisos sin datos ({@code {"type":"workout","id":"…"}}): el móvil vuelve a leer por la API de siempre.
 */
@Component
public class TogetherStreamHub {

    /** Móvil, web y alguna pestaña más: con más, se cierra la más antigua (una app que no cerró bien su canal). */
    static final int MAX_PER_PERSON = 3;
    /**
     * Cada canal se cierra a los 15 min y el móvil abre otro: así vuelve a pasar por la autenticación con su token
     * vigente y no quedan conexiones colgadas. Se fija aquí para no depender de {@code spring.mvc.async.request-timeout}
     * (30 s por defecto en Tomcat), que cortaría el canal.
     */
    static final Duration TIMEOUT = Duration.ofMinutes(15);

    private final Map<UUID, Deque<SseEmitter>> byPerson = new ConcurrentHashMap<>();

    /** Abre un canal para {@code userId}. El primer mensaje ({@code ready}) confirma al móvil que está conectado. */
    public SseEmitter open(UUID userId) {
        SseEmitter emitter = new SseEmitter(TIMEOUT.toMillis());
        Deque<SseEmitter> queue = byPerson.compute(userId, (id, q) -> {
            Deque<SseEmitter> result = q == null ? new ConcurrentLinkedDeque<>() : q;
            result.addLast(emitter);
            return result;
        });
        while (queue.size() > MAX_PER_PERSON) {
            SseEmitter oldest = queue.pollFirst();
            if (oldest != null) {
                oldest.complete();
            }
        }
        emitter.onCompletion(() -> remove(userId, emitter));
        emitter.onTimeout(() -> {
            remove(userId, emitter);
            emitter.complete();
        });
        emitter.onError(e -> remove(userId, emitter));
        send(userId, emitter, SseEmitter.event().name("ready").data("{}"));
        return emitter;
    }

    /** Manda el aviso a cada canal abierto de cada destinatario; los canales rotos se quitan. */
    public void publish(TogetherLiveChange change) {
        String data = "{\"type\":\"" + type(change.topic()) + "\",\"id\":\"" + change.id() + "\"}";
        deliver(change.recipients(), () -> SseEmitter.event().name("change").data(data));
    }

    /**
     * Latido: un comentario SSE que el cliente ignora. Mantiene viva la conexión a través de nginx, Traefik y
     * Cloudflare (que cortan una conexión sin tráfico) y descubre los canales rotos.
     */
    public void heartbeat() {
        deliver(List.copyOf(byPerson.keySet()), () -> SseEmitter.event().comment("ping"));
    }

    /** Canales abiertos de una persona (para los tests). */
    public int connections(UUID userId) {
        Deque<SseEmitter> queue = byPerson.get(userId);
        return queue == null ? 0 : queue.size();
    }

    static String type(TogetherLiveChange.Topic topic) {
        return switch (topic) {
            case STUDY_ROOM -> "studyRoom";
            case WORKOUT -> "workout";
            case TOGETHER -> "together";
        };
    }

    private void deliver(Collection<UUID> users, Supplier<SseEmitter.SseEventBuilder> event) {
        for (UUID userId : users) {
            Deque<SseEmitter> queue = byPerson.get(userId);
            if (queue != null) {
                List.copyOf(queue).forEach(emitter -> send(userId, emitter, event.get()));
            }
        }
    }

    private void send(UUID userId, SseEmitter emitter, SseEmitter.SseEventBuilder event) {
        try {
            emitter.send(event);
        } catch (IOException | IllegalStateException e) {
            // El móvil cerró la conexión (o ya estaba cerrada): fuera del registro; abrirá otra al volver.
            remove(userId, emitter);
            emitter.complete();
        }
    }

    private void remove(UUID userId, SseEmitter emitter) {
        byPerson.computeIfPresent(userId, (id, q) -> {
            q.remove(emitter);
            return q.isEmpty() ? null : q;
        });
    }
}
