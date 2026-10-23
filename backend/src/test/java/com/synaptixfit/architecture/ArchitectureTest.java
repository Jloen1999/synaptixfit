package com.synaptixfit.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/** Regla de dependencia del núcleo: el dominio y la aplicación no conocen frameworks ni infraestructura. */
@AnalyzeClasses(packages = "com.synaptixfit", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

    @ArchTest
    static final ArchRule domainIsPure = noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "org.springframework..", "jakarta.persistence..", "jakarta.validation..",
                    "tools.jackson..", "com.fasterxml..", "software.amazon..",
                    "..application..", "..infrastructure..");

    @ArchTest
    static final ArchRule applicationHasNoFramework = noClasses()
            .that().resideInAPackage("..application..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "org.springframework..", "jakarta.persistence..", "jakarta.validation..",
                    "tools.jackson..", "com.fasterxml..", "software.amazon..", "..infrastructure..");

    /**
     * Reglas de negocio independientes de la base de datos (ADR 0012): ni el dominio ni los casos de
     * uso tocan JDBC, Hibernate ni drivers. Cambiar de motor solo afecta a la infraestructura.
     */
    @ArchTest
    static final ArchRule coreIsDatabaseAgnostic = noClasses()
            .that().resideInAnyPackage("..domain..", "..application..")
            .should().dependOnClassesThat().resideInAnyPackage(
                    "java.sql..", "javax.sql..", "org.hibernate..", "org.postgresql..", "com.mysql..",
                    "org.flywaydb..");

    @ArchTest
    static final ArchRule jpaEntitiesStayInPersistence = noClasses()
            .that().resideOutsideOfPackage("..adapter.output.persistence..")
            .should().dependOnClassesThat().resideInAPackage("..persistence.entity..");

    @ArchTest
    static final ArchRule inputAdaptersDoNotUseOutputAdapters = noClasses()
            .that().resideInAPackage("..adapter.input..")
            .should().dependOnClassesThat().resideInAPackage("..adapter.output..");

    /**
     * Los adaptadores de entrada (controllers REST y oyentes de eventos) solo hablan con los contratos
     * de los casos de uso: ni servicios concretos ni puertos de salida.
     */
    @ArchTest
    static final ArchRule inputAdaptersOnlyTalkToUseCases = noClasses()
            .that().resideInAPackage("..adapter.input..")
            .should().dependOnClassesThat().resideInAnyPackage("..application.service..", "..domain.port.output..");

    @ArchTest
    static final ArchRule useCaseContractsAreInterfaces = classes()
            .that().resideInAPackage("..application.port.input..")
            .and().haveSimpleNameEndingWith("UseCase")
            .should().beInterfaces();
}
