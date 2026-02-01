# MaNGOS WotLK - Docker Build Script for Windows
# PowerShell script for building multi-architecture images

param(
    [string]$Platform = "linux/amd64,linux/arm64",
    [switch]$Push = $false
)

Write-Host "MaNGOS WotLK - Docker Build Script" -ForegroundColor Green
Write-Host "================================================"

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker is not installed" -ForegroundColor Red
    exit 1
}

# Check if buildx is available
$buildxVersion = docker buildx version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker Buildx is not available" -ForegroundColor Red
    exit 1
}

Write-Host "Build configuration:"
Write-Host "  Platform: $Platform"
Write-Host "  Push to registry: $Push"
Write-Host ""

# Create builder if it doesn't exist
$builderExists = docker buildx inspect mangos-builder 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating new buildx builder..." -ForegroundColor Yellow
    docker buildx create --name mangos-builder --use
    docker buildx inspect --bootstrap
} else {
    Write-Host "Using existing buildx builder" -ForegroundColor Green
    docker buildx use mangos-builder
}

# Set working directory to project root
Set-Location -Path (Join-Path $PSScriptRoot "..")

# Build realmd
Write-Host "`nBuilding realmd image..." -ForegroundColor Green
$buildArgs = @(
    "buildx", "build",
    "--platform", $Platform,
    "--target", "realmd",
    "--tag", "mangos-wotlk:realmd"
)
if ($Push) {
    $buildArgs += "--push"
    $buildArgs += "--tag"
    $buildArgs += "your-registry/mangos-wotlk:realmd"
}
$buildArgs += "-f"
$buildArgs += "Dockerfile"
$buildArgs += "."

& docker $buildArgs

# Build mangosd
Write-Host "`nBuilding mangosd image..." -ForegroundColor Green
$buildArgs = @(
    "buildx", "build",
    "--platform", $Platform,
    "--target", "mangosd",
    "--tag", "mangos-wotlk:mangosd"
)
if ($Push) {
    $buildArgs += "--push"
    $buildArgs += "--tag"
    $buildArgs += "your-registry/mangos-wotlk:mangosd"
}
$buildArgs += "-f"
$buildArgs += "Dockerfile"
$buildArgs += "."

& docker $buildArgs

# Build extractors
Write-Host "`nBuilding extractors image..." -ForegroundColor Green
$buildArgs = @(
    "buildx", "build",
    "--platform", $Platform,
    "--target", "extractors",
    "--tag", "mangos-wotlk:extractors"
)
if ($Push) {
    $buildArgs += "--push"
    $buildArgs += "--tag"
    $buildArgs += "your-registry/mangos-wotlk:extractors"
}
$buildArgs += "-f"
$buildArgs += "Dockerfile"
$buildArgs += "."

& docker $buildArgs

Write-Host "`nBuild completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Available images:"
Write-Host "  - mangos-wotlk:realmd"
Write-Host "  - mangos-wotlk:mangosd"
Write-Host "  - mangos-wotlk:extractors"
Write-Host ""
Write-Host "To run the stack, use: docker-compose -f docker-compose.windows.yml up -d"
