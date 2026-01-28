CONTAINER_ID=$(docker ps -aqf "name=ac-mysql")

docker exec -it ${CONTAINER_ID} bash
