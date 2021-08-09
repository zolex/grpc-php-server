ARG PHP_VERSION="8.0.9"

FROM php:${PHP_VERSION}-alpine

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG GRPC_VERSION="1.39.0"
ARG PROTOBUF_VERSION="3.17.3"

RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        cmake \
        make \
        autoconf \
        linux-headers \
        git \
        zlib-dev \
    && apk add go --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
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

COPY ./rr /roadrunner
RUN cd /roadrunner \
    && go get -t . \
    && go build -a -x -v -o rr \
    && mv rr /usr/local/bin/rr \
    && rm -rf /roadrunner

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["/usr/local/bin/rr", "serve", "-d", "-v"]
