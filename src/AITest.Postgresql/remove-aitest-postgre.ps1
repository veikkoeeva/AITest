# Define the container name and image name
$containerName = "aitest-postgres-container"
$imageName = "aitest-postgres-image"

Write-Host "Stopping and removing container: $containerName"
# Force stop and remove the container if it exists
if ($(docker ps -aq -f name=$containerName)) {
    docker rm -f $containerName
} else {
    Write-Host "Container $containerName does not exist."
}

Write-Host "Removing image: $imageName"
# Remove the image if it exists
if ($(docker images -q $imageName)) {
    docker rmi -f $imageName
} else {
    Write-Host "Image $imageName does not exist."
}

Write-Host "Removing all unused volumes..."
# Remove unused volumes (including those possibly attached to this container)
docker volume prune -f

Write-Host "Cleanup complete!"
