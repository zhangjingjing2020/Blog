FROM php:7.2-fpm-alpine3.9

MAINTAINER jackylee92@139.com

ADD tarsp /usr/local/bin
ADD composer /usr/local/bin
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN set -ex \
    && docker-php-source extract \
    # install autoconf
    && apk update \
    && apk add --no-cache autoconf gcc g++ make  libmcrypt-dev  libpng-dev freetype-dev libjpeg-turbo-dev  gettext-dev  libxml2-dev librdkafka-dev unzip \
    && php -v \
        && cd /tmp \
        && curl -SL "https://github.com/swoole/swoole-src/archive/v4.3.6.zip" -o swoole.zip \  
        && curl -SL "https://github.com/phpredis/phpredis/archive/develop.zip" -o redis.zip \
        && curl -SL "https://github.com/TarsPHP/tars-extension/archive/master.zip" -o tars.zip \
        && curl -SL "https://github.com/alexeyrybak/blitz/archive/php7.zip" -o blitz.zip \
        && curl -SL "https://github.com/laruence/yaf/archive/yaf-3.0.7.zip" -o yaf.zip \
        && curl -SL "https://phar.phpunit.de/phpunit-8.0.0.phar" -o phpunit.phar \
        && curl -SL "https://github.com/arnaud-lb/php-rdkafka/archive/4.0.3.zip" -o rdkafka.zip \
        # php extension: redis
        && unzip redis.zip \
        && rm redis.zip \
                && ( \
                    cd phpredis-develop \
                    && phpize \
                    && ./configure \
                    && make && make install \
                ) \
        && docker-php-ext-enable redis \
        # php extension: swoole
        && cd /tmp \
        && unzip swoole.zip \
        && rm swoole.zip \
                && ( \
                    cd swoole-src-4.3.6 \
                    && phpize \
                    && ./configure  \
                    && make && make install \
                ) \
       && docker-php-ext-enable swoole \
       # php extension: tars
       && cd /tmp \
       && unzip tars.zip \
       && rm tars.zip \
                && ( \
                    cd tars-extension-master \
                    && phpize \
                    && ./configure \
                    && make && make install \
                ) \
       && docker-php-ext-enable phptars \
       # php extension: blitz 
       && cd /tmp \
       && unzip blitz.zip \
       && rm blitz.zip \
                && ( \
                    cd blitz-php7 \
                    && phpize \
                    && ./configure  \
                    && make && make install \
                ) \
       && docker-php-ext-enable blitz \
       # php extension: yaf 
       && cd /tmp \
       && unzip yaf.zip \
       && rm yaf.zip \
                && ( \
                    cd yaf-yaf-3.0.7 \
                    && phpize \
                    && ./configure  \
                    && make && make install \
                ) \
       && docker-php-ext-enable yaf \
       # php extension: gd
       && pecl install mcrypt-1.0.3\ 
       && docker-php-ext-enable mcrypt \ 
       && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/  \
       && docker-php-ext-install -j$(nproc) gd \
       && docker-php-ext-enable gd \
       # php extension: mysqli
       && docker-php-ext-install bcmath sockets calendar gettext soap zip xmlrpc mysqli \
       && docker-php-ext-enable mysqli \
       # php extension: rdkafka
       && cd /tmp \
       && unzip rdkafka.zip \
       && rm rdkafka.zip \
                && ( \
                    cd php-rdkafka-4.0.3 \
                    && phpize \
                    && ./configure \
                    && make && make install \
                ) \
       && pecl install rdkafka \
       && docker-php-ext-enable rdkafka \
       && php -m \
       # php phpunit 
       && cd /tmp \
       && chmod u+x phpunit.phar \
       && chmod u+x /usr/local/bin/tarsp \
       && mv phpunit.phar /usr/local/bin/phpunit \
       # composer
       && chmod u+x /usr/local/bin/composer \
       && mkdir -p /local/Package \
       && ln -s /usr/share/nginx/html /local/Code \
       && mkdir -p /etc/dev \
