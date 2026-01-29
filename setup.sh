docker-compose down -v
rm -rf workspace/alamiaconnect

# building and running docker-compose file
docker-compose build && docker-compose up -d

# container id by image name
apache_container_id=$(docker ps -aqf "name=alamiaconnect-php-apache")
db_container_id=$(docker ps -aqf "name=alamiaconnect-mysql")

# checking connection
echo "Please wait... Waiting for MySQL connection..."
while ! docker exec ${db_container_id} mysql --user=root --password=root -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done

# creating empty database for alamiaconnect
echo "Creating empty database for alamiaconnect..."
while ! docker exec ${db_container_id} mysql --user=root --password=root -e "CREATE DATABASE IF NOT EXISTS alamiaconnect CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >/dev/null 2>&1; do
    sleep 1
done

# creating empty database for alamiaconnect testing
echo "Creating empty database for alamiaconnect testing..."
while ! docker exec ${db_container_id} mysql --user=root --password=root -e "CREATE DATABASE IF NOT EXISTS alamiaconnect_testing CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >/dev/null 2>&1; do
    sleep 1
done

# setting up alamiaconnect
echo "Now, setting up AlamiaConnect..."
if docker exec ${apache_container_id} git clone https://github.com/AlamiaSoft/AlamiaConnect-Backend alamiaconnect; then
    echo "Successfully cloned AlamiaConnect-Backend."
else
    echo "ERROR: Failed to clone repository. Please check if the URL is correct and public, or if you need to provide credentials."
    exit 1
fi


# installing composer dependencies inside container
echo "Now, setting up AlamiaConnect stable version..."
docker exec -i ${apache_container_id} bash -c "cd alamiaconnect && composer install"

# moving `.env` file
docker cp .configs/.env ${apache_container_id}:/var/www/html/alamiaconnect/.env
docker cp .configs/.env.testing ${apache_container_id}:/var/www/html/alamiaconnect/.env.testing

# executing final commands
docker exec -i ${apache_container_id} sh -c "cd alamiaconnect && composer install && npm install --legacy-peer-deps && npm run build && cd packages/Alamia/Admin && npm install && npm run build && cd ../../../ && php artisan optimize:clear && php artisan alamia:install-auto --force && php artisan storage:link && php artisan vendor:publish --provider='Webkul\\Core\\Providers\\CoreServiceProvider' --force && php artisan optimize:clear"
