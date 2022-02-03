FROM ubuntu:18.04

ENV composerVersion 1.7.2
ENV TZ=Europe/Paris
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get install -y -qq curl supervisor nginx git wget tzdata software-properties-common libxrender1
RUN apt-get install -y libcurl3
RUN apt-get install -y libjpeg-turbo8
RUN apt-get update -qq && apt-get install -y -qq ca-certificates apt-transport-https lsb-release
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN sh -c 'echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/php.list'
RUN echo "Europe/Paris" > /etc/timezone && ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime && dpkg-reconfigure -f noninteractive tzdata
# install php 7.1 & npm & pecl dependencies
RUN apt-get update -qq && apt-get install -y -qq  php7.1-cli php7.1-common php7.1-fpm php7.1-mysql php7.1-xml php7.1-bcmath \
    php7.1-mbstring php7.1-zip php7.1-xdebug php7.1-curl php-apcu php-ssh2 php7.1-soap php-imagick php7.1-intl php-pear
RUN apt install -y -qq php7.1-dev
#RUN apt install -y -qq php7.1-gd
RUN update-alternatives --set php /usr/bin/php7.1
RUN pecl install mongodb-1.2.7 \
    echo "extension=mongodb.so" > $PHP_INI_DIR/conf.d/mongo.ini

# install tools
RUN php -r "readfile('https://getcomposer.org/installer');" | php -- --version=${composerVersion} && mv composer.phar /usr/local/bin/composer
#RUN wget -O php-cs-fixer http://get.sensiolabs.org/php-cs-fixer.phar && chmod a+x php-cs-fixer && mv php-cs-fixer /usr/local/bin/php-cs-fixer

RUN apt-get install -y -qq npm rsync
# install bower & csscomb
RUN npm install --global bower csscomb

# Install wkhtmltox with deps
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 tar xf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 rsync -av wkhtmltox/* / && \
 chmod u+x /bin/wkhtmltoimage /bin/wkhtmltopdf && \
 rm wkhtmltox-0.12.3_linux-generic-amd64.tar.xz

# Configure runner
RUN sed -e 's/;daemonize = yes/daemonize = no/' -i /etc/php/7.1/fpm/php-fpm.conf \
    && sed -e 's/;listen\.owner/listen.owner/' -i /etc/php/7.1/fpm/pool.d/www.conf \
    && sed -e 's/;listen\.group/listen.group/' -i /etc/php/7.1/fpm/pool.d/www.conf \
    && sed -e 's/pm.max_children = 5/pm.max_children = 25/' -i /etc/php/7.1/fpm/pool.d/www.conf \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.1/fpm/php.ini \
    && sed -e 's/post_max_size = 8M/post_max_size = 30M/' -i /etc/php/7.1/fpm/php.ini \
    && sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 30M/' -i /etc/php/7.1/fpm/php.ini \
    && sed -e 's/memory_limit = 128M/memory_limit = 1024M/' -i /etc/php/7.1/fpm/php.ini \
    && sed -e 's/max_execution_time = 30/max_execution_time = 60/' -i /etc/php/7.1/fpm/php.ini \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.1/cli/php.ini \
    && echo "\ndaemon off;" >> /etc/nginx/nginx.conf

ADD supervisor/container.conf /etc/supervisor/container.conf
ADD supervisor/supervisord.conf /etc/supervisor/supervisord.conf

ADD nginx/nginx.conf /etc/nginx/nginx.conf
ADD nginx/nginx_prod.conf /etc/nginx/nginx_prod.conf

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"

RUN mkdir /run/php

VOLUME /var/www
WORKDIR /var/www/current

EXPOSE 80
EXPOSE 443

COPY start.sh /
RUN chmod +x /start.sh
CMD ["/start.sh"]
