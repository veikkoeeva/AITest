#Requires -Version 7
param(
    [string]$ImageName = "aitest-postgres-image",
    [string]$ContainerName = "aitest-postgres-container",
    [string]$VolumeName = "aitest-postgres-data",
    [int]$Port = 55432,
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

$PostgresUID = $(docker run --rm --entrypoint "" $ImageName id -u postgres)
Write-Host "[INFO] PostgreSQL is running as UID $PostgresUID"

$ExistingContainer = docker ps -aq -f name=$ContainerName
if ($ExistingContainer) {
    $IsRunning = docker ps -q -f name=$ContainerName

    if ($IsRunning) {
        Write-Host "[INFO] Container '$ContainerName' is already running." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Container '$ContainerName' exists but is stopped. Restarting..." -ForegroundColor Yellow
        docker start $ContainerName

        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to restart the container." -ForegroundColor Red
            exit 1
        }

        Write-Host "[INFO] Container '$ContainerName' restarted successfully." -ForegroundColor Green
    }
} else {
    Write-Host "[INFO] Starting new PostgreSQL container as non-root user..." -ForegroundColor Cyan
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
        Write-Host "[ERROR] Failed to start the container." -ForegroundColor Red
        exit 1
    }

    Write-Host "[INFO] New container '$ContainerName' started successfully." -ForegroundColor Green
}

Write-Host @"
[INFO] PostgreSQL is now running:
- Port: $Port
- Allowed connections from: $AllowedIP
- Running as UID: $PostgresUID
- Connection string: "Host=localhost;Port=$Port;Database=postgres;Username=postgres;Password=userpassword"
"@ -ForegroundColor Green
