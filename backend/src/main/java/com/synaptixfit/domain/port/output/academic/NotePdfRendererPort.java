package com.synaptixfit.domain.port.output.academic;

/** Convierte un apunte en Markdown en un PDF para descargarlo o compartirlo fuera de la app (ADR 0064). */
public interface NotePdfRendererPort {

    byte[] render(String title, String markdown);
}
