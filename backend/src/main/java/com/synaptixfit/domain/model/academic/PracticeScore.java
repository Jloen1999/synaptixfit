package com.synaptixfit.domain.model.academic;

import java.time.Duration;
import java.time.Instant;
import java.util.Collection;
import java.util.Comparator;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Resultado de la práctica reciente de un material y la autoevaluación que se propone con él en el
 * repaso espaciado. Solo es una propuesta: quien repasa elige la nota.
 *
 * <p>Cuenta la última respuesta a cada pregunta del material dada en las últimas {@link #WINDOW} y
 * después del último repaso (lo practicado antes ya se valoró). Con menos de {@link #MIN_ANSWERED}
 * preguntas no se propone nada: dos aciertos no dicen cuánto se recuerda. La escala sigue SM-2, que
 * da por fallo una nota menor que 3: un 60 % de aciertos ya es «Bien, con esfuerzo».
 */
public record PracticeScore(int correct, int answered, int suggestedQuality, Instant practicedAt) {

    public static final Duration WINDOW = Duration.ofHours(6);
    public static final int MIN_ANSWERED = 3;

    /** Nota SM-2 (0-5) propuesta para una proporción de aciertos de 0 a 1. */
    public static int qualityFor(double ratio) {
        if (ratio >= 0.9) {
            return 5;
        }
        if (ratio >= 0.75) {
            return 4;
        }
        if (ratio >= 0.6) {
            return 3;
        }
        if (ratio >= 0.4) {
            return 2;
        }
        return ratio >= 0.2 ? 1 : 0;
    }

    /**
     * Práctica reciente con las respuestas del usuario a las preguntas del material, o vacío si no hay
     * bastantes. {@code lastReviewedAt} puede ser nulo (nunca repasado).
     */
    public static Optional<PracticeScore> from(Collection<QuestionAttempt> attempts, Instant lastReviewedAt,
                                               Instant now) {
        Instant from = now.minus(WINDOW);
        if (lastReviewedAt != null && lastReviewedAt.isAfter(from)) {
            from = lastReviewedAt;
        }
        Instant since = from;
        Map<UUID, QuestionAttempt> latest = attempts.stream()
                .filter(a -> a.answeredAt().isAfter(since) && !a.answeredAt().isAfter(now))
                .collect(Collectors.toMap(QuestionAttempt::questionId, Function.identity(),
                        (a, b) -> a.answeredAt().isAfter(b.answeredAt()) ? a : b));
        if (latest.size() < MIN_ANSWERED) {
            return Optional.empty();
        }
        int correct = (int) latest.values().stream().filter(QuestionAttempt::correct).count();
        Instant last = latest.values().stream().map(QuestionAttempt::answeredAt).max(Comparator.naturalOrder())
                .orElse(now);
        return Optional.of(new PracticeScore(correct, latest.size(), qualityFor((double) correct / latest.size()),
                last));
    }
}
