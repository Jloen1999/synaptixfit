package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Todas las preguntas de una asignatura (de todos sus apuntes y archivos) con cómo va cada una, y el nombre de la
 * asignatura para el título de la pantalla, en el orden en
 * que vuelven a practicarse ({@link QuestionStanding#COMES_BACK_FIRST}). Lo pinta el apartado «Practicar» (ADR 0063).
 */
public record SubjectQuestions(String subjectName, List<Item> questions) {

    /** Orden de la lista: primero las que vuelven antes; dentro, por material y por su orden en el banco. */
    public static final Comparator<Item> ORDER = Comparator.comparing(Item::standing, QuestionStanding.COMES_BACK_FIRST)
            .thenComparing(Item::materialTitle, String.CASE_INSENSITIVE_ORDER)
            .thenComparingInt(i -> i.question().order());

    public SubjectQuestions {
        subjectName = subjectName == null ? "" : subjectName;
        questions = questions == null ? List.of() : questions.stream().sorted(ORDER).toList();
    }

    public SubjectQuestions(List<Item> questions) {
        this("", questions);
    }

    /** Cuántas tocan repasar («No lo sé» o falladas en su último intento). */
    public int toReview() {
        return (int) questions.stream().filter(i -> i.standing().toReview()).count();
    }

    /** Pregunta con el material del que sale y su último intento ({@code lastAnsweredAt} nulo si es nueva). */
    public record Item(Question question, UUID materialId, String materialTitle, QuestionStanding standing,
                       Instant lastAnsweredAt) {

        public Item {
            materialTitle = materialTitle == null ? "" : materialTitle;
        }
    }
}
