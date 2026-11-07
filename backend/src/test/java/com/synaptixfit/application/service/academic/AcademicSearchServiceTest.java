package com.synaptixfit.application.service.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.academic.AcademicSearch;
import com.synaptixfit.domain.port.output.academic.AcademicSearchPort;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Buscador de Académico (ADR 0036): texto validado y plegado, grupos con «hay más» y sin grupos vacíos. */
class AcademicSearchServiceTest {

    private final List<String> asked = new ArrayList<>();

    private final AcademicSearchPort port = new AcademicSearchPort() {
        @Override
        public List<AcademicSearch.Hit> subjects(UUID userId, String folded, int limit) {
            asked.add(folded + ":" + limit);
            return hits(AcademicSearch.Kind.SUBJECT, 1);
        }

        @Override
        public List<AcademicSearch.Hit> notes(UUID userId, String folded, int limit) {
            return hits(AcademicSearch.Kind.NOTE, limit);
        }

        @Override
        public List<AcademicSearch.Hit> files(UUID userId, String folded, int limit) {
            return List.of();
        }

        @Override
        public List<AcademicSearch.Hit> deadlines(UUID userId, String folded, int limit) {
            return hits(AcademicSearch.Kind.DEADLINE, 2);
        }
    };

    private static List<AcademicSearch.Hit> hits(AcademicSearch.Kind kind, int count) {
        return IntStream.range(0, count).mapToObj(i -> new AcademicSearch.Hit(kind, UUID.randomUUID(), "t" + i,
                null, null, null, false)).toList();
    }

    private final AcademicSearchService service = new AcademicSearchService(port);

    @Test
    void groupsByKindSkipsEmptyGroupsAndSaysWhenThereIsMore() {
        AcademicSearch.Result result = service.search(UUID.randomUUID(), "  Física   Cuántica ");

        assertThat(result.query()).isEqualTo("Física Cuántica");
        assertThat(asked).containsExactly("fisica cuantica:" + (AcademicSearch.PER_GROUP + 1));
        assertThat(result.groups()).extracting(AcademicSearch.Group::kind)
                .containsExactly(AcademicSearch.Kind.SUBJECT, AcademicSearch.Kind.NOTE, AcademicSearch.Kind.DEADLINE);
        AcademicSearch.Group notes = result.groups().get(1);
        assertThat(notes.hits()).hasSize(AcademicSearch.PER_GROUP);
        assertThat(notes.more()).isTrue();
        assertThat(result.groups().get(0).more()).isFalse();
    }

    @Test
    void tooShortQueriesAreRejected() {
        assertThatThrownBy(() -> service.search(UUID.randomUUID(), " a "))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void foldingRemovesCaseAndAccents() {
        assertThat(AcademicSearch.fold("ÁRBOL Ñandú Pingüino")).isEqualTo("arbol nandu pinguino");
    }
}
