package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TeachingGuide.AssessmentKind;
import com.synaptixfit.domain.model.academic.TeachingGuide.EvaluationMode;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

class StudyDocumentJsonCodecAdapterTest {

    private final StudyDocumentJsonCodecAdapter codec = new StudyDocumentJsonCodecAdapter(JsonMapper.builder().build());

    @Test
    void readsTheAiSchemaWithSynonymsAndLocaleNumbers() {
        TeachingGuide g = codec.decodeTeachingGuide("""
                {"asignatura": {"nombre": "Hardware", "codigo": 502376, "creditos_ects": "4,5", "semestre": 6,
                                "universidad": null, "curso_academico": "2025/2026"},
                 "temario": [{"titulo": "Tema 1", "tipo": "teoria", "subtemas": ["SoC", ""], "horas": 27},
                             "Tema 2"],
                 "evaluacion": [{"nombre": "Prueba 1", "porcentaje": "30%", "modalidad": "Evaluación continua",
                                 "tipo": "prueba escrita", "duracion_minutos": 120, "temas": [1, 2, "3"],
                                 "recuperable": false, "fecha": "2026-11-20"},
                                {"nombre": "Global", "porcentaje": 100, "modalidad": "global", "tipo": "trabajo"}],
                 "bibliografia": ["Beltrán 2010"]}""");

        assertThat(g.subject().code()).isEqualTo("502376");
        assertThat(g.subject().ectsCredits()).isEqualTo(4.5);
        assertThat(g.subject().university()).isNull();
        assertThat(g.topics()).hasSize(2);
        assertThat(g.topics().get(0).subtopics()).containsExactly("SoC");
        assertThat(g.topics().get(0).hours()).isEqualTo(27.0);
        TeachingGuide.Assessment first = g.assessments().get(0);
        assertThat(first.mode()).isEqualTo(EvaluationMode.CONTINUOUS);
        assertThat(first.kind()).isEqualTo(AssessmentKind.EXAM);
        assertThat(first.percentage()).isEqualTo(30);
        assertThat(first.topicNumbers()).containsExactly(1, 2, 3);
        assertThat(first.recoverable()).isFalse();
        assertThat(first.dueDate()).isEqualTo(LocalDate.of(2026, 11, 20));
        assertThat(g.assessments().get(1).kind()).isEqualTo(AssessmentKind.ASSIGNMENT);
        assertThat(g.assessments().get(1).recoverable()).isNull();
    }

    @Test
    void roundTripKeepsProgressAndChosenModeAndReadsOldGuides() {
        TeachingGuide original = codec.decodeTeachingGuide("""
                {"temario": [{"titulo": "Tema 1"}],
                 "evaluacion": [{"nombre": "Examen", "porcentaje": 60, "modalidad": "continua"},
                                {"nombre": "Final", "porcentaje": 100, "modalidad": "global"}]}""")
                .withTopicCompleted(0, true).withGrade(0, 7.5).withSelectedMode(EvaluationMode.GLOBAL);

        TeachingGuide back = codec.decodeTeachingGuide(codec.encodeTeachingGuide(original));

        assertThat(back).isEqualTo(original);
        assertThat(codec.decodeTeachingGuide("{\"temario\":[\"Tema\"],\"evaluacion\":[]}").subject().hasData())
                .isFalse();
    }
}
