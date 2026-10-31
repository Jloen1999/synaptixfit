package com.synaptixfit.infrastructure.adapter.output.external.ai.profile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;

import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

class EnrollmentReaderAiAdapterTest {

    private final EnrollmentReaderAiAdapter adapter =
            new EnrollmentReaderAiAdapter(mock(GenerativeAiPort.class), JsonMapper.builder().build());

    @Test
    void readsTheFieldsAndTreatsTheWordNullAsMissing() {
        var reading = adapter.parse("""
                {"universidad": "Universidad de Ejemplo", "centro": "null", "titulacion": "Grado",
                 "curso_academico": "2024-25",
                 "asignaturas": [{"codigo": "1", "nombre": "Redes", "curso": 2, "creditos": 4.5,
                                  "periodo": "2S", "veces_matriculada": 2},
                                 {"nombre": "  "}]}
                """);
        assertThat(reading.center()).isNull();
        assertThat(reading.subjects()).singleElement().satisfies(s -> {
            assertThat(s.name()).isEqualTo("Redes");
            assertThat(s.credits()).isEqualTo(4.5);
            assertThat(s.timesEnrolled()).isEqualTo(2);
        });
    }

    @Test
    void anInvalidAnswerIsReportedAsAiUnavailable() {
        assertThatThrownBy(() -> adapter.parse("no es json"))
                .extracting("code").isEqualTo("AI_UNAVAILABLE");
    }

    @Test
    void neverMoreThanFortySubjects() {
        StringBuilder many = new StringBuilder("{\"asignaturas\": [");
        for (int i = 0; i < 60; i++) {
            many.append(i == 0 ? "" : ",").append("{\"nombre\": \"A").append(i).append("\"}");
        }
        many.append("]}");
        assertThat(adapter.parse(many.toString()).subjects()).hasSize(EnrollmentReaderAiAdapter.MAX_SUBJECTS);
    }
}
