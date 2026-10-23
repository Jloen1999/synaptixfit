package com.synaptixfit.domain.model.analytics;

import java.util.List;

/** Estadística básica para la analítica. */
public final class Statistics {

    private Statistics() {
    }

    /**
     * Coeficiente de correlación de Pearson. Devuelve null si hay menos de 2 pares o si alguna de
     * las variables no varía (correlación indefinida; la app antigua devolvía 0, que se leía como
     * "sin relación" aunque no hubiera información).
     */
    public static Double pearson(List<Double> x, List<Double> y) {
        if (x.size() != y.size() || x.size() < 2) {
            return null;
        }
        int n = x.size();
        double meanX = x.stream().mapToDouble(Double::doubleValue).average().orElse(0);
        double meanY = y.stream().mapToDouble(Double::doubleValue).average().orElse(0);
        double sxy = 0;
        double sxx = 0;
        double syy = 0;
        for (int i = 0; i < n; i++) {
            double dx = x.get(i) - meanX;
            double dy = y.get(i) - meanY;
            sxy += dx * dy;
            sxx += dx * dx;
            syy += dy * dy;
        }
        if (sxx == 0 || syy == 0) {
            return null;
        }
        double r = sxy / Math.sqrt(sxx * syy);
        return Math.max(-1, Math.min(1, r));
    }

    /** Pendiente de la recta de mínimos cuadrados; null con menos de 2 puntos o x constante. */
    public static Double slope(List<Double> x, List<Double> y) {
        if (x.size() != y.size() || x.size() < 2) {
            return null;
        }
        double meanX = x.stream().mapToDouble(Double::doubleValue).average().orElse(0);
        double meanY = y.stream().mapToDouble(Double::doubleValue).average().orElse(0);
        double sxy = 0;
        double sxx = 0;
        for (int i = 0; i < x.size(); i++) {
            double dx = x.get(i) - meanX;
            sxy += dx * (y.get(i) - meanY);
            sxx += dx * dx;
        }
        return sxx == 0 ? null : sxy / sxx;
    }
}
