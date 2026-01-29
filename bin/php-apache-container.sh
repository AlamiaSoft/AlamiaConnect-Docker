# container id
CONTAINER_ID=$(docker ps -aqf "name=alamiaconnect-php-apache")

docker exec -w /var/www/html/alamiaconnect -it ${CONTAINER_ID} bash
