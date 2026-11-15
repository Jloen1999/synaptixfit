package com.synaptixfit.infrastructure.adapter.output.external.ocr;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.academic.NoteScanUnavailableException;
import com.synaptixfit.domain.model.academic.NotePhoto;
import com.synaptixfit.domain.model.academic.PageReading;
import com.synaptixfit.domain.model.shared.ImageHeader;
import com.synaptixfit.domain.model.shared.ImageHeaderTest;
import com.synaptixfit.infrastructure.adapter.output.external.image.ImagePixels;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class TesseractImageTextReaderTest {

    @Test
    void dictionariesFollowTheAppLanguageWithEnglishAsBackup() {
        assertThat(TesseractImageTextReader.languages("es")).isEqualTo("spa+eng");
        assertThat(TesseractImageTextReader.languages("en")).isEqualTo("eng");
        assertThat(TesseractImageTextReader.languages("fr")).isEqualTo("fra+eng");
        assertThat(TesseractImageTextReader.languages("pt")).isEqualTo("por+eng");
        assertThat(TesseractImageTextReader.languages(null)).isEqualTo("spa+eng");
    }

    @Test
    void anImageTheLibraryCannotOpenIsAFileProblemNotAnOutage() {
        assertThat(TesseractImageTextReader.unreadableImage("Error in pixReadMem: Unknown format")).isTrue();
        assertThat(TesseractImageTextReader.unreadableImage("Failed loading language 'spa'")).isFalse();
    }

    @Test
    void withAMemoryCapTesseractRunsUnderPrlimitWithoutAShell() {
        assertThat(TesseractImageTextReader.commandLine("tesseract", 768, "spa+eng")).containsExactly(
                "prlimit", "--as=" + 768L * 1024 * 1024, "--",
                "tesseract", "stdin", "stdout", "-l", "spa+eng", "--psm", "3", "tsv");
        assertThat(TesseractImageTextReader.commandLine("tesseract", 0, "eng")).first().isEqualTo("tesseract");
    }

    @Test
    void withoutTheProgramInstalledTheServiceSaysItIsUnavailable() {
        TesseractImageTextReader reader = new TesseractImageTextReader("programa-que-no-existe-ocr", 5, 1, 1, 0);
        assertThatThrownBy(() -> reader.read(new NotePhoto(new byte[] {1}, "image/png")))
                .isInstanceOf(NoteScanUnavailableException.class);
    }

    @Test
    void theTsvOutputGivesTheTextByLinesAndParagraphsAndItsConfidence() {
        String tsv = String.join("\n",
                "level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext",
                "1\t1\t0\t0\t0\t0\t0\t0\t800\t600\t-1\t",
                "2\t1\t1\t0\t0\t0\t10\t10\t500\t40\t-1\t",
                "5\t1\t1\t1\t1\t1\t10\t10\t100\t20\t96.5\tTema",
                "5\t1\t1\t1\t1\t2\t120\t10\t20\t20\t91\t1",
                "5\t1\t1\t1\t2\t1\t10\t40\t100\t20\t90\tLa",
                "5\t1\t1\t1\t2\t2\t120\t40\t100\t20\t88\tcélula",
                "5\t1\t2\t1\t1\t1\t10\t90\t100\t20\t95\tNúcleo",
                "5\t1\t2\t1\t1\t2\t10\t90\t100\t20\t-1\t ");
        PageReading reading = TesseractImageTextReader.parseTsv(tsv);

        assertThat(reading.text()).isEqualTo("Tema 1\nLa célula\n\nNúcleo");
        assertThat(reading.confidence()).isBetween(90, 96);
        assertThat(reading.unclear()).isFalse();
    }

    @Test
    void anOutputWithoutWordsIsUnclear() {
        PageReading reading = TesseractImageTextReader.parseTsv("level\tpage_num\n1\t1\t0\t0\t0\t0\t0\t0\t1\t1\t-1\t");
        assertThat(reading.text()).isEmpty();
        assertThat(reading.unclear()).isTrue();
    }

    /**
     * Foto de 80×40 con la esquina de arriba a la izquierda negra, tal como se ve. Para cada orientación se guarda
     * como lo haría la cámara (los píxeles girados y la etiqueta EXIF) y, al prepararla para Tesseract, debe salir
     * derecha otra vez: misma forma, la esquina negra en su sitio, en gris y en PNG.
     */
    @ParameterizedTest
    @ValueSource(ints = {1, 2, 3, 4, 5, 6, 7, 8})
    void aPhotoTakenInAnyOrientationReachesTesseractUpright(int orientation) throws Exception {
        BufferedImage upright = new BufferedImage(80, 40, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = upright.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, 80, 40);
        g.setColor(Color.BLACK);
        g.fillRect(0, 0, 40, 20);
        g.dispose();
        // Las orientaciones 6 y 8 son la inversa una de otra; las demás se deshacen solas.
        int inverse = orientation == 6 ? 8 : orientation == 8 ? 6 : orientation;
        byte[] jpeg = ImageHeaderTest.withExifOrientation(
                ImagePixels.jpeg(ImagePixels.orient(upright, inverse), 0.95f), orientation);
        assertThat(ImageHeader.read(jpeg).orElseThrow().orientation()).isEqualTo(orientation);

        byte[] prepared = TesseractImageTextReader.prepare(jpeg);
        BufferedImage out = ImageIO.read(new ByteArrayInputStream(prepared));

        assertThat(prepared).startsWith((byte) 0x89, (byte) 'P', (byte) 'N', (byte) 'G');
        assertThat(out.getType()).isEqualTo(BufferedImage.TYPE_BYTE_GRAY);
        assertThat(out.getWidth()).isEqualTo(80);
        assertThat(out.getHeight()).isEqualTo(40);
        assertThat(out.getRaster().getSample(10, 5, 0)).isLessThan(60);
        assertThat(out.getRaster().getSample(70, 5, 0)).isGreaterThan(200);
        assertThat(out.getRaster().getSample(10, 35, 0)).isGreaterThan(200);
    }

    @Test
    void whatJavaCannotOpenIsSentAsItCame() {
        byte[] odd = {1, 2, 3, 4, 5};
        assertThat(TesseractImageTextReader.prepare(odd)).isSameAs(odd);
    }
}
