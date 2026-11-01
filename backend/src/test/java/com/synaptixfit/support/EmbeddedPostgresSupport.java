package com.synaptixfit.support;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import java.io.IOException;
import java.io.UncheckedIOException;
import org.springframework.test.context.DynamicPropertyRegistry;

/**
 * PostgreSQL embebido (binarios reales, sin Docker) compartido por los tests de integración.
 * Se arranca una vez por JVM.
 */
public final class EmbeddedPostgresSupport {

    private static EmbeddedPostgres postgres;

    private EmbeddedPostgresSupport() {
    }

    public static synchronized void register(DynamicPropertyRegistry registry) {
        if (postgres == null) {
            try {
                postgres = EmbeddedPostgres.builder().start();
            } catch (IOException e) {
                throw new UncheckedIOException(e);
            }
        }
        registry.add("spring.datasource.url", () -> postgres.getJdbcUrl("postgres", "postgres"));
        registry.add("spring.datasource.username", () -> "postgres");
        registry.add("spring.datasource.password", () -> "postgres");
        // Los tests nunca llaman a la IA real aunque exista backend/.env con una clave.
        registry.add("synaptixfit.ai.api-key", () -> "");
        // Ni envían correos reales.
        registry.add("synaptixfit.mail.resend-api-key", () -> "");
        registry.add("synaptixfit.mail.weekly-cron", () -> "-");
        registry.add("synaptixfit.planner.auto-attend-cron", () -> "-");
    }
}
