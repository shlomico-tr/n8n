#!/bin/bash

# n8n Cloudflare Deployment Setup Script
# סקריפט הגדרה אוטומטי לפריסת n8n עם Cloudflare

set -e

echo "======================================"
echo "  n8n Cloudflare Deployment Setup"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on server
if [ -f /etc/os-release ]; then
    echo -e "${GREEN}✓${NC} Running on Linux server"
else
    echo -e "${YELLOW}⚠${NC}  This script is designed for Linux servers"
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗${NC} Docker is not installed"
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}✓${NC} Docker installed"
else
    echo -e "${GREEN}✓${NC} Docker is installed"
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}⚠${NC}  Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✓${NC} Docker Compose installed"
else
    echo -e "${GREEN}✓${NC} Docker Compose is installed"
fi

echo ""
echo "======================================"
echo "  Configuration"
echo "======================================"
echo ""

# Get user input
read -p "GitHub username: " GITHUB_USERNAME
read -p "Your domain (e.g., n8n.yourdomain.com): " N8N_HOST
read -p "Cloudflare Tunnel Token: " CLOUDFLARE_TUNNEL_TOKEN
read -p "Timezone (default: Asia/Jerusalem): " TIMEZONE
TIMEZONE=${TIMEZONE:-Asia/Jerusalem}

# Generate encryption key
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

# Choose deployment type
echo ""
echo "Choose deployment type:"
echo "1) Simple (SQLite) - Good for testing/small usage"
echo "2) Production (PostgreSQL) - Recommended for production"
read -p "Enter choice [1-2]: " DEPLOYMENT_TYPE

# Create directory
INSTALL_DIR="$HOME/n8n-production"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

echo ""
echo -e "${YELLOW}Creating configuration files...${NC}"

# Create .env file
cat > .env << EOF
# GitHub Configuration
GITHUB_USERNAME=$GITHUB_USERNAME

# n8n Configuration
N8N_HOST=$N8N_HOST
WEBHOOK_URL=https://$N8N_HOST
TIMEZONE=$TIMEZONE

# Security
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY

# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_TOKEN=$CLOUDFLARE_TUNNEL_TOKEN
EOF

if [ "$DEPLOYMENT_TYPE" = "2" ]; then
    # Add PostgreSQL config
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    cat >> .env << EOF

# Database Configuration
DB_TYPE=postgresdb
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
EOF
fi

echo -e "${GREEN}✓${NC} .env file created"

# Create docker-compose.yml based on choice
if [ "$DEPLOYMENT_TYPE" = "1" ]; then
    echo "Creating simple docker-compose.yml (SQLite)..."
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: ghcr.io/${GITHUB_USERNAME}/n8n:latest
    restart: unless-stopped
    environment:
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=${TIMEZONE}
      - DB_TYPE=sqlite
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_AI_ENABLED=true
      - N8N_DIAGNOSTICS_ENABLED=false
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n-network

  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - n8n-network
    depends_on:
      - n8n

volumes:
  n8n_data:

networks:
  n8n-network:
EOF
else
    echo "Creating production docker-compose.yml (PostgreSQL)..."
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: ghcr.io/${GITHUB_USERNAME}/n8n:latest
    restart: unless-stopped
    environment:
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=${TIMEZONE}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_AI_ENABLED=true
      - N8N_DIAGNOSTICS_ENABLED=false
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - n8n-network

  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${POSTGRES_USER}']
      interval: 5s
      timeout: 5s
      retries: 10
    networks:
      - n8n-network

  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - n8n-network
    depends_on:
      - n8n

volumes:
  n8n_data:
  postgres_data:

networks:
  n8n-network:
EOF
fi

echo -e "${GREEN}✓${NC} docker-compose.yml created"

echo ""
echo "======================================"
echo "  Starting Services"
echo "======================================"
echo ""

# Start services
echo "Pulling Docker images..."
docker-compose pull

echo ""
echo "Starting containers..."
docker-compose up -d

echo ""
echo -e "${GREEN}✓${NC} Services started!"
echo ""

# Wait a bit
sleep 5

# Show status
echo "======================================"
echo "  Status"
echo "======================================"
docker-compose ps

echo ""
echo "======================================"
echo "  🎉 Setup Complete!"
echo "======================================"
echo ""
echo -e "${GREEN}n8n is now accessible at:${NC}"
echo -e "  ${YELLOW}https://$N8N_HOST${NC}"
echo ""
echo "Useful commands:"
echo "  View logs:    cd $INSTALL_DIR && docker-compose logs -f"
echo "  Restart:      cd $INSTALL_DIR && docker-compose restart"
echo "  Stop:         cd $INSTALL_DIR && docker-compose down"
echo "  Update:       cd $INSTALL_DIR && docker-compose pull && docker-compose up -d"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  Your encryption key is saved in $INSTALL_DIR/.env"
echo "  Keep this file safe! You'll need it to decrypt your credentials."
echo ""
echo -e "${GREEN}Happy automating! 🚀${NC}"

