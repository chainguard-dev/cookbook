FROM cgr.dev/chainguard-private/php:8.3-dev AS build-env

USER root

WORKDIR /app

COPY . .

# Install composer dependencies
RUN composer install --no-dev --optimize-autoloader

FROM cgr.dev/chainguard-private/php:8.3-dev

ENV HOST=0.0.0.0
ENV PORT=8080

WORKDIR /app

COPY --from=build-env --chown=65532:65532 /app .

USER 65532
EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "index.php"]
