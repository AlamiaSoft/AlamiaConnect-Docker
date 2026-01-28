CONTAINER_ID=$(docker ps -aqf "name=ac-php-apache")

docker exec -it ${CONTAINER_ID} bash
