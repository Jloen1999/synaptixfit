/// Fuera de la web no se usa: el móvil abre el canal con Dio, que sí entrega
/// la respuesta a trozos (ver `TogetherLiveRemoteDataSource`).
Stream<List<int>> fetchStream(Uri url, Map<String, String> headers) =>
    throw UnsupportedError('fetchStream solo existe en la web');
