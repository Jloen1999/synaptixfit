package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.analytics.GetStudyBySubjectUseCase;
import com.synaptixfit.application.service.analytics.StudyBySubjectService;
import com.synaptixfit.domain.port.output.analytics.StudyBySubjectSourcePort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de la analítica de estudio por asignatura. */
@Configuration
public class StudyBySubjectBeanConfiguration {

    @Bean
    GetStudyBySubjectUseCase getStudyBySubjectUseCase(TransactionalUseCaseFactory tx,
                                                      StudyBySubjectSourcePort source, Clock clock,
                                                      @Value("${synaptixfit.insights.default-zone:Europe/Madrid}")
                                                      String zone) {
        return tx.wrap(GetStudyBySubjectUseCase.class, new StudyBySubjectService(source, clock, ZoneId.of(zone)));
    }
}
