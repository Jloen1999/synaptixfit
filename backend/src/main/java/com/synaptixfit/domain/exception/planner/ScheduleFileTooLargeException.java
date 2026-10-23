package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El archivo del horario supera 10 MB. */
public class ScheduleFileTooLargeException extends InvalidInputException {

    public ScheduleFileTooLargeException() {
        super("SCHEDULE_FILE_TOO_LARGE", "The file exceeds 10 MB");
    }
}
