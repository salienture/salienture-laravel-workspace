FROM dunglas/frankenphp:1-php8.5-bookworm

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Common Laravel extensions
RUN install-php-extensions \
    pdo_mysql \
    mysqli \
    intl \
    zip \
    gd \
    opcache \
    redis \
    bcmath \
    pcntl \
    exif

COPY Caddyfile /etc/caddy/Caddyfile

WORKDIR /app

EXPOSE 80 443 443/udp

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
