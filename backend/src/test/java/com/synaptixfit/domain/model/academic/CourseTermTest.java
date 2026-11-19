package com.synaptixfit.domain.model.academic;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;

class CourseTermTest {

    @Test
    void degreeSemesterBecomesCourseAndTerm() {
        assertThat(CourseTerm.fromGuide(null, 6)).contains(new CourseTerm(3, 2));
        assertThat(CourseTerm.fromGuide(null, 3)).contains(new CourseTerm(2, 1));
        assertThat(CourseTerm.fromGuide(null, 8)).contains(new CourseTerm(4, 2));
        // Con curso y semestre del grado manda el semestre: el curso sale de él.
        assertThat(CourseTerm.fromGuide(3, 5)).contains(new CourseTerm(3, 1));
    }

    @Test
    void courseAndTermAreUsedAsTheyCome() {
        assertThat(CourseTerm.fromGuide(2, 1)).contains(new CourseTerm(2, 1));
        assertThat(CourseTerm.fromGuide(4, 2)).contains(new CourseTerm(4, 2));
    }

    @Test
    void unknownWhenTheGuideDoesNotSaySure() {
        // «Semestre 2» sin curso: podría ser 1.º o cualquier otro curso.
        assertThat(CourseTerm.fromGuide(null, 2)).isEmpty();
        assertThat(CourseTerm.fromGuide(3, null)).isEmpty();
        assertThat(CourseTerm.fromGuide(null, null)).isEmpty();
        assertThat(CourseTerm.fromGuide(null, 0)).isEmpty();
    }

    @Test
    void guideInfoExposesItsCourseTerm() {
        var info = new TeachingGuide.SubjectInfo("Redes", null, 6.0, null, 6, null, null, null, null, null, null,
                null);
        assertThat(info.courseTerm()).contains(new CourseTerm(3, 2));
        assertThat(new TeachingGuide(info, List.of(), List.of(), List.of(), List.of(), null).subject().courseTerm())
                .contains(new CourseTerm(3, 2));
    }
}
