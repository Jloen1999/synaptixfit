package com.synaptixfit.infrastructure.adapter.output.external.ics;

import com.synaptixfit.domain.exception.planner.IcsFeedUnavailableException;
import com.synaptixfit.domain.exception.planner.InvalidIcsUrlException;
import com.synaptixfit.domain.port.output.planner.IcsFeedPort;
import java.io.ByteArrayOutputStream;
import java.net.InetAddress;
import java.net.URI;
import java.net.UnknownHostException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Flow;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.Consumer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Descarga calendarios ICS por HTTP(S). Sustituye al proxy del Worker de Cloudflare que usaba la app
 * web antigua para esquivar CORS: ahora la descarga la hace el servidor.
 *
 * <p>Protección SSRF: cada salto (también las redirecciones, que se siguen a mano) debe ser http(s) a los
 * puertos 80/443 y resolver solo a direcciones públicas. Tope de 5 MB y de 30 s para toda la descarga, cuerpo
 * incluido, porque se hace dentro de la transacción del caso de uso. Riesgo residual: el cliente HTTP vuelve a
 * resolver el nombre al conectar (DNS rebinding); lo cubre el filtrado de salida del contenedor (ADR 0020).
 */
@Component
public class IcsFeedHttpAdapter implements IcsFeedPort {

    private static final Logger LOG = LoggerFactory.getLogger(IcsFeedHttpAdapter.class);
    static final int MAX_BYTES = 5 * 1024 * 1024;
    static final int MAX_REDIRECTS = 3;

    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .followRedirects(HttpClient.Redirect.NEVER)
            .build();
    private final Consumer<URI> guard;
    private final Duration totalTimeout;

    public IcsFeedHttpAdapter() {
        this(IcsFeedHttpAdapter::requireAllowedTarget, Duration.ofSeconds(30));
    }

    /** Para los tests: otra política de destinos y otro plazo. */
    IcsFeedHttpAdapter(Consumer<URI> guard, Duration totalTimeout) {
        this.guard = guard;
        this.totalTimeout = totalTimeout;
    }

    @Override
    public String download(URI url) {
        long deadline = System.nanoTime() + totalTimeout.toNanos();
        URI target = url;
        for (int hop = 0; hop <= MAX_REDIRECTS; hop++) {
            guard.accept(target);
            HttpResponse<byte[]> response = fetch(target, deadline);
            int status = response.statusCode();
            if (status >= 300 && status < 400) {
                target = nextHop(target, response);
                continue;
            }
            byte[] bytes = response.body();
            if (status >= 400 || bytes == null || bytes.length == 0) {
                throw new IcsFeedUnavailableException();
            }
            return new String(bytes, StandardCharsets.UTF_8);
        }
        throw new IcsFeedUnavailableException();
    }

    private HttpResponse<byte[]> fetch(URI target, long deadline) {
        long remaining = deadline - System.nanoTime();
        if (remaining <= 0) {
            throw new IcsFeedUnavailableException();
        }
        HttpRequest request = HttpRequest.newBuilder(target)
                .timeout(Duration.ofNanos(remaining))
                .header("User-Agent", "SynaptixFit/1.0 (Calendar Sync)")
                .header("Accept", "text/calendar, */*")
                .GET()
                .build();
        // Solo se lee el cuerpo de una respuesta 2xx; el de redirecciones y errores se descarta.
        CompletableFuture<HttpResponse<byte[]>> future = client.sendAsync(request, info ->
                info.statusCode() >= 200 && info.statusCode() < 300
                        ? new LimitedBody(MAX_BYTES)
                        : HttpResponse.BodySubscribers.<byte[]>replacing(null));
        try {
            return future.get(remaining, TimeUnit.NANOSECONDS);
        } catch (TimeoutException e) {
            future.cancel(true);
            LOG.warn("ICS download timed out for host {}", target.getHost());
            throw new IcsFeedUnavailableException();
        } catch (ExecutionException e) {
            LOG.warn("ICS download failed for host {}: {}", target.getHost(), e.getCause().getMessage());
            throw new IcsFeedUnavailableException();
        } catch (InterruptedException e) {
            future.cancel(true);
            Thread.currentThread().interrupt();
            throw new IcsFeedUnavailableException();
        }
    }

    private static URI nextHop(URI from, HttpResponse<?> response) {
        String location = response.headers().firstValue("Location").orElseThrow(IcsFeedUnavailableException::new);
        try {
            return from.resolve(location);
        } catch (IllegalArgumentException e) {
            throw new IcsFeedUnavailableException();
        }
    }

    /** http(s), puerto 80/443 (para no servir de escáner de puertos) y un host que solo resuelve a IP públicas. */
    static void requireAllowedTarget(URI url) {
        String scheme = url.getScheme() == null ? "" : url.getScheme().toLowerCase(Locale.ROOT);
        int port = url.getPort();
        if (!(scheme.equals("http") || scheme.equals("https")) || url.getHost() == null
                || !(port == -1 || port == 80 || port == 443)) {
            throw new InvalidIcsUrlException();
        }
        try {
            for (InetAddress address : InetAddress.getAllByName(url.getHost())) {
                if (!isPublic(address)) {
                    throw new InvalidIcsUrlException();
                }
            }
        } catch (UnknownHostException e) {
            throw new IcsFeedUnavailableException();
        }
    }

    /**
     * Fuera: bucle local, redes privadas y de enlace, multidifusión y los rangos especiales que también llevan a
     * redes internas (0/8, CGNAT 100.64/10, 192.0.0/24, 198.18/15, 240/4 y difusión; en IPv6, fc00::/7, NAT64,
     * 6to4 y las compatibles con IPv4). Las IPv4 mapeadas en IPv6 ya llegan como Inet4Address.
     */
    static boolean isPublic(InetAddress address) {
        if (address.isLoopbackAddress() || address.isSiteLocalAddress() || address.isLinkLocalAddress()
                || address.isAnyLocalAddress() || address.isMulticastAddress()) {
            return false;
        }
        byte[] b = address.getAddress();
        int b0 = b[0] & 0xff;
        int b1 = b[1] & 0xff;
        if (b.length == 4) {
            int b2 = b[2] & 0xff;
            return !(b0 == 0 || b0 >= 240
                    || (b0 == 100 && (b1 & 0xc0) == 64)
                    || (b0 == 192 && b1 == 0 && b2 == 0)
                    || (b0 == 198 && (b1 & 0xfe) == 18));
        }
        if ((b0 & 0xfe) == 0xfc || (b0 == 0x20 && b1 == 0x02)) {
            return false;
        }
        if (b0 == 0x00 && b1 == 0x64 && (b[2] & 0xff) == 0xff && (b[3] & 0xff) == 0x9b) {
            return false;
        }
        for (int i = 0; i < 12; i++) {
            if (b[i] != 0) {
                return true;
            }
        }
        return false;
    }

    /** Acumula el cuerpo y corta la descarga en cuanto supera el tope. */
    private static final class LimitedBody implements HttpResponse.BodySubscriber<byte[]> {

        private final int max;
        private final ByteArrayOutputStream out = new ByteArrayOutputStream();
        private final CompletableFuture<byte[]> result = new CompletableFuture<>();
        private Flow.Subscription subscription;

        LimitedBody(int max) {
            this.max = max;
        }

        @Override
        public CompletionStage<byte[]> getBody() {
            return result;
        }

        @Override
        public void onSubscribe(Flow.Subscription subscription) {
            this.subscription = subscription;
            subscription.request(1);
        }

        @Override
        public void onNext(List<ByteBuffer> items) {
            for (ByteBuffer buffer : items) {
                byte[] chunk = new byte[buffer.remaining()];
                buffer.get(chunk);
                out.write(chunk, 0, chunk.length);
            }
            if (out.size() > max) {
                subscription.cancel();
                result.completeExceptionally(new IllegalStateException("ICS larger than " + max + " bytes"));
                return;
            }
            subscription.request(1);
        }

        @Override
        public void onError(Throwable throwable) {
            result.completeExceptionally(throwable);
        }

        @Override
        public void onComplete() {
            result.complete(out.toByteArray());
        }
    }
}
