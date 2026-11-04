package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** No se pudo leer texto en las fotos (borrosas, oscuras o sin letra). */
public class NoteScanNothingFoundException extends BusinessRuleException {

    public NoteScanNothingFoundException() {
        super("NOTE_SCAN_NOTHING_FOUND", "No readable text was found in the photos");
    }
}
