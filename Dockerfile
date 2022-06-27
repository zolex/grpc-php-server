ARG PHP_VERSION="8.1"

FROM ghcr.io/roadrunner-server/roadrunner:2.10.5 AS roadrunner

FROM php:${PHP_VERSION}-alpine

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG GRPC_VERSION="1.46.3"
ARG PROTOBUF_VERSION="3.21.1"

RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        cmake \
        make \
        autoconf \
        linux-headers \
        git \
        zlib-dev \
    && apk add go --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    && docker-php-ext-install sockets \
    && pecl install \
        protobuf-${PROTOBUF_VERSION} \
    && CPPFLAGS="-Wno-maybe-uninitialized" pecl install \
        grpc-${GRPC_VERSION} \
    && pecl clear-cache \
    && docker-php-ext-enable \
        grpc \
        protobuf \
    && apk del .build-deps

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

COPY --from=roadrunner /usr/bin/rr /usr/local/bin/rr

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["rr", "serve"]
