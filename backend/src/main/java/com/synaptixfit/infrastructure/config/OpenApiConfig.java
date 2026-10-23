package com.synaptixfit.infrastructure.config;

import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springdoc.core.utils.SpringDocUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Metadatos de la especificación OpenAPI generada por springdoc. */
@Configuration
public class OpenApiConfig {

    static {
        // El id del usuario sale del JWT: no es un parámetro de la API.
        SpringDocUtils.getConfig().addAnnotationsToIgnore(CurrentUserId.class);
    }

    @Bean
    OpenAPI synaptixfitOpenApi() {
        return new OpenAPI()
                .info(new Info().title("SynaptixFit API").version("v1")
                        .description("Bienestar académico y físico para estudiantes universitarios. "
                                + "Errores en formato RFC 9457 con el campo code (docs/03-api/errors.md)."))
                .components(new Components().addSecuritySchemes("bearer",
                        new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme("bearer").bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList("bearer"));
    }
}
