package com.synaptixfit.infrastructure.adapter.output.external.ics;

import com.synaptixfit.domain.exception.planner.IcsFeedUnavailableException;
import com.synaptixfit.domain.exception.planner.InvalidIcsUrlException;
import com.synaptixfit.domain.port.output.planner.IcsFeedPort;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.URI;
import java.net.UnknownHostException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Descarga calendarios ICS por HTTP(S). Sustituye al proxy del Worker de Cloudflare que usaba la app
 * web antigua para esquivar CORS: ahora la descarga la hace el servidor.
 *
 * <p>Protección SSRF básica: rechaza direcciones locales/privadas y limita el tamaño a 5 MB.
 */
@Component
public class IcsFeedHttpAdapter implements IcsFeedPort {

    private static final Logger LOG = LoggerFactory.getLogger(IcsFeedHttpAdapter.class);
    static final int MAX_BYTES = 5 * 1024 * 1024;

    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    @Override
    public String download(URI url) {
        requirePublicHost(url);
        HttpRequest request = HttpRequest.newBuilder(url)
                .timeout(Duration.ofSeconds(30))
                .header("User-Agent", "SynaptixFit/1.0 (Calendar Sync)")
                .header("Accept", "text/calendar, */*")
                .GET()
                .build();
        try {
            HttpResponse<InputStream> response = client.send(request, HttpResponse.BodyHandlers.ofInputStream());
            try (InputStream body = response.body()) {
                if (response.statusCode() >= 400) {
                    throw new IcsFeedUnavailableException();
                }
                byte[] bytes = body.readNBytes(MAX_BYTES + 1);
                if (bytes.length == 0 || bytes.length > MAX_BYTES) {
                    throw new IcsFeedUnavailableException();
                }
                return new String(bytes, StandardCharsets.UTF_8);
            }
        } catch (IOException e) {
            LOG.warn("ICS download failed for host {}: {}", url.getHost(), e.getMessage());
            throw new IcsFeedUnavailableException();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IcsFeedUnavailableException();
        }
    }

    private static void requirePublicHost(URI url) {
        try {
            for (InetAddress address : InetAddress.getAllByName(url.getHost())) {
                if (address.isLoopbackAddress() || address.isSiteLocalAddress() || address.isLinkLocalAddress()
                        || address.isAnyLocalAddress() || address.isMulticastAddress()) {
                    throw new InvalidIcsUrlException();
                }
            }
        } catch (UnknownHostException e) {
            throw new IcsFeedUnavailableException();
        }
    }
}
