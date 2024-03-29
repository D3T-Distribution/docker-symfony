FROM ubuntu:xenial

# RUN echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN apt-get update -qq && apt-get install -y -qq curl supervisor nginx git wget
RUN apt-get update -qq && apt-get install -y -qq php7.0-cli php7.0-common php7.0-fpm php7.0-mysql php7.0-xml php7.0-bcmath php7.0-mbstring php7.0-zip php-curl php-apcu php-ssh2 php7.0-soap php-imagick php7.0-gd php7.0-intl

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
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 tar xf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz && \
 rsync -av wkhtmltox/* / && \
 chmod u+x /bin/wkhtmltoimage /bin/wkhtmltopdf && \
 rm wkhtmltox-0.12.3_linux-generic-amd64.tar.xz

RUN apt-get update -qq && apt-get install -y -qq libxrender1

# Configure runner
RUN sed -e 's/;daemonize = yes/daemonize = no/' -i /etc/php/7.0/fpm/php-fpm.conf \
    && sed -e 's/;listen\.owner/listen.owner/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;listen\.group/listen.group/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;pm = dynamic/pm = ondemand/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/pm.max_children = 5/pm.max_children = 500/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;pm.start_servers = 2/pm.start_servers = 64/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;pm.min_spare_servers = 1/pm.min_spare_servers = 10/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;pm.max_spare_servers = 3/pm.max_spare_servers = 128/' -i /etc/php/7.0/fpm/pool.d/www.conf \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/post_max_size = 8M/post_max_size = 30M/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/upload_max_filesize = 2M/upload_max_filesize = 30M/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/memory_limit = 128M/memory_limit = 1024M/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/max_execution_time = 30/max_execution_time = 60/' -i /etc/php/7.0/fpm/php.ini \
    && sed -e 's/;date\.timezone =/date\.timezone = Europe\/Paris/' -i /etc/php/7.0/cli/php.ini \
    && echo "\ndaemon off;" >> /etc/nginx/nginx.conf

ADD supervisor/container.conf /etc/supervisor/container.conf
ADD supervisor/supervisord.conf /etc/supervisor/supervisord.conf

ADD nginx/nginx.conf /etc/nginx/nginx.conf
ADD nginx/nginx_prod.conf /etc/nginx/nginx_prod.conf

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"

RUN mv /etc/ImageMagick-6/policy.xml /tmp/policy.xml && cat /tmp/policy.xml | sed "s/none/read|write/" > /etc/ImageMagick-6/policy.xml

RUN mkdir /run/php

VOLUME /var/www
WORKDIR /var/www/current

EXPOSE 80
EXPOSE 443

CMD ["/usr/bin/supervisord"]
