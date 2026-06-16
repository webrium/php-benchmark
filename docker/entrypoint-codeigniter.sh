#!/bin/bash
set -e

cd /var/www/codeigniter

if [ ! -f "spark" ]; then
    echo ">>> Installing CodeIgniter 4..."
    composer create-project codeigniter4/appstarter . --prefer-dist --no-interaction
fi

chown -R www-data:www-data /var/www/codeigniter
chmod -R 755 /var/www/codeigniter
chmod -R 775 /var/www/codeigniter/writable

if [ ! -f ".env" ]; then
    cp env .env
fi

sed -i "s/# CI_ENVIRONMENT = production/CI_ENVIRONMENT = production/" .env

mkdir -p /run/php

echo ">>> Starting PHP-FPM..."
php-fpm8.2 -D

echo ">>> Starting Nginx on port 8003..."
nginx -g "daemon off;"
