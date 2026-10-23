package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El horario debe ser un PDF o una imagen. */
public class UnsupportedScheduleFileException extends InvalidInputException {

    public UnsupportedScheduleFileException() {
        super("SCHEDULE_UNSUPPORTED_FILE", "Only PDF or image files are supported");
    }
}
