#!/bin/bash

if [ ! -f "vendor/autoload.php" ]; then
    composer install -no-progress --no-interaction
fi

if [ ! -f ".env" ]; then
    echo "Creating env file for env $APP_ENV"
    cp .env.example .env
else
    echo "env file exists."
fi

role=${CONTAINER_ROLE:-app}

if [ "$role" = "app" ]; then
    php artisan key:generate
    php artisan optimize:clear
    php artisan migrate
    php artisan serve --port=$PORT --host=0.0.0.0 --env=.env
    exec docker-php-entrypoint "$@"

elif [ "$role" = "queue" ]; then
    echo "Running the queue..."
    php /var/www/artisan queue:work --verbose --tries=3 --timeout=18
    
elif [ "$role" = "websocket" ]; then
    echo "Running the websocket server..."

    composer require beyondcode/laravel-websockets
    php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="migrations"
    php artisan migrate
    php artisan vendor:publish --provider="BeyondCode\LaravelWebSockets\WebSocketsServiceProvider" --tag="config"

    # php artisan websockets:serve
fi

