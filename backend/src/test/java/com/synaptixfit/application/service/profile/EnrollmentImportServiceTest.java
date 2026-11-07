package com.synaptixfit.application.service.profile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.synaptixfit.application.port.input.academic.CreateSubjectUseCase;
import com.synaptixfit.application.port.input.academic.CreateSubjectsFromCatalogUseCase;
import com.synaptixfit.application.port.input.academic.ListSubjectsUseCase;
import com.synaptixfit.application.port.input.catalog.LinkDegreeUseCase;
import com.synaptixfit.application.port.input.catalog.ListDegreesUseCase;
import com.synaptixfit.application.port.input.catalog.ListUniversitiesUseCase;
import com.synaptixfit.application.port.input.catalog.SearchCatalogSubjectsUseCase;
import com.synaptixfit.application.port.input.profile.ApplyEnrollmentUseCase;
import com.synaptixfit.application.port.input.profile.ReadEnrollmentUseCase;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentReading;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentReading.EnrolledSubject;
import com.synaptixfit.domain.port.output.profile.DocumentTextPort;
import com.synaptixfit.domain.port.output.profile.EnrollmentReaderPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Datos inventados: nunca se usan documentos reales en los tests. */
class EnrollmentImportServiceTest {

    private static final byte[] PDF = "%PDF-1.7".getBytes(java.nio.charset.StandardCharsets.US_ASCII);
    private final UUID userId = UUID.randomUUID();
    private DocumentTextPort documents;
    private EnrollmentReaderPort reader;
    private ListSubjectsUseCase mySubjects;
    private LinkDegreeUseCase linkDegree;
    private CreateSubjectsFromCatalogUseCase fromCatalog;
    private CreateSubjectUseCase createSubject;
    private EnrollmentImportService service;

    @BeforeEach
    void setUp() {
        documents = mock(DocumentTextPort.class);
        reader = mock(EnrollmentReaderPort.class);
        UserRepositoryPort users = mock(UserRepositoryPort.class);
        when(users.findById(userId)).thenReturn(Optional.empty());
        ListUniversitiesUseCase universities = mock(ListUniversitiesUseCase.class);
        when(universities.listUniversities(null)).thenReturn(List.of());
        mySubjects = mock(ListSubjectsUseCase.class);
        when(mySubjects.listSubjects(userId, false, null)).thenReturn(List.of());
        linkDegree = mock(LinkDegreeUseCase.class);
        fromCatalog = mock(CreateSubjectsFromCatalogUseCase.class);
        createSubject = mock(CreateSubjectUseCase.class);
        service = new EnrollmentImportService(documents, reader, users, universities, mock(ListDegreesUseCase.class),
                mock(SearchCatalogSubjectsUseCase.class), mySubjects, linkDegree, fromCatalog, createSubject);
    }

    @Test
    void withoutConsentTheDocumentIsNotEvenRead() {
        assertThatThrownBy(() -> service.readEnrollment(
                new ReadEnrollmentUseCase.Command(userId, PDF, "application/pdf", false)))
                .extracting("code").isEqualTo("ENROLLMENT_CONSENT_REQUIRED");
        verify(documents, never()).textOf(any(), anyString());
    }

    @Test
    void onlySmallPdfsAreAccepted() {
        assertThatThrownBy(() -> service.readEnrollment(
                new ReadEnrollmentUseCase.Command(userId, PDF, "image/png", true)))
                .extracting("code").isEqualTo("ENROLLMENT_FILE_INVALID");
        assertThatThrownBy(() -> service.readEnrollment(new ReadEnrollmentUseCase.Command(userId,
                new byte[com.synaptixfit.domain.model.profile.enrollment.EnrollmentDocument.MAX_BYTES + 1], "application/pdf", true)))
                .extracting("code").isEqualTo("ENROLLMENT_FILE_INVALID");
    }

    @Test
    void theAiOnlyReceivesTheTextWithoutPersonalData() {
        when(documents.textOf(PDF, "application/pdf")).thenReturn("N.I.F.: 12345678Z\nRedes de Ordenadores 6");
        when(reader.read(anyString())).thenReturn(new EnrollmentReading(null, null, null, null,
                List.of(new EnrolledSubject(null, "Redes de Ordenadores", 2, 6.0, "2S", 1))));

        var proposal = service.readEnrollment(new ReadEnrollmentUseCase.Command(userId, PDF, "application/pdf", true));

        verify(reader).read(argThat(text -> !text.contains("12345678Z") && text.contains("Redes de Ordenadores")));
        assertThat(proposal.subjects()).hasSize(1);
    }

    @Test
    void aDocumentWithoutSubjectsIsReported() {
        when(documents.textOf(PDF, "application/pdf")).thenReturn("Recibo");
        when(reader.read(anyString())).thenReturn(new EnrollmentReading(null, null, null, null, List.of()));
        assertThatThrownBy(() -> service.readEnrollment(
                new ReadEnrollmentUseCase.Command(userId, PDF, "application/pdf", true)))
                .extracting("code").isEqualTo("ENROLLMENT_NOTHING_FOUND");
    }

    @Test
    void aSelectionLargerThanAnEnrollmentIsRejected() {
        List<UUID> many = java.util.stream.Stream.generate(UUID::randomUUID).limit(41).toList();
        assertThatThrownBy(() -> service.applyEnrollment(
                new ApplyEnrollmentUseCase.Command(userId, null, many, List.of())))
                .extracting("code").isEqualTo("ENROLLMENT_TOO_MANY_SUBJECTS");
    }

    @Test
    void applyingLinksTheDegreeAndCreatesCatalogAndOwnSubjects() {
        UUID degree = UUID.randomUUID();
        UUID catalogSubject = UUID.randomUUID();
        when(fromCatalog.createFromCatalog(userId, List.of(catalogSubject))).thenReturn(List.of(
                mock(com.synaptixfit.domain.model.academic.Subject.class)));

        var result = service.applyEnrollment(new ApplyEnrollmentUseCase.Command(userId, degree,
                List.of(catalogSubject), List.of(new ApplyEnrollmentUseCase.CustomSubject("Optativa", "9", 6))));

        verify(linkDegree).linkDegree(userId, degree);
        verify(createSubject).createSubject(argThat(c -> c.name().equals("Optativa") && c.credits() == 6));
        assertThat(result.subjectsAdded()).isEqualTo(2);
        assertThat(result.degreeLinked()).isTrue();
    }
}
