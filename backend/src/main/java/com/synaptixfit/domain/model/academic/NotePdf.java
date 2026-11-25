package com.synaptixfit.domain.model.academic;

/**
 * Un apunte exportado a PDF: el nombre del archivo (sale del título, sin caracteres que los sistemas de archivos
 * no aceptan) y su contenido. Lo devuelve {@code ExportNotePdfUseCase}.
 */
public record NotePdf(String fileName, byte[] content) {

    static final int MAX_NAME = 80;

    /** Nombre de archivo seguro a partir del título: sin {@code / \ : * ? " < > |}, recortado y con «.pdf». */
    public static String fileNameFor(String title) {
        String base = title == null ? "" : title.replaceAll("[\\\\/:*?\"<>|\\p{Cntrl}]", " ")
                .replaceAll("\s+", " ").strip();
        if (base.length() > MAX_NAME) {
            base = base.substring(0, MAX_NAME).strip();
        }
        return (base.isEmpty() ? "apunte" : base) + ".pdf";
    }
}
