package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic;

import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.MasteryState;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.model.academic.SubjectPriority;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import java.util.Locale;

/** Vocabulario de la base de datos (minúsculas y español) ↔ enums del dominio académico. */
public final class AcademicDbCodes {

    private AcademicDbCodes() {
    }

    public static String priority(SubjectPriority p) {
        return switch (p) {
            case LOW -> "baja";
            case MEDIUM -> "media";
            case HIGH -> "alta";
        };
    }

    public static SubjectPriority priority(String v) {
        return switch (v == null ? "media" : v) {
            case "baja" -> SubjectPriority.LOW;
            case "alta" -> SubjectPriority.HIGH;
            default -> SubjectPriority.MEDIUM;
        };
    }

    public static String sourceType(StudySourceType t) {
        return t == StudySourceType.NOTE ? "apunte" : "archivo";
    }

    public static StudySourceType sourceType(String v) {
        return "apunte".equals(v) ? StudySourceType.NOTE : StudySourceType.FILE;
    }

    public static String documentSource(AiDocumentSource s) {
        return switch (s) {
            case NOTE -> "apunte";
            case FILE -> "archivo";
            case SUBJECT -> "guia_docente";
        };
    }

    public static AiDocumentSource documentSource(String v) {
        return switch (v) {
            case "apunte" -> AiDocumentSource.NOTE;
            case "archivo" -> AiDocumentSource.FILE;
            default -> AiDocumentSource.SUBJECT;
        };
    }

    public static String documentType(AiDocumentType t) {
        return switch (t) {
            case SUMMARY -> "resumen";
            case MIND_MAP -> "mapa_mental";
            case PRACTICE -> "practica";
            case TEACHING_GUIDE -> "guia_docente";
        };
    }

    public static AiDocumentType documentType(String v) {
        return switch (v) {
            case "resumen" -> AiDocumentType.SUMMARY;
            case "mapa_mental" -> AiDocumentType.MIND_MAP;
            case "practica" -> AiDocumentType.PRACTICE;
            default -> AiDocumentType.TEACHING_GUIDE;
        };
    }

    public static String mastery(MasteryState s) {
        return switch (s) {
            case NOT_EVALUATED -> "sin_evaluar";
            case IN_PROGRESS -> "en_progreso";
            case MASTERED -> "dominado";
            case NEEDS_REVIEW -> "necesita_repaso";
            case ABANDONED -> "abandonado";
        };
    }

    public static MasteryState mastery(String v) {
        return switch (v == null ? "sin_evaluar" : v) {
            case "en_progreso" -> MasteryState.IN_PROGRESS;
            case "dominado" -> MasteryState.MASTERED;
            case "necesita_repaso" -> MasteryState.NEEDS_REVIEW;
            case "abandonado" -> MasteryState.ABANDONED;
            default -> MasteryState.NOT_EVALUATED;
        };
    }

    public static String questionType(QuestionType t) {
        return t == QuestionType.FILL_IN_BLANK ? "rellenar_hueco" : "opcion_multiple";
    }

    public static QuestionType questionType(String v) {
        return "rellenar_hueco".equals(v) ? QuestionType.FILL_IN_BLANK : QuestionType.MULTIPLE_CHOICE;
    }

    public static String sessionStatus(TestSessionStatus s) {
        return s.name().toLowerCase(Locale.ROOT);
    }

    public static TestSessionStatus sessionStatus(String v) {
        return v == null ? TestSessionStatus.IN_PROGRESS : TestSessionStatus.valueOf(v.toUpperCase(Locale.ROOT));
    }
}
