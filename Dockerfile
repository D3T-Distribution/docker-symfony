FROM ubuntu:xenial

RUN apt-get update -qq && apt-get install -y -qq curl supervisor nginx git wget tzdata software-properties-common python-software-properties libxrender1
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
# install php 7.4 & npm
RUN apt-get update -qq && apt-get install -y -qq php7.4-cli php7.4-common php7.4-fpm php7.4-mysql php7.4-xml php7.4-bcmath php7.4-mbstring php7.4-zip php7.4-xdebug php7.4-curl php-apcu php-ssh2 php7.4-soap php-imagick php7.4-gd php7.4-intl npm

# install tools
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
RUN curl http://get.sensiolabs.org/php-cs-fixer.phar -o php-cs-fixer && chmod a+x php-cs-fixer && mv php-cs-fixer /usr/local/bin/php-cs-fixer

# install bower, csscomb & robohydra
RUN ln -s /usr/bin/nodejs /usr/bin/node && npm install --global bower csscomb robohydra

ENV NODE_PATH=/usr/local/lib/node_modules

# Install wkhtmltox with deps
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 tar xf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 rsync -av wkhtmltox/* / && \
 chmod u+x /bin/wkhtmltoimage /bin/wkhtmltopdf && \
 rm wkhtmltox-0.12.3_linux-generic-amd64.tar.xz

# Configure runner
RUN sed -e 's/;daemonize = yes/daemonize = no/' -i /etc/php/7.4/fpm/php-fpm.conf \
    && sed -e 's/;listen\.owner/listen.owner/' -i /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -e 's/;listen\.group/listen.group/' -i /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -e 's/pm.max_children = 5/pm.max_children = 25/' -i /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.4/fpm/php.ini \
    && sed -e 's/post_max_size = 8M/post_max_size = 30M/' -i /etc/php/7.4/fpm/php.ini \
    && sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 30M/' -i /etc/php/7.4/fpm/php.ini \
    && sed -e 's/memory_limit = 128M/memory_limit = 1024M/' -i /etc/php/7.4/fpm/php.ini \
    && sed -e 's/max_execution_time = 30/max_execution_time = 60/' -i /etc/php/7.4/fpm/php.ini \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.4/cli/php.ini \
    && echo "\ndaemon off;" >> /etc/nginx/nginx.conf

ADD supervisor/container.conf /etc/supervisor/container.conf
ADD supervisor/supervisord.conf /etc/supervisor/supervisord.conf

ADD nginx/nginx.conf /etc/nginx/nginx.conf
ADD nginx/nginx_prod.conf /etc/nginx/nginx_prod.conf

RUN mkdir /run/php

VOLUME /var/www
WORKDIR /var/www/current

EXPOSE 80
EXPOSE 3000

CMD ["/usr/bin/supervisord"]
