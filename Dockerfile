FROM ubuntu:xenial

RUN apt-get update -qq && apt-get install -y -qq curl supervisor nginx git wget tzdata software-properties-common python-software-properties libxrender1
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
# install php 7.2 & npm
RUN apt-get update -qq && apt-get install -y -qq php7.2-cli php7.2-common php7.2-fpm php7.2-mysql php7.2-xml php7.2-bcmath php7.2-mbstring php7.2-zip php7.2-xdebug php7.2-curl php-apcu php-ssh2 php7.2-soap php-imagick php7.2-gd php7.2-intl npm
RUN ln -s /usr/bin/nodejs /usr/bin/node

# install tools
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
RUN curl http://get.sensiolabs.org/php-cs-fixer.phar -o php-cs-fixer && chmod a+x php-cs-fixer && mv php-cs-fixer /usr/local/bin/php-cs-fixer

# install bower & csscomb
RUN npm install --global bower csscomb

# Install wkhtmltox with deps
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 tar xf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 rsync -av wkhtmltox/* / && \
 chmod u+x /bin/wkhtmltoimage /bin/wkhtmltopdf && \
 rm wkhtmltox-0.12.3_linux-generic-amd64.tar.xz

# Configure runner
RUN sed -e 's/;daemonize = yes/daemonize = no/' -i /etc/php/7.2/fpm/php-fpm.conf \
    && sed -e 's/;listen\.owner/listen.owner/' -i /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -e 's/;listen\.group/listen.group/' -i /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -e 's/pm.max_children = 5/pm.max_children = 25/' -i /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.2/fpm/php.ini \
    && sed -e 's/post_max_size = 8M/post_max_size = 30M/' -i /etc/php/7.2/fpm/php.ini \
    && sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 30M/' -i /etc/php/7.2/fpm/php.ini \
    && sed -e 's/memory_limit = 128M/memory_limit = 1024M/' -i /etc/php/7.2/fpm/php.ini \
    && sed -e 's/max_execution_time = 30/max_execution_time = 60/' -i /etc/php/7.2/fpm/php.ini \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.2/cli/php.ini \
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
