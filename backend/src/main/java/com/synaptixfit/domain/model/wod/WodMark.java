package com.synaptixfit.domain.model.wod;

/**
 * Una marca con el WOD al que pertenece, para «Mis marcas».
 *
 * @param signature huella del WOD ({@link WodDefinition#signature()})
 * @param best      es la mejor de ese WOD en su división (lo decide el servidor)
 */
public record WodMark(WodResult result, String signature, String title, String templateCode, WodFormat format,
                      boolean best) {

    public WodMark asBest(boolean isBest) {
        return new WodMark(result, signature, title, templateCode, format, isBest);
    }
}
