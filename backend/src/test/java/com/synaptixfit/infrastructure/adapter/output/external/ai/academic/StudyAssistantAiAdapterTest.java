package com.synaptixfit.infrastructure.adapter.output.external.ai.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.MindMapNode;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.ai.AiAttachment;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic.StudyDocumentJsonCodecAdapter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

/** Parseo tolerante de las respuestas del modelo y codificación JSON de documentos (sin red). */
class StudyAssistantAiAdapterTest {

    private final JsonMapper mapper = JsonMapper.builder().build();
    private final StudyDocumentJsonCodecAdapter codec = new StudyDocumentJsonCodecAdapter(mapper);
    private final List<String> prompts = new ArrayList<>();
    private final List<List<AiAttachment>> attachments = new ArrayList<>();
    private String nextResponse;

    private final GenerativeAiPort ai = new GenerativeAiPort() {
        public String generateText(String prompt, List<AiAttachment> a, double t) {
            throw new UnsupportedOperationException();
        }

        public String generateJson(String prompt, List<AiAttachment> a, double t) {
            prompts.add(prompt);
            attachments.add(a);
            return nextResponse;
        }
    };
    private final StudyAssistantAiAdapter adapter = new StudyAssistantAiAdapter(ai, mapper, codec);

    @Test
    void summaryExtractsJsonWrappedInTextAndSendsBinariesAsAttachments() {
        nextResponse = "Claro: ```json\n{\"titulo_personalizado\":\"Célula\",\"contenido_markdown\":\"## Núcleo\"}\n```";
        StudyAssistantPort.Summary s = adapter.summarize(List.of(
                StudyAssistantPort.Source.text("Apunte", "texto del apunte"),
                StudyAssistantPort.Source.binary("tema.pdf", "application/pdf", new byte[]{1})));
        assertThat(s.title()).isEqualTo("Célula");
        assertThat(s.markdown()).isEqualTo("## Núcleo");
        assertThat(prompts.getFirst()).contains("--- FUENTE: Apunte ---").contains("texto del apunte")
                .contains("Fuente 2: \"tema.pdf\"");
        assertThat(attachments.getFirst()).singleElement()
                .satisfies(a -> assertThat(a.mimeType()).isEqualTo("application/pdf"));
    }

    @Test
    void invalidResponsesAreReportedAsAiUnavailable() {
        nextResponse = "lo siento";
        assertThatThrownBy(() -> adapter.summarize(List.of(StudyAssistantPort.Source.text("a", "b"))))
                .isInstanceOf(AiUnavailableException.class);
        nextResponse = "{\"titulo_personalizado\":\"x\",\"contenido_markdown\":\"\"}";
        assertThatThrownBy(() -> adapter.summarize(List.of(StudyAssistantPort.Source.text("a", "b"))))
                .isInstanceOf(AiUnavailableException.class);
    }

    @Test
    void mindMapComesFromIndentedMarkdown() {
        nextResponse = "{\"titulo_personalizado\":\"Célula\",\"contenido_markdown\":"
                + "\"- Célula\\n  - Núcleo\\n    - ADN\\n  - Membrana\"}";
        StudyAssistantPort.GeneratedMindMap m = adapter.mindMap(List.of(StudyAssistantPort.Source.text("a", "b")));
        assertThat(m.mindMap().central()).isEqualTo("Célula");
        assertThat(m.mindMap().branches()).extracting(MindMapNode::title).containsExactly("Núcleo", "Membrana");
    }

    @Test
    void practiceQuestionsAcceptLetterAnswersAndDropInvalidOnes() {
        nextResponse = """
                {"titulo_personalizado":"Célula","preguntas":[
                  {"tipo":"opcion_multiple","enunciado":"¿Dónde está el ADN?","opciones":["Núcleo","Pared"],
                   "respuesta_correcta":"A","explicacion":"En eucariotas"},
                  {"tipo":"rellenar_hueco","enunciado":"La ___ produce energía","respuesta_correcta":"mitocondria"},
                  {"tipo":"opcion_multiple","enunciado":"Sin opciones","opciones":[],"respuesta_correcta":"x"}
                ]}""";
        StudyAssistantPort.PracticeQuestions p = adapter.practiceQuestions(
                List.of(StudyAssistantPort.Source.text("a", "b")));
        assertThat(p.questions()).hasSize(2);
        assertThat(p.questions().getFirst().correctAnswer()).isEqualTo("Núcleo");
        assertThat(p.questions().get(1).type()).isEqualTo(QuestionType.FILL_IN_BLANK);
    }

    @Test
    void teachingGuideUsesLegacySchemaAndPercentStrings() {
        nextResponse = """
                {"profesores":[{"nombre":"Ana","email":"ana@u.es","despacho":"D-1"}],
                 "temario":[{"titulo":"Tema 1","tipo":"teoria"},{"titulo":"Lab","tipo":"practica"}],
                 "evaluacion":[{"nombre":"Examen","porcentaje":"60%"},{"nombre":"Prácticas","porcentaje":40}],
                 "bibliografia":["Alberts, B. (2015)."]}""";
        TeachingGuide g = adapter.extractTeachingGuide(StudyAssistantPort.Source.binary("g.pdf", "application/pdf",
                new byte[]{1}));
        assertThat(g.professors()).singleElement().satisfies(p -> assertThat(p.office()).isEqualTo("D-1"));
        assertThat(g.topics().get(1).kind()).isEqualTo(TeachingGuide.TopicKind.PRACTICE);
        assertThat(g.assessments()).extracting(TeachingGuide.Assessment::percentage).containsExactly(60.0, 40.0);
        assertThat(g.bibliography()).hasSize(1);
    }

    @Test
    void codecRoundTripsDocuments() {
        MindMap map = new MindMap("C", List.of(new MindMapNode("R", List.of(new MindMapNode("H", List.of())))));
        assertThat(codec.decodeMindMap(codec.encodeMindMap(map))).isEqualTo(map);

        TeachingGuide guide = new TeachingGuide(List.of(), List.of(new TeachingGuide.Topic("T",
                TeachingGuide.TopicKind.THEORY, true)), List.of(new TeachingGuide.Assessment("E", 100, 6.5)),
                List.of("Ref"));
        assertThat(codec.decodeTeachingGuide(codec.encodeTeachingGuide(guide))).isEqualTo(guide);

        var marker = new StudyDocumentCodecPort.PracticeMarker(UUID.randomUUID(), UUID.randomUUID(), 10);
        assertThat(codec.decodePractice(codec.encodePractice(marker))).isEqualTo(marker);
        // Las marcas antiguas tenían contenido vacío.
        assertThat(codec.decodePractice("").questionCount()).isZero();
        assertThat(codec.decodeMindMap("no-json").isEmpty()).isTrue();
    }
}
