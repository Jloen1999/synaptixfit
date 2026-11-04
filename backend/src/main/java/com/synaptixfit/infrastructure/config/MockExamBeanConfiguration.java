package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.academic.GetMockExamOptionsUseCase;
import com.synaptixfit.application.service.academic.MockExamOptionsService;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de las opciones del simulacro de asignatura (varios materiales a la vez). */
@Configuration
public class MockExamBeanConfiguration {

    @Bean
    GetMockExamOptionsUseCase getMockExamOptionsUseCase(TransactionalUseCaseFactory tx,
                                                        SubjectRepositoryPort subjects,
                                                        StudyMaterialRepositoryPort materials,
                                                        QuestionBankRepositoryPort banks) {
        return tx.wrap(GetMockExamOptionsUseCase.class, new MockExamOptionsService(subjects, materials, banks));
    }
}
