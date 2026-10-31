package com.synaptixfit.domain.model.profile.enrollment;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Quita del texto de una carta de pago o resguardo de matrícula los datos personales antes de que
 * salga del servidor hacia la IA: DNI/NIE, cuentas bancarias, correos, teléfonos y referencias largas,
 * líneas de dirección o de datos del estudiante y las líneas con su nombre. Lo que queda (universidad,
 * titulación y asignaturas) basta para reconocer la matrícula.
 */
public final class PersonalDataRedactor {

    static final String MASK = "[dato oculto]";

    private static final List<Pattern> VALUES = List.of(
            // DNI/NIF (8 cifras + letra) y NIE (X/Y/Z + 7 cifras + letra), con o sin guion.
            Pattern.compile("\\b\\d{8}[- ]?[A-Za-z]\\b"),
            Pattern.compile("\\b[XYZxyz][- ]?\\d{7}[- ]?[A-Za-z]\\b"),
            // IBAN y cuentas: dos letras, dos cifras y al menos diez cifras más (con espacios).
            Pattern.compile("\\b[A-Z]{2}\\d{2}(?:[ -]?\\d){10,30}\\b"),
            Pattern.compile("[\\w.+-]+@[\\w-]+\\.[\\w.-]+"),
            // Teléfonos, referencias de pago y cualquier serie de 9 o más cifras.
            Pattern.compile("\\+?\\d(?:[ .-]?\\d){8,}"));

    /** Líneas que llevan datos del estudiante o su domicilio: se quitan enteras. */
    private static final Pattern PERSONAL_LINE = Pattern.compile(
            "(?i)\\b(alumn[oa]|estudiante|nombre|apellidos?|domicilio|direcci[oó]n|calle|avda|avenida|"
                    + "plaza|n\\.?\\s?i\\.?\\s?f|dni|nie|pasaporte|tel[eé]fono|m[oó]vil|e-?mail|correo|cuenta|iban|"
                    + "titular|c[oó]digo postal|localidad|provincia)\\b");

    /** Línea que empieza por un código postal (5 cifras y la localidad). */
    private static final Pattern POSTAL_LINE = Pattern.compile("^\\s*\\d{5}\\s+\\p{L}.*$");

    private PersonalDataRedactor() {
    }

    /**
     * @param knownNames nombre completo del usuario: una línea con dos o más de sus palabras (de 3 o
     *                   más letras, sin distinguir mayúsculas ni tildes) se quita entera. Una palabra
     *                   suelta no basta, para no borrar «Universidad de León» a quien se apellide León.
     */
    public static String redact(String text, List<String> knownNames) {
        if (text == null || text.isBlank()) {
            return "";
        }
        List<String> nameWords = knownNames == null ? List.of() : knownNames.stream()
                .filter(n -> n != null && !n.isBlank())
                .flatMap(n -> List.of(n.split("\\s+")).stream())
                .map(PersonalDataRedactor::fold)
                .filter(w -> w.length() >= 3)
                .distinct()
                .toList();
        return text.lines()
                .filter(line -> !PERSONAL_LINE.matcher(line).find())
                .filter(line -> !POSTAL_LINE.matcher(line).matches())
                .filter(line -> !mentionsName(line, nameWords))
                .map(PersonalDataRedactor::redactValues)
                .collect(Collectors.joining("\n"));
    }

    private static String redactValues(String line) {
        String out = line;
        for (Pattern p : VALUES) {
            out = p.matcher(out).replaceAll(MASK);
        }
        return out;
    }

    private static boolean mentionsName(String line, List<String> nameWords) {
        if (nameWords.size() < 2) {
            return false;
        }
        long hits = List.of(fold(line).split("[^A-Z]+")).stream()
                .filter(nameWords::contains)
                .distinct()
                .count();
        return hits >= 2;
    }

    /** Mayúsculas sin tildes, para comparar nombres escritos de forma distinta. */
    static String fold(String s) {
        return Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "")
                .toUpperCase(Locale.ROOT);
    }
}
