# Mermaid Service Setup Script for Windows
# This script automates the setup and running of the Mermaid diagram service

# Define variables
$repoUrl = "https://github.com/fionatony/mermaid"
$repoName = "mermaid"
$containerName = "mermaid-container"
$serviceName = "mermaid-service"
$port = "7777"
$url = "http://localhost:$port/render?code=graph TD; A-->B; A-->C; B-->D; C-->D;"

Write-Host "=== Mermaid Service Setup Script ==="
Write-Host "Starting setup process..."

# Check if Docker is installed and running
try {
    $dockerStatus = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Docker is not running. Please start Docker Desktop and try again."
        Exit 1
    }
    Write-Host "✓ Docker is running"
} catch {
    Write-Host "Error: Docker not found. Please install Docker Desktop for Windows and try again."
    Exit 1
}

# Clone the Mermaid repository
if (-Not (Test-Path $repoName)) {
    Write-Host "Cloning Mermaid repository..."
    git clone $repoUrl
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to clone repository. Check your internet connection and try again."
        Exit 1
    }
    Write-Host "✓ Repository cloned successfully"
} else {
    Write-Host "✓ Repository already exists. Skipping clone."
}

# Navigate into the mermaid directory
Set-Location $repoName
Write-Host "✓ Changed directory to $repoName"

# Build the Docker image
Write-Host "Building Docker image (this may take a few minutes)..."
docker build -t $serviceName .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build Docker image."
    Exit 1
}
Write-Host "✓ Docker image built successfully"

# Check if container already exists and remove it
$containerExists = docker ps -a --filter "name=$containerName" --format "{{.Names}}"
if ($containerExists) {
    Write-Host "Container already exists. Removing it..."
    docker rm -f $containerName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to remove existing container."
        Exit 1
    }
    Write-Host "✓ Existing container removed"
}

# Run the container
Write-Host "Starting container..."
docker run -d -p $port`:$port --name $containerName $serviceName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to start the container."
    Exit 1
}
Write-Host "✓ Container started successfully"

# Wait a few seconds to allow the container to start
Write-Host "Waiting for service to initialize..."
Start-Sleep -Seconds 5

# Verify the container is running
$containerStatus = docker ps --filter "name=$containerName" --format "{{.Status}}"
if ($containerStatus) {
    Write-Host "✓ Container is running: $containerStatus"
} else {
    Write-Host "Error: Container failed to start."
    Exit 1
}

# Properly encode the URL to handle spaces and special characters
$encodedUrl = [System.Web.HttpUtility]::UrlPathEncode($url)

# Open browser to access Mermaid server
Write-Host "Opening browser to test the service..."
try {
    # Add reference to System.Web for URL encoding
    Add-Type -AssemblyName System.Web
    
    # Try Chrome first
    Start-Process "chrome.exe" -ArgumentList "`"$url`"" -ErrorAction Stop
} catch {
    try {
        # Try Edge as fallback
        Start-Process "msedge.exe" -ArgumentList "`"$url`"" -ErrorAction Stop
    } catch {
        try {
            # Try Firefox as second fallback
            Start-Process "firefox.exe" -ArgumentList "`"$url`"" -ErrorAction Stop
        } catch {
            # If all browsers fail, just show the URL
            Write-Host "Could not automatically open a browser. Please manually navigate to:"
            Write-Host $url
        }
    }
}

Write-Host ""
Write-Host "=== Setup Complete ==="
Write-Host "Mermaid Service is running at http://localhost:$port"
Write-Host "Example URL: $url"
Write-Host ""
Write-Host "To stop the service, run: docker stop $containerName"
Write-Host "To start it again, run: docker start $containerName"
Write-Host "" 