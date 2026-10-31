package com.synaptixfit.domain.model.profile.enrollment;

import com.synaptixfit.domain.model.catalog.CatalogSubject;
import com.synaptixfit.domain.model.catalog.Degree;
import com.synaptixfit.domain.model.catalog.University;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentReading.EnrolledSubject;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Propuesta de importación de la matrícula: la lectura cruzada con el catálogo (universidad, carrera
 * y asignaturas que se reconocen) y con lo que el usuario ya tiene. No se guarda: el usuario la revisa
 * y elige qué añadir.
 *
 * @param university universidad del catálogo reconocida (o null)
 * @param degree     carrera del catálogo reconocida (o null)
 */
public record EnrollmentProposal(EnrollmentReading reading, University university, Degree degree,
                                 List<ProposedSubject> subjects) {

    public EnrollmentProposal {
        subjects = List.copyOf(subjects);
    }

    /**
     * @param catalogSubjectId asignatura del catálogo equivalente (null si no se reconoce)
     * @param alreadyAdded     el usuario ya tiene una asignatura con ese nombre
     */
    public record ProposedSubject(EnrolledSubject source, UUID catalogSubjectId, String catalogName,
                                  boolean alreadyAdded) {
    }

    /**
     * Cruza la lectura con el catálogo. La universidad y la carrera se reconocen por el nombre (sin
     * tildes ni mayúsculas, igual o contenido); si hay varias carreras con el mismo nombre (una por
     * centro), gana la del centro del documento.
     */
    public static EnrollmentProposal match(EnrollmentReading reading, Collection<University> universities,
                                           Function<UUID, List<Degree>> degreesOf,
                                           Function<UUID, List<CatalogSubject>> subjectsOf,
                                           Collection<String> existingSubjectNames) {
        University university = best(universities, reading.university(), University::name).orElse(null);
        Degree degree = null;
        if (university != null && reading.degree() != null) {
            List<Degree> named = degreesOf.apply(university.id()).stream()
                    .filter(d -> CatalogNames.matches(d.name(), reading.degree()))
                    .toList();
            degree = named.stream()
                    .filter(d -> reading.center() != null && CatalogNames.matches(d.centerName(), reading.center()))
                    .findFirst()
                    .orElse(named.isEmpty() ? null : named.getFirst());
        }
        List<CatalogSubject> catalog = degree == null ? List.of() : subjectsOf.apply(degree.id());
        Set<String> existing = existingSubjectNames.stream().map(CatalogNames::normalize).collect(Collectors.toSet());
        List<ProposedSubject> proposed = new ArrayList<>();
        for (EnrolledSubject s : reading.subjects()) {
            if (s.name() == null || s.name().isBlank()) {
                continue;
            }
            Optional<CatalogSubject> match = best(catalog, s.name(), CatalogSubject::name);
            String shownName = match.map(CatalogSubject::name).orElse(s.name());
            proposed.add(new ProposedSubject(s, match.map(CatalogSubject::id).orElse(null),
                    match.map(CatalogSubject::name).orElse(null),
                    existing.contains(CatalogNames.normalize(shownName))
                            || existing.contains(CatalogNames.normalize(s.name()))));
        }
        return new EnrollmentProposal(reading, university, degree, proposed);
    }

    /** Coincidencia exacta (normalizada) primero; si no, la que contiene o está contenida. */
    private static <T> Optional<T> best(Collection<T> items, String wanted, Function<T, String> name) {
        if (wanted == null || wanted.isBlank()) {
            return Optional.empty();
        }
        String w = CatalogNames.normalize(wanted);
        return items.stream().filter(i -> CatalogNames.normalize(name.apply(i)).equals(w)).findFirst()
                .or(() -> items.stream().filter(i -> CatalogNames.matches(name.apply(i), wanted)).findFirst());
    }
}
