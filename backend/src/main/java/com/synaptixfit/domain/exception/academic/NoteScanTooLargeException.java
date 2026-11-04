package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Una foto supera 10 MB o todas juntas superan 20 MB. */
public class NoteScanTooLargeException extends InvalidInputException {

    public NoteScanTooLargeException() {
        super("NOTE_SCAN_TOO_LARGE", "Each photo can be up to 10 MB and all together up to 20 MB");
    }
}
