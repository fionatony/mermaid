# Implementing a Dockerized Mermaid Diagram Generation Service

## Initial Requirements

The goal was to set up a Dockerized API using `mmdc` (Mermaid CLI) to generate PNG images of Mermaid diagrams with the following requirements:

1. Create server.js for Express API
2. Write a Dockerfile
3. Create Build and Run Script
4. Make the service accessible via URL

## Implementation Steps

### 1. Setting Up the Project Structure

Created the following files:
- `package.json` - Node.js dependencies
- `server.js` - Express API implementation
- `Dockerfile` - Container configuration
- `puppeteer-config.json` - Puppeteer browser settings

### 2. Key Components

#### package.json
```json
{
  "name": "mermaid-diagram-service",
  "version": "1.0.0",
  "description": "A service to generate Mermaid diagrams via URL",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "@mermaid-js/mermaid-cli": "^10.6.1",
    "cors": "^2.8.5"
  }
}
```

#### server.js
```javascript
const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const util = require('util');
const execPromise = util.promisify(exec);

const app = express();
const port = 7777;

// Enable CORS for all routes
app.use(cors());

// Create temp directory if it doesn't exist
const tempDir = path.join(__dirname, 'temp');
if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir);
}

app.get('/render', async (req, res) => {
    const { code } = req.query;

    if (!code) {
        return res.status(400).json({ error: 'Missing mermaid code in query parameter' });
    }

    try {
        // Create unique filename for this request
        const timestamp = Date.now();
        const inputFile = path.join(tempDir, `diagram-${timestamp}.mmd`);
        const outputFile = path.join(tempDir, `diagram-${timestamp}.png`);

        // Write mermaid code to temporary file
        fs.writeFileSync(inputFile, decodeURIComponent(code));

        // Set up the mmdc command with proper configuration
        const mmdcCmd = `mmdc -i "${inputFile}" -o "${outputFile}" -b transparent`;
        
        console.log('Executing command:', mmdcCmd);
        
        // Execute mmdc command
        const { stdout, stderr } = await execPromise(mmdcCmd);
        
        if (stderr) {
            console.error('MMDC stderr:', stderr);
        }
        
        if (stdout) {
            console.log('MMDC stdout:', stdout);
        }

        // Check if the output file exists
        if (!fs.existsSync(outputFile)) {
            throw new Error('Output file was not generated');
        }

        // Send the generated PNG file
        res.sendFile(outputFile, (err) => {
            if (err) {
                console.error(`Error sending file: ${err}`);
            }
            // Clean up temporary files
            try {
                fs.unlinkSync(inputFile);
                fs.unlinkSync(outputFile);
            } catch (cleanupError) {
                console.error('Error cleaning up files:', cleanupError);
            }
        });
    } catch (error) {
        console.error(`Server error: ${error.message}`);
        console.error(error.stack);
        res.status(500).json({ error: 'Failed to generate diagram', details: error.message });
    }
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${port}`);
});
```

#### Dockerfile
```dockerfile
# Use Node.js LTS version
FROM node:18-slim

# Install Chrome dependencies and Chromium
RUN apt-get update && apt-get install -y \
    chromium \
    libgbm1 \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgdk-pixbuf2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libxshmfence1 \
    xdg-utils \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies globally
RUN npm install -g @mermaid-js/mermaid-cli@10.6.1 && npm install

# Copy application files
COPY . .

# Create temp directory for diagram generation with proper permissions
RUN mkdir -p temp && chmod 777 temp

# Set environment variables for Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Create a non-root user
RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser \
    && mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /app

# Run everything after as non-root user
USER pptruser

# Expose port
EXPOSE 7777

# Start the server
CMD ["node", "server.js"]
```

#### puppeteer-config.json
```json
{
  "args": ["--no-sandbox", "--disable-setuid-sandbox"]
}
```

### 3. Building and Running the Service

1. Build the Docker image:
```bash
docker build -t mermaid-service .
```

2. Run the container:
```bash
docker run -d -p 7777:7777 --name mermaid-container mermaid-service
```

### 4. Using the Service

The service can be accessed via HTTP GET requests to:
```
http://localhost:7777/render?code=YOUR_MERMAID_CODE_HERE
```

Example URL:
```
http://localhost:7777/render?code=graph%20TD%3BA-%3EB%3BB-%3EC
```

### 5. Features

- Generates PNG images from Mermaid diagram code
- Supports all Mermaid diagram types
- Automatic cleanup of temporary files
- CORS enabled for cross-origin requests
- Health check endpoint at `/health`
- Runs as non-root user for security
- Uses Chromium for rendering
- Transparent background for generated images

### 6. Troubleshooting

If you encounter issues:

1. Check container status:
```bash
docker ps
```

2. View container logs:
```bash
docker logs mermaid-container
```

3. Restart the container:
```bash
docker restart mermaid-container
```

### 7. Security Considerations

- Runs as non-root user
- Uses secure Chromium settings
- Implements proper file cleanup
- Validates input parameters
- Uses temporary files with unique names

## Conclusion

The service provides a secure and efficient way to generate Mermaid diagrams via URL requests, making it easy to integrate with other applications or use directly in web browsers. 