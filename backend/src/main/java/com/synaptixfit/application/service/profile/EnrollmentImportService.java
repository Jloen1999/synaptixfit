package com.synaptixfit.application.service.profile;

import com.synaptixfit.application.port.input.academic.CreateSubjectUseCase;
import com.synaptixfit.application.port.input.academic.CreateSubjectsFromCatalogUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectsUseCase;
import com.synaptixfit.application.port.input.catalog.LinkDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.ListDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.ListUniversitiesUseCase;
import com.synaptixfit.application.port.input.catalog.SearchCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.profile.ApplyEnrollmentUseCase;
import com.synaptixfit.application.port.input.profile.ReadEnrollmentUseCase;
import com.synaptixfit.domain.exception.profile.EnrollmentConsentRequiredException;
import com.synaptixfit.domain.exception.profile.EnrollmentNothingFoundException;
import com.synaptixfit.domain.exception.profile.EnrollmentTooManySubjectsException;
import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.CatalogSubjectFilter;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentDocument;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentProposal;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentReading;
import com.synaptixfit.domain.model.profile.enrollment.PersonalDataRedactor;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.profile.DocumentTextPort;
import com.synaptixfit.domain.port.output.profile.EnrollmentReaderPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Implementa {@link ReadEnrollmentUseCase} y {@link ApplyEnrollmentUseCase}. Leer: comprueba el
 * permiso y el archivo, saca el texto ({@link DocumentTextPort}), quita los datos personales
 * ({@link PersonalDataRedactor}) antes de dárselo a la IA ({@link EnrollmentReaderPort}) y lo cruza con
 * el catálogo. El documento no se guarda en ningún sitio. Aplicar: vincula la carrera y crea las
 * asignaturas con los casos de uso de catálogo y académico.
 */
public class EnrollmentImportService implements ReadEnrollmentUseCase, ApplyEnrollmentUseCase {

    /** Una matrícula anual rara vez pasa de 15 asignaturas; el tope evita abusos. */
    static final int MAX_SUBJECTS = 40;

    private final DocumentTextPort documents;
    private final EnrollmentReaderPort reader;
    private final UserRepositoryPort users;
    private final ListUniversitiesUseCase universities;
    private final ListDegreesUseCase degrees;
    private final SearchCatalogSubjectsUseCase catalogSubjects;
    private final ListSubjectsUseCase mySubjects;
    private final LinkDegreeUseCase linkDegree;
    private final CreateSubjectsFromCatalogUseCase fromCatalog;
    private final CreateSubjectUseCase createSubject;

    public EnrollmentImportService(DocumentTextPort documents, EnrollmentReaderPort reader, UserRepositoryPort users,
                                   ListUniversitiesUseCase universities, ListDegreesUseCase degrees,
                                   SearchCatalogSubjectsUseCase catalogSubjects, ListSubjectsUseCase mySubjects,
                                   LinkDegreeUseCase linkDegree, CreateSubjectsFromCatalogUseCase fromCatalog,
                                   CreateSubjectUseCase createSubject) {
        this.documents = documents;
        this.reader = reader;
        this.users = users;
        this.universities = universities;
        this.degrees = degrees;
        this.catalogSubjects = catalogSubjects;
        this.mySubjects = mySubjects;
        this.linkDegree = linkDegree;
        this.fromCatalog = fromCatalog;
        this.createSubject = createSubject;
    }

    @Override
    public EnrollmentProposal readEnrollment(ReadEnrollmentUseCase.Command command) {
        UUID userId = Guard.notNull(command.userId(), "userId");
        if (!command.consent()) {
            throw new EnrollmentConsentRequiredException();
        }
        EnrollmentDocument document = EnrollmentDocument.of(command.content(), command.mimeType());
        String fullName = users.findById(userId).map(u -> u.fullName()).orElse(null);
        String redacted = PersonalDataRedactor.redact(documents.textOf(document.content(), EnrollmentDocument.MIME),
                fullName == null ? List.of() : List.of(fullName));
        EnrollmentReading reading = reader.read(redacted);
        if (reading.subjects().isEmpty()) {
            throw new EnrollmentNothingFoundException();
        }
        List<String> existing = mySubjects.listSubjects(userId, false, null).stream()
                .map(s -> s.subject().name())
                .toList();
        return EnrollmentProposal.match(reading, universities.listUniversities(null),
                universityId -> degrees.listDegreesByUniversity(universityId, null),
                this::allSubjectsOf, existing);
    }

    @Override
    public ApplyEnrollmentUseCase.Result applyEnrollment(ApplyEnrollmentUseCase.Command command) {
        UUID userId = Guard.notNull(command.userId(), "userId");
        if (command.catalogSubjectIds().size() + command.customSubjects().size() > MAX_SUBJECTS) {
            throw new EnrollmentTooManySubjectsException();
        }
        boolean linked = false;
        if (command.degreeId() != null) {
            linkDegree.linkDegree(userId, command.degreeId());
            linked = true;
        }
        int added = 0;
        if (!command.catalogSubjectIds().isEmpty()) {
            added += fromCatalog.createFromCatalog(userId, command.catalogSubjectIds()).size();
        }
        for (ApplyEnrollmentUseCase.CustomSubject custom : command.customSubjects()) {
            createSubject.createSubject(new CreateSubjectUseCase.Command(userId, custom.name(), custom.code(), null,
                    custom.credits(), null, null, null, null, null));
            added++;
        }
        return new ApplyEnrollmentUseCase.Result(added, linked);
    }

    /** Todo el plan de estudios de una carrera (paginado de 100 en 100). */
    private List<CatalogSubject> allSubjectsOf(UUID degreeId) {
        List<CatalogSubject> all = new ArrayList<>();
        CatalogSubjectFilter any = new CatalogSubjectFilter(null, null, null, null);
        for (int page = 0; ; page++) {
            PageResult<CatalogSubject> result = catalogSubjects.searchSubjects(degreeId, any,
                    new PageRequest(page, PageRequest.MAX_SIZE));
            all.addAll(result.items());
            if (result.items().size() < PageRequest.MAX_SIZE || all.size() >= result.totalItems()) {
                return all;
            }
        }
    }
}
