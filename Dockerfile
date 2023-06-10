FROM composer:2 as composer
COPY app/composer.json composer.json
COPY app/composer.lock composer.lock
RUN composer install --ignore-platform-reqs --no-interaction --prefer-dist

FROM craftcms/nginx:8.1

USER root
RUN apk add --no-cache postgresql-client git
COPY .docker/default.conf /etc/nginx/conf.d/default.conf
USER www-data

COPY --chown=www-data:www-data app .
COPY --chown=www-data:www-data --from=composer /app/vendor/ ./vendor/
COPY --from=composer /usr/bin/composer /usr/bin/composer
