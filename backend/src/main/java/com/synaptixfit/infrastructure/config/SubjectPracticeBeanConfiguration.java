package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.academic.GetMockExamOptionsUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectQuestionsUseCase;
import com.synaptixfit.application.service.academic.MockExamOptionsService;
import com.synaptixfit.application.service.academic.SubjectQuestionsService;
import com.synaptixfit.domain.port.output.academic.QuestionAttemptRepositoryPort;
import com.synaptixfit.domain.port.output.academic.QuestionBankRepositoryPort;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de la práctica de una asignatura: opciones del simulacro (varios materiales a la vez) y la lista
 * de todas sus preguntas del apartado «Practicar» (ADR 0063).
 */
@Configuration
public class SubjectPracticeBeanConfiguration {

    @Bean
    GetMockExamOptionsUseCase getMockExamOptionsUseCase(TransactionalUseCaseFactory tx,
                                                        SubjectRepositoryPort subjects,
                                                        StudyMaterialRepositoryPort materials,
                                                        QuestionBankRepositoryPort banks) {
        return tx.wrap(GetMockExamOptionsUseCase.class, new MockExamOptionsService(subjects, materials, banks));
    }

    @Bean
    ListSubjectQuestionsUseCase listSubjectQuestionsUseCase(TransactionalUseCaseFactory tx,
                                                            SubjectRepositoryPort subjects,
                                                            StudyMaterialRepositoryPort materials,
                                                            QuestionBankRepositoryPort banks,
                                                            QuestionAttemptRepositoryPort attempts) {
        return tx.wrap(ListSubjectQuestionsUseCase.class,
                new SubjectQuestionsService(subjects, materials, banks, attempts));
    }
}
