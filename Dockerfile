# Use Node.js LTS 
FROM node:18-slim

# Install Chrome dependencies and Google Chrome
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
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
    && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm -rf google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies globally
RUN npm install && npm install -g @mermaid-js/mermaid-cli@10.6.1

# Copy application files
COPY . .

# Create temp directory for diagram generation with proper permissions
RUN mkdir -p temp && chmod 777 temp

# Create a wrapper script for mmdc
RUN echo '#!/bin/bash\n\
    export PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable\n\
    mmdc --puppeteerConfigFile /app/mmdc-puppeteer-config.json "$@"' > /usr/local/bin/mmdc-wrapper && \
    chmod +x /usr/local/bin/mmdc-wrapper

# Create puppeteer config file for mmdc
RUN echo '{\n\
    "args": ["--no-sandbox", "--disable-dev-shm-usage"]\n\
    }' > /app/mmdc-puppeteer-config.json

# Set environment variables for Puppeteer and Chrome
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable \
    PUPPETEER_NO_SANDBOX=true \
    CHROME_BIN=/usr/bin/google-chrome-stable \
    CHROME_PATH=/usr/bin/google-chrome-stable \
    PUPPETEER_ARGS="--no-sandbox,--disable-dev-shm-usage"

# Expose port
EXPOSE 7777

# Start the server
CMD ["node", "server.js"] 