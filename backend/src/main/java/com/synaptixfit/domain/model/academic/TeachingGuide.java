package com.synaptixfit.domain.model.academic;

import com.synaptixfit.domain.exception.FieldValidationException;
import java.text.Normalizer;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Guía docente (plan docente) de una asignatura extraída por la IA: datos de la asignatura,
 * profesorado, temario con progreso, criterios de evaluación con la nota obtenida y bibliografía.
 *
 * <p>Muchas guías tienen dos sistemas de evaluación (continua y global) que suman 100 % cada uno:
 * la calculadora solo usa los criterios de la modalidad activa (la elegida por el estudiante o,
 * si no eligió, la continua). La nota estimada es la media ponderada (0-10) de los criterios ya
 * calificados; la nota necesaria es la que hace falta en el resto para llegar a un 5.
 */
public record TeachingGuide(SubjectInfo subject, List<Professor> professors, List<Topic> topics,
                            List<Assessment> assessments, List<String> bibliography, EvaluationMode selectedMode) {

    public enum TopicKind { THEORY, PRACTICE }

    /** Modalidad de evaluación de un criterio; nula en el criterio significa «vale para las dos». */
    public enum EvaluationMode { CONTINUOUS, GLOBAL }

    /** Tipo de prueba; decide el tipo de entrega o examen que se crea en el planificador. */
    public enum AssessmentKind { EXAM, ASSIGNMENT, PRESENTATION, OTHER }

    /** Datos de identificación de la asignatura según la guía. Los ECTS admiten decimales (4,5). */
    public record SubjectInfo(String name, String code, Double ectsCredits, Integer courseYear, Integer semester,
                              String character, String degree, String center, String university,
                              String academicYear, String department, String description) {

        public SubjectInfo {
            name = clean(name, 150);
            code = clean(code, 50);
            ectsCredits = ectsCredits == null || ectsCredits <= 0 || ectsCredits > 60 ? null : ectsCredits;
            courseYear = courseYear == null || courseYear < 1 || courseYear > 6 ? null : courseYear;
            semester = semester == null || semester < 1 || semester > 12 ? null : semester;
            character = clean(character, 60);
            degree = clean(degree, 300);
            center = clean(center, 200);
            university = clean(university, 200);
            academicYear = clean(academicYear, 20);
            department = clean(department, 200);
            description = clean(description, 2000);
        }

        public static SubjectInfo empty() {
            return new SubjectInfo(null, null, null, null, null, null, null, null, null, null, null, null);
        }

        public boolean hasData() {
            return name != null || code != null || ectsCredits != null || degree != null;
        }

        /** Es la misma asignatura si coincide el código o el nombre (sin mayúsculas ni tildes). */
        public boolean matches(String subjectName, String subjectCode) {
            if (code != null && subjectCode != null && code.equalsIgnoreCase(subjectCode.strip())) {
                return true;
            }
            return name != null && subjectName != null && fold(name).equals(fold(subjectName));
        }

        private static String fold(String text) {
            return Normalizer.normalize(text, Normalizer.Form.NFD).replaceAll("\\p{M}", "")
                    .replaceAll("[^\\p{Alnum}]+", " ").strip().toLowerCase(Locale.ROOT);
        }

        /** Créditos enteros para la asignatura del usuario (1-30): 4,5 ECTS se redondean a 5. */
        public Integer roundedCredits() {
            return ectsCredits == null ? null : (int) Math.max(1, Math.min(30, Math.round(ectsCredits)));
        }
    }

    public record Professor(String name, String email, String office) {
    }

    public record Topic(String title, TopicKind kind, boolean completed, List<String> subtopics, Double hours) {
        public Topic {
            title = title == null ? "" : title.strip();
            kind = kind == null ? TopicKind.THEORY : kind;
            subtopics = subtopics == null ? List.of()
                    : subtopics.stream().map(s -> s == null ? "" : s.strip()).filter(s -> !s.isEmpty()).toList();
            hours = hours == null || hours <= 0 || hours > 1000 ? null : hours;
        }

        public Topic(String title, TopicKind kind, boolean completed) {
            this(title, kind, completed, List.of(), null);
        }

        Topic withCompleted(boolean value) {
            return new Topic(title, kind, value, subtopics, hours);
        }
    }

    /**
     * Criterio de evaluación. {@code topicNumbers} son los temas que cubre (1 = primer tema del
     * temario); {@code recoverable} nulo significa que la guía no lo dice.
     */
    public record Assessment(String name, double percentage, Double grade, EvaluationMode mode, AssessmentKind kind,
                             Integer durationMinutes, List<Integer> topicNumbers, Boolean recoverable,
                             LocalDate dueDate) {
        public Assessment {
            name = name == null ? "" : name.strip();
            percentage = Math.max(0, Math.min(100, percentage));
            if (grade != null && (grade < 0 || grade > 10)) {
                throw new FieldValidationException("grade", "OUT_OF_RANGE", "grade must be between 0 and 10");
            }
            kind = kind == null ? AssessmentKind.OTHER : kind;
            durationMinutes = durationMinutes == null || durationMinutes <= 0 || durationMinutes > 1440 ? null
                    : durationMinutes;
            topicNumbers = topicNumbers == null ? List.of()
                    : topicNumbers.stream().filter(n -> n != null && n > 0 && n <= 200).distinct().sorted().toList();
        }

        public Assessment(String name, double percentage, Double grade) {
            this(name, percentage, grade, null, AssessmentKind.OTHER, null, List.of(), null, null);
        }

        Assessment withGrade(Double value) {
            return new Assessment(name, percentage, value, mode, kind, durationMinutes, topicNumbers, recoverable,
                    dueDate);
        }
    }

    /** Estado de la calculadora: nota estimada, porcentaje calificado y lo necesario para aprobar. */
    public record GradeEstimate(double estimatedGrade, double coveredPercentage, Double requiredGradeToPass,
                                String nextPendingAssessment) {
    }

    /*
     * Límites del borrador: lo que la IA devuelve se recorta aquí con los mismos topes que valida la
     * API al aplicarlo, para que el estudiante siempre pueda reenviar el borrador sin errores que no
     * sabría corregir. Una prueba sin nombre recibe «Prueba N».
     */
    static final int MAX_PROFESSORS = 20;
    static final int MAX_TOPICS = 100;
    static final int MAX_SUBTOPICS = 40;
    static final int MAX_ASSESSMENTS = 50;
    static final int MAX_BIBLIOGRAPHY = 100;
    static final int MAX_TITLE = 300;
    static final int MAX_ASSESSMENT_NAME = 200;
    static final int MAX_REFERENCE = 1000;

    public TeachingGuide {
        subject = subject == null ? SubjectInfo.empty() : subject;
        professors = professors == null ? List.of() : professors.stream().limit(MAX_PROFESSORS)
                .map(p -> new Professor(clean(p.name(), 150), clean(p.email(), 200), clean(p.office(), 100)))
                .toList();
        topics = topics == null ? List.of() : topics.stream().filter(t -> !t.title().isEmpty()).limit(MAX_TOPICS)
                .map(t -> new Topic(clip(t.title(), MAX_TITLE), t.kind(), t.completed(),
                        t.subtopics().stream().limit(MAX_SUBTOPICS).map(st -> clip(st, MAX_TITLE)).toList(),
                        t.hours()))
                .toList();
        List<Assessment> named = new ArrayList<>();
        if (assessments != null) {
            for (Assessment a : assessments.stream().limit(MAX_ASSESSMENTS).toList()) {
                String name = a.name().isEmpty() ? "Prueba " + (named.size() + 1) : clip(a.name(), MAX_ASSESSMENT_NAME);
                named.add(new Assessment(name, a.percentage(), a.grade(), a.mode(), a.kind(), a.durationMinutes(),
                        a.topicNumbers(), a.recoverable(), a.dueDate()));
            }
        }
        assessments = List.copyOf(named);
        bibliography = bibliography == null ? List.of() : bibliography.stream()
                .map(b -> clean(b, MAX_REFERENCE)).filter(b -> b != null).limit(MAX_BIBLIOGRAPHY).toList();
    }

    private static String clip(String value, int max) {
        return value.length() > max ? value.substring(0, max).strip() : value;
    }

    public TeachingGuide(List<Professor> professors, List<Topic> topics, List<Assessment> assessments,
                         List<String> bibliography) {
        this(SubjectInfo.empty(), professors, topics, assessments, bibliography, null);
    }

    public boolean hasData() {
        return subject.hasData() || !professors.isEmpty() || !topics.isEmpty() || !assessments.isEmpty()
                || !bibliography.isEmpty();
    }

    /** Fracción de temas completados (0-1). */
    public double syllabusProgress() {
        if (topics.isEmpty()) {
            return 0;
        }
        return (double) topics.stream().filter(Topic::completed).count() / topics.size();
    }

    /** Modalidades que aparecen en la guía (vacía si ningún criterio indica modalidad). */
    public List<EvaluationMode> availableModes() {
        return List.of(EvaluationMode.values()).stream()
                .filter(m -> assessments.stream().anyMatch(a -> a.mode() == m)).toList();
    }

    /** Modalidad con la que se calcula la nota: la elegida si existe en la guía; si no, la continua. */
    public EvaluationMode effectiveMode() {
        List<EvaluationMode> available = availableModes();
        if (available.isEmpty()) {
            return null;
        }
        if (selectedMode != null && available.contains(selectedMode)) {
            return selectedMode;
        }
        return available.contains(EvaluationMode.CONTINUOUS) ? EvaluationMode.CONTINUOUS : available.get(0);
    }

    /** Un criterio cuenta para la nota si no indica modalidad o si es de la modalidad activa. */
    public boolean isActive(Assessment a) {
        EvaluationMode mode = effectiveMode();
        return mode == null || a.mode() == null || a.mode() == mode;
    }

    public TeachingGuide withSelectedMode(EvaluationMode mode) {
        return new TeachingGuide(subject, professors, topics, assessments, bibliography, mode);
    }

    public TeachingGuide withTopicCompleted(int index, boolean completed) {
        checkIndex(index, topics.size(), "topicIndex");
        List<Topic> copy = new ArrayList<>(topics);
        copy.set(index, copy.get(index).withCompleted(completed));
        return new TeachingGuide(subject, professors, copy, assessments, bibliography, selectedMode);
    }

    public TeachingGuide withGrade(int index, Double grade) {
        checkIndex(index, assessments.size(), "assessmentIndex");
        List<Assessment> copy = new ArrayList<>(assessments);
        copy.set(index, copy.get(index).withGrade(grade));
        return new TeachingGuide(subject, professors, topics, copy, bibliography, selectedMode);
    }

    /**
     * Al volver a importar la guía se conserva el progreso del estudiante: temas completados (por
     * título), notas (por nombre y modalidad) y la modalidad elegida.
     */
    public TeachingGuide keepingProgressOf(TeachingGuide previous) {
        if (previous == null) {
            return this;
        }
        Map<String, Boolean> done = new HashMap<>();
        previous.topics.forEach(t -> done.put(key(t.title()), t.completed()));
        Map<String, Double> grades = new HashMap<>();
        previous.assessments.stream().filter(a -> a.grade() != null)
                .forEach(a -> grades.put(key(a.name()) + "|" + a.mode(), a.grade()));
        List<Topic> mergedTopics = topics.stream()
                .map(t -> t.completed() ? t : t.withCompleted(done.getOrDefault(key(t.title()), false))).toList();
        List<Assessment> mergedAssessments = assessments.stream()
                .map(a -> a.grade() != null ? a : a.withGrade(grades.get(key(a.name()) + "|" + a.mode()))).toList();
        EvaluationMode mode = selectedMode != null ? selectedMode : previous.selectedMode;
        return new TeachingGuide(subject, professors, mergedTopics, mergedAssessments, bibliography, mode);
    }

    public GradeEstimate estimate() {
        double weighted = 0;
        double covered = 0;
        double remaining = 0;
        String pending = null;
        for (Assessment a : assessments) {
            if (!isActive(a)) {
                continue;
            }
            if (a.grade() != null) {
                weighted += a.grade() / 10 * a.percentage();
                covered += a.percentage();
            } else {
                remaining += a.percentage();
                if (pending == null) {
                    pending = a.name();
                }
            }
        }
        double estimated = covered > 0 ? clamp(weighted / covered * 10) : 0;
        Double required = null;
        if (covered < 100 && remaining > 0) {
            required = clamp((50.0 - weighted) / remaining * 10);
        }
        return new GradeEstimate(round2(estimated), covered, required == null ? null : round2(required), pending);
    }

    private static String key(String text) {
        return text == null ? "" : text.strip().toLowerCase(Locale.ROOT);
    }

    private static String clean(String value, int max) {
        if (value == null) {
            return null;
        }
        String s = value.strip().replaceAll("\\s+", " ");
        if (s.isEmpty()) {
            return null;
        }
        return s.length() > max ? s.substring(0, max).strip() : s;
    }

    private static void checkIndex(int index, int size, String field) {
        if (index < 0 || index >= size) {
            throw new FieldValidationException(field, "OUT_OF_RANGE", field + " is out of range");
        }
    }

    private static double clamp(double v) {
        return Math.max(0, Math.min(10, v));
    }

    private static double round2(double v) {
        return Math.round(v * 100) / 100.0;
    }
}
