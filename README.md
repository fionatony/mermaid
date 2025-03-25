# Mermaid Diagram Generation Service

A Dockerized service that generates Mermaid diagrams via URL requests.

## Prerequisites

- Docker Desktop for Windows 10 or Docker for Linux
- Internet connection for pulling Docker images

## Quick Start for Windows

### One-Click Setup (PowerShell)

You can set up and run the Mermaid service with a single command in PowerShell:

```powershell
irm "https://raw.githubusercontent.com/fionatony/mermaid/main/start.ps1" | iex
```

This script will:
1. Check if Docker is running
2. Clone the repository
3. Build the Docker image
4. Start the container
5. Open your default browser with a sample diagram

### Manual Setup

1. Clone the Mermaid repository:

```bash
git clone https://github.com/fionatony/mermaid
```
2.  Navigate into the mermaid directory:
```bash
cd mermaid
```

3. Build the Docker image:
```bash
docker build -t mermaid-service .
```

4. Run the container:
```bash
docker run -d -p 7777:7777 --name mermaid-container mermaid-service
```

5. Verify the container is running: To check if the container is up and running, use:
```bash
docker ps
```
6. Access the Mermaid Server
Open your browser and navigate to the following URL:
```bash
http://localhost:7777/render?code=graph TD; A-->B; A-->C; B-->D; C-->D;
```
This will render a simple Mermaid diagram. You can modify the code parameter to render different diagrams.

## Usage

Generate a diagram by sending a GET request to:
```
http://localhost:7777/render?code=YOUR_MERMAID_CODE_HERE
```

Example URL:
```
http://localhost:7777/render?code=graph TD; A-->B; A-->C; B-->D; C-->D;
```

## API Endpoints

- `GET /render?code=<mermaid-code>`: Generates and returns a PNG image of the Mermaid diagram
- `GET /health`: Health check endpoint

## Managing the Container

- Stop the container:
```bash
docker stop mermaid-container
```

- Remove the container:
```bash
docker rm mermaid-container
```

## Troubleshooting

If you encounter any issues:

1. Check if the container is running:
```bash
docker ps
```

2. View container logs:
```bash
docker logs mermaid-container
```

## Notes

- The service runs on port 7777
- Temporary files are automatically cleaned up after each request
- CORS is enabled for all origins 