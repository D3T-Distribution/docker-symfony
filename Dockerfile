FROM ubuntu:xenial

RUN echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN apt-get update -qq && apt-get install -y -qq curl supervisor nginx git wget
RUN apt-get update -qq && apt-get install -y -qq php7.0-cli php7.0-common php7.0-fpm php7.0-mysql php7.0-xml php7.0-bcmath php7.0-mbstring php7.0-zip php-xdebug php-curl php-apcu php-ssh2 php7.0-soap
RUN apt-get update -qq && apt-get install -y -qq wkhtmltopdf xvfb

# install tools
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
RUN curl http://get.sensiolabs.org/php-cs-fixer.phar -o php-cs-fixer && chmod a+x php-cs-fixer && mv php-cs-fixer /usr/local/bin/php-cs-fixer

# install npm
RUN apt-get update -qq && apt-get install -y -qq npm
RUN ln -s /usr/bin/nodejs /usr/bin/node

# install bower
RUN npm install --global bower

# Configure runner
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
