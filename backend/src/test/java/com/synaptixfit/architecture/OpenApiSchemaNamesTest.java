package com.synaptixfit.architecture;

import static org.assertj.core.api.Assertions.assertThat;

import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

/**
 * springdoc nombra cada esquema OpenAPI con el nombre simple de la clase: dos DTOs con el mismo
 * nombre en módulos distintos se fusionan en uno y el contrato publicado queda mal. Este test exige
 * que cada nombre de esquema sea único (se desambigua con {@code @Schema(name = "...")}).
 */
class OpenApiSchemaNamesTest {

    @Test
    void restDtoSchemaNamesAreUnique() {
        List<JavaClass> dtos = new ClassFileImporter()
                .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
                .importPackages("com.synaptixfit.infrastructure.adapter.input.rest")
                .stream()
                .filter(c -> c.getPackageName().endsWith(".dto"))
                .filter(c -> c.isRecord() || c.isEnum())
                .toList();

        Map<String, List<String>> byName = dtos.stream().collect(Collectors.groupingBy(
                OpenApiSchemaNamesTest::schemaName,
                Collectors.mapping(JavaClass::getFullName, Collectors.toList())));

        Map<String, List<String>> duplicates = byName.entrySet().stream()
                .filter(e -> e.getValue().size() > 1)
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

        assertThat(duplicates).as("Esquemas OpenAPI con el mismo nombre").isEmpty();
    }

    private static String schemaName(JavaClass c) {
        return c.tryGetAnnotationOfType(Schema.class)
                .map(Schema::name)
                .filter(n -> !n.isBlank())
                .orElse(c.getSimpleName());
    }
}
