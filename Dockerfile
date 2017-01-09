FROM ubuntu:xenial

RUN echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN apt-get update -qq && apt-get install -y -qq curl supervisor nginx git wget
RUN apt-get update -qq && apt-get install -y -qq php7.0-cli php7.0-common php7.0-fpm php7.0-mysql php7.0-xml php7.0-bcmath php7.0-mbstring php7.0-zip php-xdebug php-curl php-apcu php-ssh2 php7.0-soap php-imagick php7.0-gd php7.0-intl

# install tools
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
RUN curl http://get.sensiolabs.org/php-cs-fixer.phar -o php-cs-fixer && chmod a+x php-cs-fixer && mv php-cs-fixer /usr/local/bin/php-cs-fixer

# install npm
RUN apt-get update -qq && apt-get install -y -qq npm
RUN ln -s /usr/bin/nodejs /usr/bin/node

# install bower
RUN npm install --global bower

# Install csscomb
RUN npm install --global csscomb

# Install wkhtmltox with deps
RUN wget http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 tar xf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 rsync -av wkhtmltox/* / && \
 chmod u+x /bin/wkhtmltoimage /bin/wkhtmltopdf
RUN apt-get update -qq && apt-get install -y -qq libxrender1

# Configure runner
RUN sed -e 's/;daemonize = yes/daemonize = no/' -i /etc/php/7.0/fpm/php-fpm.conf \
    && sed -e 's/;listen\.owner/listen.owner/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;listen\.group/listen.group/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/pm.max_children = 5/pm.max_children = 25/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/post_max_size = 8M/post_max_size = 30M/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 30M/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/memory_limit = 128M/memory_limit = 1024M/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/max_execution_time = 30/max_execution_time = 60/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.0/cli/php.ini \
    && echo "\ndaemon off;" >> /etc/nginx/nginx.conf

ADD supervisor/container.conf /etc/supervisor/container.conf
ADD supervisor/supervisord.conf /etc/supervisor/supervisord.conf

ADD nginx/vhost.conf /etc/nginx/sites-available/default

RUN mkdir /run/php

VOLUME /var/www
WORKDIR /var/www/current

EXPOSE 80

CMD ["/usr/bin/supervisord"]
