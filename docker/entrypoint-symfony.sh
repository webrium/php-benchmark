#!/bin/bash
set -e

cd /var/www/symfony

if [ ! -f "bin/console" ]; then
    echo ">>> Installing Symfony..."
    composer create-project symfony/skeleton . --prefer-dist --no-interaction
    composer require symfony/twig-bundle twig/twig --no-interaction
    composer require symfony/framework-bundle --no-interaction
fi

chown -R www-data:www-data /var/www/symfony
chmod -R 755 /var/www/symfony
chmod -R 775 /var/www/symfony/var

if [ ! -f ".env.local" ]; then
    echo "APP_ENV=prod" > .env.local
    echo "APP_DEBUG=0" >> .env.local
fi

composer dump-autoload --optimize --quiet

mkdir -p /run/php

echo ">>> Starting PHP-FPM..."
php-fpm8.2 -D

echo ">>> Starting Nginx on port 8004..."
nginx -g "daemon off;"
