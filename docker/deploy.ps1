# MaNGOS WotLK - Docker Deployment Script for Windows
# PowerShell script for managing Docker Compose deployment

param(
    [Parameter(Position=0)]
    [ValidateSet("up", "down", "restart", "logs", "status", "clean", "build")]
    [string]$Command = "up"
)

Write-Host "MaNGOS WotLK - Deployment Script" -ForegroundColor Green
Write-Host "================================================"

# Set working directory to project root
$ProjectRoot = Join-Path $PSScriptRoot ".."
Set-Location -Path $ProjectRoot

# Check for .env file
if (-not (Test-Path ".env")) {
    Write-Host "Warning: .env file not found" -ForegroundColor Yellow
    Write-Host "Creating .env from .env.example..."
    Copy-Item ".env.example" ".env"
    Write-Host "Please edit .env file with your configuration" -ForegroundColor Yellow
    Read-Host "Press Enter to continue or Ctrl+C to abort"
}

switch ($Command) {
    "up" {
        Write-Host "Starting MaNGOS services..." -ForegroundColor Blue
        docker-compose -f docker-compose.windows.yml up -d
        Write-Host ""
        Write-Host "Services started successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Access points:"
        Write-Host "  - Realmd: localhost:3724"
        Write-Host "  - Mangosd: localhost:8085"
        Write-Host "  - MySQL: localhost:3306"
        Write-Host "  - phpMyAdmin: http://localhost:8080 (use --profile tools)"
        Write-Host ""
        Write-Host "Check logs with: docker-compose -f docker-compose.windows.yml logs -f"
    }

    "down" {
        Write-Host "Stopping MaNGOS services..." -ForegroundColor Blue
        docker-compose -f docker-compose.windows.yml down
        Write-Host "Services stopped" -ForegroundColor Green
    }

    "restart" {
        Write-Host "Restarting MaNGOS services..." -ForegroundColor Blue
        docker-compose -f docker-compose.windows.yml restart
        Write-Host "Services restarted" -ForegroundColor Green
    }

    "logs" {
        Write-Host "Showing logs..." -ForegroundColor Blue
        docker-compose -f docker-compose.windows.yml logs -f
    }

    "status" {
        Write-Host "Service status:" -ForegroundColor Blue
        docker-compose -f docker-compose.windows.yml ps
    }

    "clean" {
        Write-Host "Warning: This will remove all containers, volumes, and data!" -ForegroundColor Red
        $confirmation = Read-Host "Are you sure? (yes/no)"
        if ($confirmation -eq "yes") {
            Write-Host "Cleaning up..." -ForegroundColor Blue
            docker-compose -f docker-compose.windows.yml down -v
            Write-Host "Cleanup complete" -ForegroundColor Green
        } else {
            Write-Host "Cancelled"
        }
    }

    "build" {
        Write-Host "Building images..." -ForegroundColor Blue
        & (Join-Path $PSScriptRoot "build.ps1")
    }

    default {
        Write-Host "Usage: .\deploy.ps1 {up|down|restart|logs|status|clean|build}"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  up      - Start all services"
        Write-Host "  down    - Stop all services"
        Write-Host "  restart - Restart all services"
        Write-Host "  logs    - Show service logs"
        Write-Host "  status  - Show service status"
        Write-Host "  clean   - Remove all containers and volumes"
        Write-Host "  build   - Build Docker images"
    }
}
