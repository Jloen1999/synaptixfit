package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.academic.ApplyTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.DiscardTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.GetTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.ProcessTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.RequestTeachingGuideUploadUseCase;
import com.synaptixfit.application.port.input.academic.RetryTeachingGuideImportUseCase;
import com.synaptixfit.application.port.input.academic.StartTeachingGuideImportUseCase;
import com.synaptixfit.application.service.academic.TeachingGuideImportService;
import com.synaptixfit.domain.port.output.academic.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.academic.TeachingGuideImportRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de la importación de planes docentes (subida, análisis en segundo plano y aplicación). */
@Configuration
public class TeachingGuideImportBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final TeachingGuideImportService service;

    public TeachingGuideImportBeanConfiguration(TransactionalUseCaseFactory tx,
                                                TeachingGuideImportRepositoryPort imports,
                                                SubjectRepositoryPort subjects, SubjectFileRepositoryPort files,
                                                AiDocumentRepositoryPort aiDocuments, StudyDocumentCodecPort codec,
                                                StudyAssistantPort assistant, FileStoragePort storage,
                                                DomainEventPublisherPort events, AcademicCatalogPort catalog,
                                                Clock clock,
                                                @Value("${synaptixfit.insights.default-zone:Europe/Madrid}")
                                                String zone) {
        this.tx = tx;
        this.service = new TeachingGuideImportService(imports, subjects, files, aiDocuments, codec, assistant,
                storage, events, catalog, clock, ZoneId.of(zone));
    }

    @Bean
    RequestTeachingGuideUploadUseCase requestTeachingGuideUploadUseCase() {
        return tx.wrap(RequestTeachingGuideUploadUseCase.class, service);
    }

    @Bean
    StartTeachingGuideImportUseCase startTeachingGuideImportUseCase() {
        return tx.wrap(StartTeachingGuideImportUseCase.class, service);
    }

    /**
     * Sin transacción envolvente a propósito: la llamada a la IA puede durar más de un minuto y no
     * debe retener una conexión de la base de datos; cada guardado es su propia transacción. Se
     * expone con una referencia a método para que el bean solo implemente este contrato.
     */
    @Bean
    ProcessTeachingGuideImportUseCase processTeachingGuideImportUseCase() {
        return service::process;
    }

    @Bean
    GetTeachingGuideImportUseCase getTeachingGuideImportUseCase() {
        return tx.wrap(GetTeachingGuideImportUseCase.class, service);
    }

    @Bean
    RetryTeachingGuideImportUseCase retryTeachingGuideImportUseCase() {
        return tx.wrap(RetryTeachingGuideImportUseCase.class, service);
    }

    @Bean
    ApplyTeachingGuideImportUseCase applyTeachingGuideImportUseCase() {
        return tx.wrap(ApplyTeachingGuideImportUseCase.class, service);
    }

    @Bean
    DiscardTeachingGuideImportUseCase discardTeachingGuideImportUseCase() {
        return tx.wrap(DiscardTeachingGuideImportUseCase.class, service);
    }
}
