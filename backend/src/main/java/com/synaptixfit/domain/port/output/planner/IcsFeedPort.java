package com.synaptixfit.domain.port.output.planner;

import java.net.URI;

/** Descarga un calendario ICS remoto. Lanza IcsFeedUnavailableException si falla. */
public interface IcsFeedPort {

    String download(URI url);
}
