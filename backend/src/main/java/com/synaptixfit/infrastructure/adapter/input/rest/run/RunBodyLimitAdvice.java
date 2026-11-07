package com.synaptixfit.infrastructure.adapter.input.rest.run;

import com.synaptixfit.domain.exception.run.RunRouteTooLargeException;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpInputMessage;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.RequestBodyAdviceAdapter;

/**
 * Límite de {@link RunController#MAX_BODY_BYTES} al subir una carrera, también cuando la petición no trae
 * {@code Content-Length} (envío por trozos): lee como mucho un byte más del límite antes de que Jackson la convierta y,
 * si se pasa, responde {@code RUN_ROUTE_TOO_LARGE} sin haber cargado el resto en memoria.
 */
@ControllerAdvice(assignableTypes = RunController.class)
public class RunBodyLimitAdvice extends RequestBodyAdviceAdapter {

    @Override
    public boolean supports(MethodParameter parameter, Type targetType,
                            Class<? extends HttpMessageConverter<?>> converterType) {
        return targetType == RunController.RunRecordRequest.class;
    }

    @Override
    public HttpInputMessage beforeBodyRead(HttpInputMessage input, MethodParameter parameter, Type targetType,
                                           Class<? extends HttpMessageConverter<?>> converterType) throws IOException {
        long declared = input.getHeaders().getContentLength();
        if (declared > RunController.MAX_BODY_BYTES) {
            throw new RunRouteTooLargeException();
        }
        byte[] body = readAtMost(input.getBody(), RunController.MAX_BODY_BYTES);
        HttpHeaders headers = input.getHeaders();
        return new HttpInputMessage() {
            @Override
            public InputStream getBody() {
                return new ByteArrayInputStream(body);
            }

            @Override
            public HttpHeaders getHeaders() {
                return headers;
            }
        };
    }

    /** Lee el cuerpo entero si cabe en {@code max} bytes; si no, lanza {@link RunRouteTooLargeException}. */
    static byte[] readAtMost(InputStream in, long max) throws IOException {
        byte[] read = in.readNBytes((int) max + 1);
        if (read.length > max) {
            throw new RunRouteTooLargeException();
        }
        return read;
    }
}
