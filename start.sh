#!/bin/bash

if [ ! -z $PHPMAXCHILDREN ]
then
    sed -e 's/pm.max_children = 25/pm.max_children = '"$PHPMAXCHILDREN"'/' -i /etc/php/7.1/fpm/pool.d/www.conf
fi 

/usr/bin/supervisord
