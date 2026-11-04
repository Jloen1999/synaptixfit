# Imagen del backend: compilación con Maven y ejecución con JRE 21.
FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN ./mvnw -B -q dependency:go-offline
COPY src src
RUN ./mvnw -B -q package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
# Tesseract lee el texto de las fotos de apuntes (ADR 0040); DeepSeek solo entiende texto.
# Diccionarios de los idiomas de la app: español, inglés, francés y portugués.
RUN apt-get update \
    && apt-get install -y --no-install-recommends tesseract-ocr tesseract-ocr-spa tesseract-ocr-eng \
       tesseract-ocr-fra tesseract-ocr-por \
    && rm -rf /var/lib/apt/lists/*
RUN useradd --system --uid 1001 app
COPY --from=build /workspace/target/*.jar app.jar
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3   CMD curl -fsS http://127.0.0.1:8080/actuator/health || exit 1
# Memoria según el límite del contenedor; si se agota, el proceso termina y Docker lo reinicia
# en lugar de quedarse colgado.
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-XX:+ExitOnOutOfMemoryError", "-jar", "app.jar"]
