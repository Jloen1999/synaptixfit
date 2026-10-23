package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.catalog.GetCatalogSubjectUseCase;
import com.synaptixfit.application.port.input.catalog.GetDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.GetUniversityUseCase;
import com.synaptixfit.application.port.input.catalog.LinkDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.ListCentersUseCase;
import com.synaptixfit.application.port.input.catalog.ListDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.ListMyCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.catalog.ListMyDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.ListUniversitiesUseCase;
import com.synaptixfit.application.port.input.catalog.SearchCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.catalog.UnlinkDegreeUseCase;
import com.synaptixfit.application.service.catalog.CatalogService;
import com.synaptixfit.application.service.catalog.UserDegreeService;
import com.synaptixfit.domain.port.output.catalog.AcademicCatalogPort;
import com.synaptixfit.domain.port.output.catalog.UserDegreeRepositoryPort;
import com.synaptixfit.domain.port.output.catalog.UserSubjectLinksPort;
import com.synaptixfit.domain.port.output.profile.AcademicProfileRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Raíz de composición del catálogo académico y de las carreras del usuario (patrón de {@link BeanConfiguration}). */
@Configuration
public class CatalogBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final AcademicCatalogPort catalog;
    private final UserDegreeRepositoryPort userDegrees;
    private final AcademicProfileRepositoryPort academicProfiles;
    private final UserSubjectLinksPort subjectLinks;
    private final Clock clock;

    public CatalogBeanConfiguration(TransactionalUseCaseFactory tx, AcademicCatalogPort catalog,
                                    UserDegreeRepositoryPort userDegrees,
                                    AcademicProfileRepositoryPort academicProfiles,
                                    UserSubjectLinksPort subjectLinks, Clock clock) {
        this.tx = tx;
        this.catalog = catalog;
        this.userDegrees = userDegrees;
        this.academicProfiles = academicProfiles;
        this.subjectLinks = subjectLinks;
        this.clock = clock;
    }

    // ---------------------------------------------------------------- catálogo

    @Bean(autowireCandidate = false)
    CatalogService catalogService() {
        return new CatalogService(catalog);
    }

    @Bean
    ListUniversitiesUseCase listUniversitiesUseCase() {
        return tx.wrap(ListUniversitiesUseCase.class, catalogService());
    }

    @Bean
    GetUniversityUseCase getUniversityUseCase() {
        return tx.wrap(GetUniversityUseCase.class, catalogService());
    }

    @Bean
    ListCentersUseCase listCentersUseCase() {
        return tx.wrap(ListCentersUseCase.class, catalogService());
    }

    @Bean
    ListDegreesUseCase listDegreesUseCase() {
        return tx.wrap(ListDegreesUseCase.class, catalogService());
    }

    @Bean
    GetDegreeUseCase getDegreeUseCase() {
        return tx.wrap(GetDegreeUseCase.class, catalogService());
    }

    @Bean
    SearchCatalogSubjectsUseCase searchCatalogSubjectsUseCase() {
        return tx.wrap(SearchCatalogSubjectsUseCase.class, catalogService());
    }

    @Bean
    GetCatalogSubjectUseCase getCatalogSubjectUseCase() {
        return tx.wrap(GetCatalogSubjectUseCase.class, catalogService());
    }

    // ---------------------------------------------------------------- carreras del usuario

    @Bean(autowireCandidate = false)
    UserDegreeService userDegreeService() {
        return new UserDegreeService(userDegrees, catalog, academicProfiles, subjectLinks, clock);
    }

    @Bean
    ListMyDegreesUseCase listMyDegreesUseCase() {
        return tx.wrap(ListMyDegreesUseCase.class, userDegreeService());
    }

    @Bean
    LinkDegreeUseCase linkDegreeUseCase() {
        return tx.wrap(LinkDegreeUseCase.class, userDegreeService());
    }

    @Bean
    UnlinkDegreeUseCase unlinkDegreeUseCase() {
        return tx.wrap(UnlinkDegreeUseCase.class, userDegreeService());
    }

    @Bean
    ListMyCatalogSubjectsUseCase listMyCatalogSubjectsUseCase() {
        return tx.wrap(ListMyCatalogSubjectsUseCase.class, userDegreeService());
    }
}
