package com.synaptixfit.infrastructure.adapter.output.external.ics;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.sun.net.httpserver.HttpServer;
import com.synaptixfit.domain.exception.planner.IcsFeedUnavailableException;
import com.synaptixfit.domain.exception.planner.InvalidIcsUrlException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/** Protección SSRF y límites de la descarga de calendarios ICS. */
class IcsFeedHttpAdapterTest {

    private HttpServer server;
    private final List<String> requested = new CopyOnWriteArrayList<>();

    @BeforeEach
    void start() throws Exception {
        server = HttpServer.create(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0), 0);
        server.createContext("/", exchange -> {
            String path = exchange.getRequestURI().getPath();
            requested.add(path);
            switch (path) {
                case "/ok/redirect-inside" -> {
                    exchange.getResponseHeaders().add("Location", "/ok/calendar.ics");
                    exchange.sendResponseHeaders(302, -1);
                }
                case "/ok/redirect-internal" -> {
                    exchange.getResponseHeaders().add("Location", "/internal/secret");
                    exchange.sendResponseHeaders(302, -1);
                }
                case "/ok/slow" -> {
                    exchange.sendResponseHeaders(200, 0);
                    exchange.getResponseBody().write("BEGIN:VCALENDAR\n".getBytes(StandardCharsets.UTF_8));
                    exchange.getResponseBody().flush();
                    try {
                        Thread.sleep(3_000);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                }
                default -> {
                    byte[] body = "BEGIN:VCALENDAR\nEND:VCALENDAR\n".getBytes(StandardCharsets.UTF_8);
                    exchange.sendResponseHeaders(200, body.length);
                    exchange.getResponseBody().write(body);
                }
            }
            exchange.close();
        });
        server.start();
    }

    @AfterEach
    void stop() {
        server.stop(0);
    }

    /** Política de prueba: solo se permiten las rutas /ok (el servidor real está en la red local). */
    private IcsFeedHttpAdapter adapter(Duration timeout) {
        return new IcsFeedHttpAdapter(uri -> {
            if (!uri.getPath().startsWith("/ok")) {
                throw new InvalidIcsUrlException();
            }
        }, timeout);
    }

    private URI url(String path) {
        return URI.create("http://127.0.0.1:" + server.getAddress().getPort() + path);
    }

    @Test
    void aRedirectIsFollowedWhenTheNewTargetIsAllowed() {
        String ics = adapter(Duration.ofSeconds(5)).download(url("/ok/redirect-inside"));

        assertThat(ics).startsWith("BEGIN:VCALENDAR");
        assertThat(requested).containsExactly("/ok/redirect-inside", "/ok/calendar.ics");
    }

    @Test
    void aRedirectToAForbiddenTargetIsRejectedBeforeRequestingIt() {
        assertThatThrownBy(() -> adapter(Duration.ofSeconds(5)).download(url("/ok/redirect-internal")))
                .isInstanceOf(InvalidIcsUrlException.class);
        assertThat(requested).containsExactly("/ok/redirect-internal");
    }

    @Test
    void aBodyThatNeverEndsIsCutAtTheTotalDeadline() {
        long start = System.nanoTime();

        assertThatThrownBy(() -> adapter(Duration.ofMillis(800)).download(url("/ok/slow")))
                .isInstanceOf(IcsFeedUnavailableException.class);
        assertThat(Duration.ofNanos(System.nanoTime() - start)).isLessThan(Duration.ofMillis(2_500));
    }

    @Test
    void theRealPolicyRejectsLoopbackAndOtherPorts() {
        assertThatThrownBy(() -> IcsFeedHttpAdapter.requireAllowedTarget(URI.create("http://127.0.0.1/cal.ics")))
                .isInstanceOf(InvalidIcsUrlException.class);
        assertThatThrownBy(() -> IcsFeedHttpAdapter.requireAllowedTarget(URI.create("http://localhost/cal.ics")))
                .isInstanceOf(InvalidIcsUrlException.class);
        assertThatThrownBy(() -> IcsFeedHttpAdapter.requireAllowedTarget(URI.create("https://8.8.8.8:5432/x")))
                .isInstanceOf(InvalidIcsUrlException.class);
        assertThatThrownBy(() -> IcsFeedHttpAdapter.requireAllowedTarget(URI.create("ftp://8.8.8.8/x")))
                .isInstanceOf(InvalidIcsUrlException.class);
    }

    @ParameterizedTest
    @ValueSource(strings = {"127.0.0.1", "10.1.2.3", "172.16.0.1", "192.168.1.1", "169.254.169.254", "0.1.2.3",
            "100.64.0.1", "100.127.255.255", "192.0.0.8", "198.18.0.1", "198.19.255.1", "240.0.0.1",
            "255.255.255.255", "224.0.0.1", "::1", "::", "fe80::1", "fc00::1", "fd12:3456::1", "64:ff9b::a00:1",
            "2002:a00:1::", "::ffff:10.0.0.1", "::10.0.0.1"})
    void internalAddressesAreNotPublic(String ip) throws Exception {
        assertThat(IcsFeedHttpAdapter.isPublic(InetAddress.getByName(ip))).isFalse();
    }

    @ParameterizedTest
    @ValueSource(strings = {"8.8.8.8", "1.1.1.1", "100.128.0.1", "198.20.0.1", "2001:4860:4860::8888"})
    void publicAddressesAreAllowed(String ip) throws Exception {
        assertThat(IcsFeedHttpAdapter.isPublic(InetAddress.getByName(ip))).isTrue();
    }
}
