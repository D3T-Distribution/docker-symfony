FROM ubuntu:xenial

RUN apt-get update && apt-get install -y curl php7.0-cli php7.0-common php7.0-fpm php7.0-mysql php7.0-xml php-xdebug supervisor nginx

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

RUN sed -e 's/;daemonize = yes/daemonize = no/' -i /etc/php/7.0/fpm/php-fpm.conf \
    && sed -e 's/;listen\.owner/listen.owner/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;listen\.group/listen.group/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && echo "\ndaemon off;" >> /etc/nginx/nginx.conf

ADD supervisor.conf /etc/supervisor/conf.d/supervisor.conf
ADD vhost.conf /etc/nginx/sites-available/default

RUN mkdir /run/php
RUN usermod -u 1000 www-data

VOLUME /var/www
WORKDIR /var/www

EXPOSE 80

CMD ["/usr/bin/supervisord"]
