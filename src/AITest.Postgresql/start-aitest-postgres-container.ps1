#Requires -Version 7
param(
    [string]$ImageName = "aitest-postgres-image",
    [string]$ContainerName = "aitest-postgres-container",
    [string]$VolumeName = "aitest-postgres-data",
    [int]$Port = 55432,
    [int]$PostgresUID = 1001,
    [string]$AllowedIP = "host.docker.internal"
)

Write-Host "[INFO] Checking if Docker image '$ImageName' exists..." -ForegroundColor Cyan
$ImageExists = @(docker image inspect $ImageName 2>&1)
if ($LASTEXITCODE -ne 0 -or $ImageExists.Count -eq 0) {
    Write-Host "[INFO] Building PostgreSQL image..." -ForegroundColor Yellow
    docker build --tag $ImageName --file Postgresql.Dockerfile .

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to build Docker image." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[INFO] Image '$ImageName' already exists, skipping build." -ForegroundColor Green
}

Write-Host "[INFO] Ensuring volume permissions are set correctly..." -ForegroundColor Cyan
docker run --rm `
    --entrypoint "" `
    --volume "${VolumeName}:/var/lib/postgresql/data" `
    --user root `
    $ImageName `
    chown -R ${PostgresUID}:${PostgresUID} /var/lib/postgresql/data

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to set volume permissions." -ForegroundColor Red
    exit 1
}

# Write-Host "[INFO] Checking if container '$ContainerName' is running..." -ForegroundColor Cyan
#$RunningContainer = docker ps -q -f "name=^${ContainerName}$"
#if ($RunningContainer) {
#    Write-Host "[INFO] Stopping running container '$ContainerName'..." -ForegroundColor Yellow
#    docker stop $ContainerName
#    if ($LASTEXITCODE -ne 0) {
#        Write-Host "[ERROR] Failed to stop container." -ForegroundColor Red
#        exit 1
#    }
#}

# Write-Host "[INFO] Removing any existing container with the same name..." -ForegroundColor Cyan
# $ContainerExists = docker ps -a -q -f "name=^${ContainerName}$"
# if ($ContainerExists) {
#    docker rm -f $ContainerName
#    if ($LASTEXITCODE -ne 0) {
#        Write-Host "[ERROR] Failed to remove container." -ForegroundColor Red
#        exit 1
#    }
#}

Write-Host "[INFO] Starting PostgreSQL container as non-root user..." -ForegroundColor Cyan
docker run --detach `
    --name $ContainerName `
    --env POSTGRES_HOST_AUTH_METHOD=trust `
    --env POSTGRES_USER=postgres `
    --env POSTGRES_DB=postgres `
    --env POSTGRES_PASSWORD=userpassword `
    --env ALLOW_IP_RANGE="${AllowedIP}" `
    --publish "127.0.0.1:${Port}:5432" `
    --volume "${VolumeName}:/var/lib/postgresql/data" `
    --add-host host.docker.internal:host-gateway `
    $ImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to start container." -ForegroundColor Red
    exit 1
}


Write-Host @"
[INFO] PostgreSQL is now running:
- Port: $Port
- Allowed connections from: $AllowedIP
- Running as UID: $PostgresUID
- Connection string: "Host=localhost;Port=$Port;Database=postgres;Username=postgres;Password=userpassword"
"@ -ForegroundColor Green