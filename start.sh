#!/bin/bash

# Mermaid Service Setup Script for Linux
# This script automates the setup and running of the Mermaid diagram service

# Define variables
REPO_URL="https://github.com/fionatony/mermaid"
REPO_NAME="mermaid"
CONTAINER_NAME="mermaid-container"
SERVICE_NAME="mermaid-service"
PORT="7777"
URL="http://localhost:$PORT/render?code=graph TD; A-->B; A-->C; B-->D; C-->D;"

echo "=== Mermaid Service Setup Script ==="
echo "Starting setup process..."

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found. Please install Docker and try again."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi
echo "✓ Docker is running"

# Clone the Mermaid repository
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning Mermaid repository..."
    git clone "$REPO_URL"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone repository. Check your internet connection and try again."
        exit 1
    fi
    echo "✓ Repository cloned successfully"
else
    echo "✓ Repository already exists. Skipping clone."
fi

# Navigate into the mermaid directory
cd "$REPO_NAME"
echo "✓ Changed directory to $REPO_NAME"

# Build the Docker image
echo "Building Docker image (this may take a few minutes)..."
docker build -t "$SERVICE_NAME" .
if [ $? -ne 0 ]; then
    echo "Error: Failed to build Docker image."
    exit 1
fi
echo "✓ Docker image built successfully"

# Check if container already exists and remove it
if docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
    echo "Container already exists. Removing it..."
    docker rm -f "$CONTAINER_NAME"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to remove existing container."
        exit 1
    fi
    echo "✓ Existing container removed"
fi

# Run the container
echo "Starting container..."
docker run -d -p "$PORT:$PORT" --name "$CONTAINER_NAME" "$SERVICE_NAME"
if [ $? -ne 0 ]; then
    echo "Error: Failed to start the container."
    exit 1
fi
echo "✓ Container started successfully"

# Wait a few seconds to allow the container to start
echo "Waiting for service to initialize..."
sleep 5

# Verify the container is running
if docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}" | grep -q "Up"; then
    CONTAINER_STATUS=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}")
    echo "✓ Container is running: $CONTAINER_STATUS"
else
    echo "Error: Container failed to start."
    exit 1
fi

# Encode URL for browser opening
ENCODED_URL=$(echo "$URL" | sed 's/ /%20/g')

# Open browser to access Mermaid server
echo "Opening browser to test the service..."
if command -v xdg-open &> /dev/null; then
    # For most Linux distributions
    xdg-open "$ENCODED_URL"
elif command -v gnome-open &> /dev/null; then
    # For GNOME
    gnome-open "$ENCODED_URL"
elif command -v kde-open &> /dev/null; then
    # For KDE
    kde-open "$ENCODED_URL"
else
    # If no browser opener found
    echo "Could not automatically open a browser. Please manually navigate to:"
    echo "$URL"
fi

echo ""
echo "=== Setup Complete ==="
echo "Mermaid Service is running at http://localhost:$PORT"
echo "Example URL: $URL"
echo ""
echo "To stop the service, run: docker stop $CONTAINER_NAME"
echo "To start it again, run: docker start $CONTAINER_NAME"
echo "" 