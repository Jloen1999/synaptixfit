package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/** Analiza con la IA una importación pendiente y guarda el resultado o el error. Idempotente. */
public interface ProcessTeachingGuideImportUseCase {

    void process(UUID importId);
}
