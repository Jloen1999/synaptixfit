# Imagen del cliente web: compila Flutter y lo sirve con nginx, que además reenvía /api al backend.
# Así web y API comparten origen (un solo subdominio, sin CORS).
#
#   docker build -t synaptixfit-web --build-arg API_BASE_URL=https://synaptixfit.jloenit.dev \
#     --build-arg GOOGLE_CLIENT_ID=<id>.apps.googleusercontent.com frontend
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
ARG API_BASE_URL
ARG GOOGLE_CLIENT_ID=""
# Lo generado (freezed, json, traducciones) no se versiona: se regenera aquí.
RUN dart run build_runner build --delete-conflicting-outputs \
 && dart run tool/merge_arb.dart \
 && flutter gen-l10n \
 && flutter build web --release \
      --dart-define=API_BASE_URL=${API_BASE_URL} \
      --dart-define=GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}

FROM nginx:1.27-alpine
# La plantilla se resuelve al arrancar con envsubst (BACKEND_UPSTREAM, R2_UPSTREAM y MEDIA_UPSTREAM). Sin
# valor, envsubst dejaría «${R2_UPSTREAM}» literal y nginx no arrancaría: por defecto, un dominio que no
# resuelve (solo fallan /storage/ y /media/).
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html
ENV BACKEND_UPSTREAM=http://backend:8080 \
    R2_UPSTREAM=https://r2-no-configurado.invalid \
    MEDIA_UPSTREAM=https://r2-no-configurado.invalid
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://127.0.0.1/healthz || exit 1
