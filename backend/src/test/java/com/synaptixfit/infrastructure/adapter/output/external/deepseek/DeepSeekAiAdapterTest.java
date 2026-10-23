package com.synaptixfit.infrastructure.adapter.output.external.deepseek;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.synaptixfit.domain.exception.AiAttachmentNotSupportedException;
import com.synaptixfit.domain.exception.AiQuotaExceededException;
import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.port.output.ai.AiAttachment;
import com.synaptixfit.infrastructure.config.AppProperties;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

/** {@link DeepSeekAiAdapter} contra un servidor HTTP simulado: petición enviada y traducción de errores. */
class DeepSeekAiAdapterTest {

    private static final String URL = "https://api.test/chat/completions";

    private MockRestServiceServer server;
    private DeepSeekAiAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl("https://api.test");
        server = MockRestServiceServer.bindTo(builder).build();
        adapter = new DeepSeekAiAdapter(builder.build(),
                new AppProperties.Ai("clave-test", "deepseek-chat", "https://api.test", Duration.ofSeconds(5), 1000),
                new AttachmentTextExtractor());
    }

    private static String reply(String content, String finishReason) {
        return """
                {"choices":[{"message":{"role":"assistant","content":%s},"finish_reason":"%s"}]}
                """.formatted("\"" + content.replace("\"", "\\\"").replace("\n", "\\n") + "\"", finishReason);
    }

    @Test
    void jsonModeSendsSystemPromptAndResponseFormat() {
        server.expect(requestTo(URL))
                .andExpect(header("Authorization", "Bearer clave-test"))
                .andExpect(jsonPath("$.model").value("deepseek-chat"))
                .andExpect(jsonPath("$.response_format.type").value("json_object"))
                .andExpect(jsonPath("$.messages[0].role").value("system"))
                .andExpect(jsonPath("$.messages[1].content").value("Dame un plan"))
                .andRespond(withSuccess(reply("```json\n{\"ok\":true}\n```", "stop"), MediaType.APPLICATION_JSON));

        assertThat(adapter.generateJson("Dame un plan", List.of(), 0.2)).isEqualTo("{\"ok\":true}");
        server.verify();
    }

    @Test
    void textAttachmentsAreAppendedToThePrompt() {
        server.expect(requestTo(URL))
                .andExpect(jsonPath("$.messages[0].content").value("Resume\n\n=== DOCUMENTO 1 ===\nTema 1: células"))
                .andRespond(withSuccess(reply("Resumen", "stop"), MediaType.APPLICATION_JSON));

        String out = adapter.generateText("Resume",
                List.of(new AiAttachment("text/plain", "Tema 1: células".getBytes(StandardCharsets.UTF_8))), 0.3);
        assertThat(out).isEqualTo("Resumen");
    }

    @Test
    void imagesAreRejectedBeforeCallingTheApi() {
        assertThatThrownBy(() -> adapter.generateText("Lee", List.of(new AiAttachment("image/png", new byte[]{1})), 0.3))
                .isInstanceOf(AiAttachmentNotSupportedException.class);
        server.verify();
    }

    @Test
    void quotaAndBalanceErrorsMapToQuotaExceeded() {
        server.expect(requestTo(URL)).andRespond(withStatus(HttpStatus.PAYMENT_REQUIRED));
        assertThatThrownBy(() -> adapter.generateText("x", List.of(), 0.3)).isInstanceOf(AiQuotaExceededException.class);
    }

    @Test
    void truncatedResponsesAreRejected() {
        server.expect(requestTo(URL)).andRespond(withSuccess(reply("{\"a\":", "length"), MediaType.APPLICATION_JSON));
        assertThatThrownBy(() -> adapter.generateJson("x", List.of(), 0.3)).isInstanceOf(AiUnavailableException.class);
    }

    @Test
    void missingKeyMeansUnavailable() {
        DeepSeekAiAdapter noKey = new DeepSeekAiAdapter(RestClient.builder().build(),
                new AppProperties.Ai("", "deepseek-chat", "https://api.test", Duration.ofSeconds(5), 1000),
                new AttachmentTextExtractor());
        assertThatThrownBy(() -> noKey.generateText("x", List.of(), 0.3)).isInstanceOf(AiUnavailableException.class);
    }
}
