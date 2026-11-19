package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.BankUpdateMode;
import com.synaptixfit.domain.model.academic.QuestionBankGeneration;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionFormat;
import com.synaptixfit.domain.model.academic.QuestionType;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * «Crear preguntas» de un material (ADR 0058): las del documento que la persona eligió más las nuevas que
 * crea la IA por tandas; se añaden a las que tiene (sin repetir) o las sustituyen.
 */
public interface GenerateQuestionBankUseCase {

    /**
     * @param documentQuestions preguntas del documento ya revisadas (pueden ir vacías)
     * @param supportedTypes    tipos que sabe pintar la app (las antiguas no conocen «Varias correctas»)
     */
    record Command(UUID userId, UUID materialId, QuestionFormat format, int newQuestions, BankUpdateMode mode,
                   List<QuestionDraft> documentQuestions, Set<QuestionType> supportedTypes) {

        public Command {
            format = format == null ? QuestionFormat.MIXED : format;
            mode = mode == null ? BankUpdateMode.REPLACE : mode;
            documentQuestions = documentQuestions == null ? List.of() : List.copyOf(documentQuestions);
            supportedTypes = supportedTypes == null ? QuestionType.ALL : Set.copyOf(supportedTypes);
        }

        /** Lo que hacían las apps anteriores sin cuerpo: 10 preguntas mezcladas que sustituyen a las de antes. */
        public static Command legacy(UUID userId, UUID materialId) {
            return new Command(userId, materialId, QuestionFormat.MIXED, 10, BankUpdateMode.REPLACE, List.of(),
                    QuestionType.LEGACY);
        }
    }

    QuestionBankGeneration generateBank(Command command);
}
