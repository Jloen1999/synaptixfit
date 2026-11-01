package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.util.UUID;

/**
 * Resumen de un apunte compartido para los listados: autor, asignatura del catálogo y un extracto en
 * texto plano, sin el contenido completo (que se pide al abrirlo). Lo devuelve {@code ListSharedNotesUseCase}.
 *
 * @param visibility visibilidad efectiva: la más restrictiva entre la del apunte y la del perfil del autor
 */
public record SharedNoteSummary(UUID id, UUID authorId, String authorName, String authorAvatarUrl,
                                UUID catalogSubjectId, String catalogSubjectName, String title, String excerpt,
                                Visibility visibility, Instant updatedAt) {

    /** Longitud máxima del extracto, en caracteres. */
    public static final int EXCERPT_LENGTH = 180;

    /** Caracteres del principio del contenido que hacen falta para sacar el extracto. */
    public static final int SOURCE_LENGTH = 600;

    /**
     * Extracto en texto plano del principio de un apunte en Markdown: quita marcas de formato (títulos,
     * énfasis, citas, listas, enlaces e imágenes), junta los espacios y corta en una palabra.
     */
    public static String excerptOf(String markdown) {
        if (markdown == null || markdown.isBlank()) {
            return "";
        }
        String text = markdown
                .replaceAll("!\\[([^\\]]*)\\]\\([^)]*\\)", "$1")
                .replaceAll("\\[([^\\]]*)\\]\\([^)]*\\)", "$1")
                .replaceAll("(?m)^\\s{0,3}(#{1,6}|>+|[-*+]|\\d+[.)])\\s+", "")
                .replaceAll("[*_`~|]", "")
                .replaceAll("\\s+", " ")
                .strip();
        if (text.length() <= EXCERPT_LENGTH) {
            return text;
        }
        int cut = text.lastIndexOf(' ', EXCERPT_LENGTH);
        return text.substring(0, cut > EXCERPT_LENGTH / 2 ? cut : EXCERPT_LENGTH).strip() + "…";
    }
}
