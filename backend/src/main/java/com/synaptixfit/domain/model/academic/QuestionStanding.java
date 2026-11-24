package com.synaptixfit.domain.model.academic;

import java.util.Collection;
import java.util.Comparator;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Cómo va una pregunta según su <b>último</b> intento y en qué orden vuelve a practicarse (ADR 0063).
 *
 * <p>Cada intento equivale a una nota SM-2 (0-5, ver formulas.md): «No lo sé» = 0 (no se recuerda nada),
 * fallo = 2 (se intentó, pero mal) y acierto = 4. Al elegir preguntas para practicar o para un simulacro
 * salen antes las de nota más baja: primero las de «No lo sé», luego las falladas, luego las nuevas (sin nota)
 * y por último las acertadas. Así una pregunta que no sabías vuelve antes que una que fallaste.
 */
public enum QuestionStanding {
    DONT_KNOW(0),
    WRONG(2),
    NEW(-1),
    CORRECT(4);

    /**
     * Orden de vuelta: el de <b>declaración</b> de las constantes, no la nota: «No lo sé», falladas, nuevas (tercera
     * aunque no tenga nota) y acertadas. Reordenar las constantes cambia este orden.
     */
    public static final Comparator<QuestionStanding> COMES_BACK_FIRST = Comparator.comparingInt(Enum::ordinal);

    private final int recallQuality;

    QuestionStanding(int recallQuality) {
        this.recallQuality = recallQuality;
    }

    /** Nota SM-2 (0-5) del último intento; -1 si la pregunta aún no se ha contestado. */
    public int recallQuality() {
        return recallQuality;
    }

    /** Si toca repasarla: el último intento fue «No lo sé» o un fallo. */
    public boolean toReview() {
        return this == DONT_KNOW || this == WRONG;
    }

    /** Estado según un intento (el último de la pregunta) o {@link #NEW} si no hay. */
    public static QuestionStanding of(QuestionAttempt latest) {
        if (latest == null) {
            return NEW;
        }
        if (latest.dontKnow()) {
            return DONT_KNOW;
        }
        return latest.correct() ? CORRECT : WRONG;
    }

    /** Último intento de cada pregunta (el más reciente; a igual hora, el de nota más baja). */
    public static Map<UUID, QuestionAttempt> latest(Collection<QuestionAttempt> attempts) {
        return attempts.stream().collect(Collectors.toMap(QuestionAttempt::questionId, Function.identity(),
                (a, b) -> {
                    int byTime = a.answeredAt().compareTo(b.answeredAt());
                    if (byTime != 0) {
                        return byTime > 0 ? a : b;
                    }
                    return COMES_BACK_FIRST.compare(of(a), of(b)) <= 0 ? a : b;
                }));
    }
}
