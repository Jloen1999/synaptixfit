package com.synaptixfit.domain.port.output.ai;

import java.util.List;

/**
 * Modelo generativo de propósito general (DeepSeek en producción).
 *
 * <p>Los puertos de cada funcionalidad construyen sus prompts en la aplicación o en su
 * adaptador; este puerto solo transporta. Lanza AiUnavailableException o AiQuotaExceededException.
 */
public interface GenerativeAiPort {

    /** Genera texto libre (Markdown). */
    String generateText(String prompt, List<AiAttachment> attachments, double temperature);

    /** Genera un documento JSON (modo JSON del modelo). Devuelve el JSON como texto. */
    String generateJson(String prompt, List<AiAttachment> attachments, double temperature);
}
