ARG DEBIAN_FRONTEND=noninteractive

FROM ubuntu:latest AS build

ENV TZ=Europe/Prague

ENV PHP_VERSION=7.4
ENV PHP_ETC=/etc/php/${PHP_VERSION}
ENV PHP_MODS_DIR=${PHP_ETC}/mods-available
ENV PHP_CLI_DIR=${PHP_ETC}/cli
ENV PHP_CLI_CONF_DIR=${PHP_CLI_DIR}/conf.d
ENV PHP_FPM_DIR=${PHP_ETC}/fpm/
ENV PHP_FPM_CONF_DIR=${PHP_FPM_DIR}/conf.d
ENV PHP_FPM_POOL_DIR=${PHP_FPM_DIR}/pool.d

ENV DOCROOT=/srv/www
ENV COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN \
    # INSTALLATION
    apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    apt-get install -y --no-install-recommends \
        curl \
        nginx \
        cron \
        supervisor \
        msmtp \
        msmtp-mta \
        unzip \
        php${PHP_VERSION}-apcu \
        php${PHP_VERSION}-bz2 \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-mongo \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-ssh2 \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-xmlrpc \
        php${PHP_VERSION}-imagick && \
    rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/* \
    # PHP MOD(s) ###############################################################
    rm ${PHP_FPM_POOL_DIR}/www.conf && \
    # NGINX ####################################################################
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    # MSMTP ####################################################################
    ln -sf /dev/stdout /var/log/msmtp.log
    # CLEAN UP #################################################################
    #rm /etc/nginx/conf.d/default.conf

# PHP
ADD ./docker/php/php-fpm.conf ${PHP_FPM_DIR}/
# NGINX
ADD ./docker/nginx/* /etc/nginx/
ADD ./docker/nginx/sites.d /etc/nginx/sites.d/
# SUPERVISOR
ADD docker/supervisor/supervisord.conf /etc/supervisor/
ADD docker/supervisor/services /etc/supervisor/services/
# MSMTP
ADD ./docker/msmtp/msmtprc.template /etc/
ADD ./docker/msmtp/generate_msmtprc.sh /usr/sbin/
# ENTRY
#ADD ./docker/entry/fix_permissions.sh /usr/sbin/
#RUN chmod ug+rx /usr/sbin/fix_permissions.sh

ADD ./src /srv
ADD ./custom /root/custom

# APP
WORKDIR /srv
EXPOSE 80
CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisor/supervisord.conf"]

FROM build AS lib-tools
RUN \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
    composer global require "hirak/prestissimo:^0.3" && \
    # and install node
    apt-get update && \
    apt-get install -y --no-install-recommends \
        gpg-agent && \
    curl -sL https://deb.nodesource.com/setup_13.x | bash && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        nodejs \
        yarn \
        git \
        wget \
        bsdtar && \
    rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/* && \
    mkdir /srv/tmp && \
    chown www-data:www-data /srv/tmp

FROM lib-tools AS dev
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        php-xdebug \
        vim && \
    rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

FROM lib-tools AS libs
WORKDIR /root/custom/themes/kvetinysafari
RUN \
    yarn install && \
    yarn run gulp
WORKDIR /root/custom/themes/sperkysafari
RUN \
    yarn install && \
    yarn run gulp
WORKDIR /srv
RUN \
    composer install && \
    mkdir -p ${DOCROOT}/libraries/ && \
    wget -qO- https://use.fontawesome.com/releases/v5.7.2/fontawesome-free-5.7.2-web.zip | bsdtar -xvf- -C ${DOCROOT}/libraries/

FROM build AS prod
COPY --from=libs /srv ./
RUN rm -rf ./node_modules composer* package* yarn* /root/custom

FROM lib-tools AS depolyment
COPY --from=prod /srv ./
RUN mkdir deployment && \
    wget -O deployment/app.phar https://github.com/dg/ftp-deployment/releases/download/v3.3.0/deployment.phar
ADD ./docker/deployment/deployment.sh /srv
ADD ./docker/deployment/config.php /srv/deployment
