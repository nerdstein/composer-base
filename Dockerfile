FROM php:7.2-apache
MAINTAINER nerdstein <nerdstein@gmail.com>

ENV APACHE_DOCROOT /var/www/html/web
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data

#
# Install basic requirements
#
RUN apt-get update \
 && apt-get install -y \
 curl \
 apt-transport-https \
 git \
 build-essential \
 libssl-dev \
 wget \
 unzip \
 bzip2 \
 libbz2-dev \
 zlib1g-dev \
 mysql-client-* \
 libfontconfig \
 libfreetype6-dev \
 libjpeg62-turbo-dev \
 libpng-dev \
 libicu-dev \
 libxml2-dev \
 libldap2-dev \
 libmcrypt-dev \
 python-pip \
 fabric \
 jq \
 gnupg \
 nodejs \
 npm \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


#
# Install Node (with NPM), and Yarn (via package manager for Debian)
#
# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
RUN npm install -g yarn

#
# Install Composer and Drush
#
RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
 && composer --ansi --version --no-interaction 

#
# Install additional php extensions
#
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install -j$(nproc) \
      bcmath \
      bz2 \
      calendar \
      exif \
      ftp \
      gd \
      gettext \
      intl \
      ldap \
      mysqli \
      opcache \
      pcntl \
      pdo_mysql \
      shmop \
      soap \
      sockets \
      sysvmsg \
      sysvsem \
      sysvshm \
      zip \
    && pecl install redis apcu \
    && docker-php-ext-enable redis apcu

#
# PHP xdebug for phpunit code coverage report
#
RUN pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > $PHP_INI_DIR/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> $PHP_INI_DIR/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> $PHP_INI_DIR/conf.d/xdebug.ini


#
# PHP configuration
#
# Set timezone
RUN echo "date.timezone = \"America/New_York\"" > $PHP_INI_DIR/conf.d/timezone.ini
# Increase PHP memory limit
RUN echo "memory_limit=-1" > $PHP_INI_DIR/conf.d/timezone.ini
# Set upload limit
RUN echo "upload_max_filesize = 128M\npost_max_size = 128M" > $PHP_INI_DIR/conf.d/00-max_filesize.ini


#
# Apache configuration
#
RUN a2enmod rewrite headers expires ssl \
  && sed -i "/User www-data/c\User \$\{APACHE_RUN_USER\}" /etc/apache2/apache2.conf \
  && sed -i "/Group www-data/c\Group \$\{APACHE_RUN_GROUP\}" /etc/apache2/apache2.conf \
  && sed -i "/DocumentRoot \/var\/www\/html/c\\\tDocumentRoot \$\{APACHE_DOCROOT\}" /etc/apache2/sites-enabled/000-default.conf \
