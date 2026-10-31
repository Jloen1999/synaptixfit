package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.CatalogTranslations;
import com.synaptixfit.domain.model.training.ExerciseNameTranslations;
import com.synaptixfit.domain.port.output.training.CatalogTranslationsPort;
import com.synaptixfit.domain.port.output.training.ExerciseNameTranslationsRepositoryPort;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * Implementa {@link CatalogTranslationsPort} y {@link ExerciseNameTranslationsRepositoryPort} sobre
 * {@code ejercicio_nombres} y {@code vocabulario_nombres} (V930). Las traducciones de cada idioma se
 * guardan en memoria (se piden en cada respuesta y casi nunca cambian) y se descartan cuando la
 * administración guarda nombres, una vez confirmada la transacción.
 */
@Component
public class CatalogTranslationsJdbcAdapter implements CatalogTranslationsPort, ExerciseNameTranslationsRepositoryPort {

    private final JdbcClient jdbc;
    private final Map<String, CatalogTranslations> cache = new ConcurrentHashMap<>();
    /** Sube al descartar la memoria: una lectura empezada antes no se guarda (estaría desfasada). */
    private long generation;

    public CatalogTranslationsJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public CatalogTranslations load(String language) {
        CatalogTranslations cached = cache.get(language);
        if (cached != null) {
            return cached;
        }
        long before;
        synchronized (this) {
            before = generation;
        }
        CatalogTranslations fresh = read(language);
        synchronized (this) {
            if (generation == before) {
                cache.put(language, fresh);
            }
        }
        return fresh;
    }

    @Override
    public ExerciseNameTranslations findByExercise(UUID exerciseId) {
        Map<String, String> names = new HashMap<>();
        jdbc.sql("SELECT idioma, nombre FROM ejercicio_nombres WHERE ejercicio_id = :id")
                .param("id", exerciseId)
                .query((ResultSet rs) -> {
                    names.put(rs.getString("idioma"), rs.getString("nombre"));
                });
        return ExerciseNameTranslations.of(names);
    }

    @Override
    public void replace(UUID exerciseId, ExerciseNameTranslations names) {
        jdbc.sql("DELETE FROM ejercicio_nombres WHERE ejercicio_id = :id").param("id", exerciseId).update();
        names.byLanguage().forEach((language, name) -> jdbc.sql(
                        "INSERT INTO ejercicio_nombres (ejercicio_id, idioma, nombre) VALUES (:id, :lang, :name)")
                .param("id", exerciseId)
                .param("lang", language)
                .param("name", name)
                .update());
        forgetAfterCommit();
    }

    private void forgetAfterCommit() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    forget();
                }
            });
        } else {
            forget();
        }
    }

    private synchronized void forget() {
        generation++;
        cache.clear();
    }

    private CatalogTranslations read(String language) {
        Map<UUID, String> exercises = new HashMap<>();
        jdbc.sql("SELECT ejercicio_id, nombre FROM ejercicio_nombres WHERE idioma = :lang")
                .param("lang", language)
                .query((ResultSet rs) -> {
                    exercises.put(rs.getObject("ejercicio_id", UUID.class), rs.getString("nombre"));
                });
        Map<String, String> terms = new HashMap<>();
        jdbc.sql("SELECT termino, nombre FROM vocabulario_nombres WHERE idioma = :lang")
                .param("lang", language)
                .query((ResultSet rs) -> {
                    terms.put(rs.getString("termino"), rs.getString("nombre"));
                });
        return new CatalogTranslations(exercises, terms);
    }
}
