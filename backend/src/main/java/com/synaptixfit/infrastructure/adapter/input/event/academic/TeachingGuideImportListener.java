package com.synaptixfit.infrastructure.adapter.input.event.academic;

import com.synaptixfit.application.port.input.academic.ProcessTeachingGuideImportUseCase;
import com.synaptixfit.domain.event.academic.TeachingGuideImportRequested;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Analiza el plan docente en segundo plano. A diferencia del resto de oyentes, espera a que se
 * confirme la transacción (la importación ya está guardada) y no bloquea la petición del móvil.
 */
@Component
public class TeachingGuideImportListener {

    private final ProcessTeachingGuideImportUseCase process;

    public TeachingGuideImportListener(ProcessTeachingGuideImportUseCase process) {
        this.process = process;
    }

    @Async("aiTaskExecutor")
    @TransactionalEventListener(fallbackExecution = true)
    public void on(TeachingGuideImportRequested event) {
        process.process(event.importId());
    }
}
