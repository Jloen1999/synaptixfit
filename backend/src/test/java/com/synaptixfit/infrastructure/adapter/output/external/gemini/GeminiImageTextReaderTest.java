package com.synaptixfit.infrastructure.adapter.output.external.gemini;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.synaptixfit.domain.exception.academic.NoteScanUnavailableException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.PageReading;
import com.synaptixfit.domain.model.shared.ImageHeader;
import com.synaptixfit.domain.model.shared.ImageHeaderTest;
import com.synaptixfit.infrastructure.adapter.output.external.image.ImagePixels;
import java.awt.image.BufferedImage;
import java.time.Duration;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

/** {@link GeminiImageTextReader} contra un servidor HTTP simulado: nunca se llama a la API real. */
class GeminiImageTextReaderTest {

    private static final String URL = "https://vision.test/v1beta/models/modelo-test:generateContent";

    private MockRestServiceServer server;
    private GeminiImageTextReader reader;

    private static GeminiImageTextReader.Settings settings(String key) {
        return new GeminiImageTextReader.Settings(key, "modelo-test", Duration.ofSeconds(5), 64, "MINIMAL", 2);
    }

    /** Foto vertical de móvil: 120×60 guardada y EXIF 6 (se ve de 60×120). */
    private static NotePhoto photo() {
        byte[] jpeg = ImagePixels.jpeg(new BufferedImage(120, 60, BufferedImage.TYPE_INT_RGB), 0.9f);
        return new NotePhoto(ImageHeaderTest.withExifOrientation(jpeg, 6), "image/jpeg");
    }

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl("https://vision.test");
        server = MockRestServiceServer.bindTo(builder).build();
        reader = new GeminiImageTextReader(builder.build(), settings("clave-de-prueba"));
    }

    @Test
    void sendsTheUprightReducedPhotoInlineAndReturnsTheTranscription() {
        server.expect(requestTo(URL))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("x-goog-api-key", "clave-de-prueba"))
                .andExpect(jsonPath("$.contents[0].parts[0].inlineData.mimeType").value("image/jpeg"))
                .andExpect(jsonPath("$.contents[0].parts[1].text").value(GeminiImageTextReader.PROMPT))
                .andExpect(jsonPath("$.generationConfig.thinkingConfig.thinkingLevel").value("MINIMAL"))
                .andRespond(withSuccess("""
                        {"candidates":[{"content":{"role":"model","parts":[
                          {"text":"pensando…","thought":true},
                          {"text":"Tema 1\\nLa célula"}]},"finishReason":"STOP"}]}
                        """, MediaType.APPLICATION_JSON));

        PageReading reading = reader.read(photo());

        assertThat(reading.text()).isEqualTo("Tema 1\nLa célula");
        assertThat(reading.confidence()).isEqualTo(PageReading.UNKNOWN);
        assertThat(reading.unclear()).isFalse();
        server.verify();
    }

    @Test
    void thePhotoLeavesUprightWithoutMetadataAndNoBiggerThanTheLimit() {
        byte[] sent = reader.prepare(photo().content());
        ImageHeader header = ImageHeader.read(sent).orElseThrow();
        assertThat(header.orientation()).isEqualTo(ImageHeader.UPRIGHT);
        assertThat(header.width()).isLessThan(header.height());
        assertThat(Math.max(header.width(), header.height())).isLessThanOrEqualTo(64);
    }

    @Test
    void anErrorFromGoogleBecomesUnavailableWithoutRetrying() {
        server.expect(requestTo(URL)).andRespond(withStatus(HttpStatus.TOO_MANY_REQUESTS));
        assertThatThrownBy(() -> reader.read(photo())).isInstanceOf(NoteScanUnavailableException.class);
        server.verify();
    }

    @Test
    void aBlockedAnswerIsUnavailableAndAnEmptyOneHasNoText() {
        server.expect(requestTo(URL)).andRespond(withSuccess("""
                {"promptFeedback":{"blockReason":"OTHER"}}""", MediaType.APPLICATION_JSON));
        assertThatThrownBy(() -> reader.read(photo())).isInstanceOf(NoteScanUnavailableException.class);

        server.reset();
        server.expect(requestTo(URL)).andRespond(withSuccess("""
                {"candidates":[{"content":{"parts":[{"text":""}]},"finishReason":"STOP"}]}""",
                MediaType.APPLICATION_JSON));
        assertThat(reader.read(photo()).hasText()).isFalse();
    }

    @Test
    void withoutKeyItIsDisabledAndNeverCalled() {
        GeminiImageTextReader noKey = new GeminiImageTextReader(RestClient.builder().build(), settings(""));
        assertThat(noKey.available()).isFalse();
        assertThatThrownBy(() -> noKey.read(photo())).isInstanceOf(NoteScanUnavailableException.class);
        assertThat(settings("secreta").toString()).doesNotContain("secreta");
    }
}
