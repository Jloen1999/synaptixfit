package com.synaptixfit.domain.model.academic;

/**
 * Experiencia de la práctica académica (cantidades del sistema antiguo).
 *
 * <ul>
 *   <li>Test o práctica completa: 20 XP, +10 si se acierta al menos el 80 %. Solo con al menos
 *       {@value #MIN_REWARDED_QUESTIONS} preguntas y como mucho {@value #MAX_REWARDED_TESTS_PER_DAY} tests con XP
 *       cada 24 h: antes un test de una pregunta daba 30 XP y se podía repetir sin fin.</li>
 *   <li>Repaso SM-2 que tocaba (ver {@code StudyMaterial.isReviewOwed}): {@value #DUE_REVIEW_XP} XP.
 *       Antes era una sola vez por material; ahora premia el hábito de repasar cuando toca, una vez
 *       al día como mucho por material porque el siguiente repaso queda al menos a un día.</li>
 *   <li>Ronda de flashcards que tocaba: 3 XP por tarjeta dominada y 1 por dudosa, entre
 *       {@value #DUE_REVIEW_XP} y {@value #FLASHCARDS_MAX_XP} XP (una ronda enorme no debe valer más
 *       que un test completo).</li>
 * </ul>
 */
public final class PracticeRewards {

    public static final int PRACTICE_BASE_XP = 20;
    public static final int PRACTICE_BONUS_XP = 10;
    public static final double BONUS_THRESHOLD = 0.8;
    public static final int DUE_REVIEW_XP = 5;
    public static final int FLASHCARDS_MAX_XP = 30;
    public static final int MIN_REWARDED_QUESTIONS = 5;
    public static final int MAX_REWARDED_TESTS_PER_DAY = 5;

    private PracticeRewards() {
    }

    /** XP de un test terminado; {@code rewardedLastDay} son los tests que dieron XP en las últimas 24 h. */
    public static int practiceXp(int correct, int total, int rewardedLastDay) {
        if (total < MIN_REWARDED_QUESTIONS || rewardedLastDay >= MAX_REWARDED_TESTS_PER_DAY) {
            return 0;
        }
        return PRACTICE_BASE_XP + ((double) correct / total >= BONUS_THRESHOLD ? PRACTICE_BONUS_XP : 0);
    }

    public static int flashcardsXp(int mastered, int doubtful) {
        return Math.max(0, mastered) * 3 + Math.max(0, doubtful);
    }

    /** XP de un repaso simple: solo si tocaba. */
    public static int reviewXp(boolean owed) {
        return owed ? DUE_REVIEW_XP : 0;
    }

    /** XP de una ronda de flashcards: solo si tocaba, acotada entre el repaso simple y el máximo. */
    public static int flashcardsReviewXp(boolean owed, int mastered, int doubtful) {
        if (!owed) {
            return 0;
        }
        return Math.max(DUE_REVIEW_XP, Math.min(FLASHCARDS_MAX_XP, flashcardsXp(mastered, doubtful)));
    }

    /**
     * Calidad SM-2 de una ronda de flashcards: 4 si al menos la mitad son dominadas, 3 si lo son
     * contando las dudosas y 0 en otro caso (el sistema antiguo solo distinguía 4 y 0).
     */
    public static int flashcardsQuality(int mastered, int doubtful, int failed) {
        int total = Math.max(0, mastered) + Math.max(0, doubtful) + Math.max(0, failed);
        if (total == 0) {
            return 0;
        }
        int half = (total + 1) / 2;
        if (mastered >= half) {
            return 4;
        }
        return mastered + doubtful >= half ? 3 : 0;
    }
}
