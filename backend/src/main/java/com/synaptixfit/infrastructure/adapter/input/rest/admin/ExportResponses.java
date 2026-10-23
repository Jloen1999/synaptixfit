package com.synaptixfit.infrastructure.adapter.input.rest.admin;

import com.synaptixfit.domain.model.privacy.UserDataExport;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

/** Respuesta de descarga de una exportación RGPD (JSON adjunto). */
public final class ExportResponses {

    private ExportResponses() {
    }

    public static ResponseEntity<String> attachment(UserDataExport export) {
        LocalDate day = LocalDate.ofInstant(export.exportedAt(), ZoneOffset.UTC);
        String filename = "synaptixfit-datos-" + export.userId() + "-" + day + ".json";
        return ResponseEntity.ok()
                .contentType(new MediaType(MediaType.APPLICATION_JSON, StandardCharsets.UTF_8))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(filename).build().toString())
                .body(export.json());
    }
}
