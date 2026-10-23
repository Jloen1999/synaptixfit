package com.synaptixfit.infrastructure.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.TaskExecutor;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

/**
 * Trabajos en segundo plano con la IA (análisis de planes docentes). Pocos hilos a propósito: el
 * backend tiene 700 MB y cada análisis tiene un PDF en memoria; si la cola se llena, la importación
 * queda pendiente, el dominio la da por fallida y el estudiante puede reintentarla.
 *
 * <p>Ojo: al declarar un {@link TaskExecutor}, Spring Boot deja de crear su ejecutor por defecto,
 * así que un {@code @Async} futuro sin nombre iría también a este pool. Usa siempre
 * {@code @Async(AI_EXECUTOR)} o declara otro ejecutor para otro tipo de trabajo.
 */
@Configuration
@EnableAsync
public class AsyncConfiguration {

    private static final Logger LOG = LoggerFactory.getLogger(AsyncConfiguration.class);

    public static final String AI_EXECUTOR = "aiTaskExecutor";

    @Bean(name = AI_EXECUTOR)
    TaskExecutor aiTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setThreadNamePrefix("ai-");
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(2);
        executor.setQueueCapacity(50);
        executor.setRejectedExecutionHandler((task, pool) ->
                LOG.warn("Cola de IA llena: se descarta un análisis (el estudiante podrá reintentarlo)"));
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(30);
        executor.initialize();
        return executor;
    }
}
