# The container, image, and volume names to be removed.
$containerName = "aitest-postgres-container"
$imageName = "aitest-postgres-image"
$volumeName = "aitest-postgres-data"


Write-Host "Stopping and removing container: $containerName"
if ($(docker ps -aq -f name=$containerName)) {
    docker rm -f $containerName
} else {
    Write-Host "Container $containerName does not exist."
}

Write-Host "Removing image: $imageName"
if ($(docker images -q $imageName)) {
    docker rmi -f $imageName
} else {
    Write-Host "Image $imageName does not exist."
}

Write-Host "Removing specific volume: $volumeName"
if ($(docker volume ls -q -f name=$volumeName)) {
    docker volume rm $volumeName
} else {
    Write-Host "Volume $volumeName does not exist."
}

Write-Host "Cleanup complete!"
