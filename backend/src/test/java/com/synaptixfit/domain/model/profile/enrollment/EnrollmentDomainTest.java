package com.synaptixfit.domain.model.profile.enrollment;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.University;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentReading.EnrolledSubject;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Datos inventados: nunca se usan documentos reales en los tests. */
class EnrollmentDomainTest {

    @Test
    void personalDataNeverLeavesTheServer() {
        String text = String.join("\n",
                "UNIVERSIDAD DE EJEMPLO",
                "Alumno/a: ANA PRUEBA EJEMPLO",
                "N.I.F.: 12345678Z",
                "Calle Falsa 123",
                "28080 MADRID",
                "ANA PRUEBA EJEMPLO",
                "X1234567L",
                "Cuenta ES12 3456 7890 12 3456789012",
                "Referencia 2024000000123",
                "Contacto ana@example.com 600 123 456",
                "501448 HABILIDADES COMUNICATIVAS 6 2S");

        String redacted = PersonalDataRedactor.redact(text, List.of("Ana Prueba Ejemplo"));

        assertThat(redacted)
                .doesNotContain("12345678Z", "X1234567L", "ES12", "Calle", "28080", "ANA", "PRUEBA",
                        "ana@example.com", "600 123 456", "2024000000123")
                .contains("UNIVERSIDAD DE EJEMPLO", "501448 HABILIDADES COMUNICATIVAS 6 2S");
    }

    @Test
    void namesMatchWhateverTheirCaseOrAccents() {
        assertThat(CatalogNames.matches("METODOLOGIA Y DESARROLLO DE APLICACIONES PARA INTERNET",
                "Metodología y desarrollo de aplicaciones para Internet")).isTrue();
        assertThat(CatalogNames.matches("Redes", "Sistemas inteligentes")).isFalse();
    }

    @Test
    void theProposalUsesTheCatalogAndMarksWhatTheUserAlreadyHas() {
        UUID uniId = UUID.randomUUID();
        University uni = new University(uniId, "Universidad de Ejemplo");
        Degree merida = new Degree(UUID.randomUUID(), "Grado en Informática", 240, null, UUID.randomUUID(),
                "Centro de Mérida", uniId, uni.name());
        Degree caceres = new Degree(UUID.randomUUID(), "Grado en Informática", 240, null, UUID.randomUUID(),
                "Escuela de Cáceres", uniId, uni.name());
        CatalogSubject redes = new CatalogSubject(UUID.randomUUID(), merida.id(), "Redes de Ordenadores", 2, 2,
                "Obligatoria", 6.0, null, null, null, null);
        EnrollmentReading reading = new EnrollmentReading("UNIVERSIDAD DE EJEMPLO", "CENTRO DE MÉRIDA",
                "GRADO EN INFORMÁTICA", "2024-25", List.of(
                        new EnrolledSubject("1", "REDES DE ORDENADORES", 2, 6.0, "2S", 2),
                        new EnrolledSubject("2", "Asignatura nueva", 4, 6.0, "1S", 1)));

        EnrollmentProposal p = EnrollmentProposal.match(reading, List.of(uni),
                id -> List.of(caceres, merida), Map.of(merida.id(), List.of(redes))::get,
                List.of("Asignatura nueva"));

        assertThat(p.university()).isEqualTo(uni);
        assertThat(p.degree()).isEqualTo(merida);
        assertThat(p.subjects().get(0).catalogSubjectId()).isEqualTo(redes.id());
        assertThat(p.subjects().get(0).alreadyAdded()).isFalse();
        assertThat(p.subjects().get(1).catalogSubjectId()).isNull();
        assertThat(p.subjects().get(1).alreadyAdded()).isTrue();
    }
}
