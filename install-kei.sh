#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
╦╔═┌─┐┬
╠╩╗├┤ │
╩ ╩└─┘┴
EOF
echo -e "${NC}"
echo -e "${GREEN}Kei - Deployment Platform${NC}"
echo -e "${YELLOW}Modified version of Dokploy${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

echo -e "${BLUE}Installing Kei on $OS...${NC}"

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}Docker installed successfully${NC}"
else
    echo -e "${GREEN}Docker already installed${NC}"
fi

# Install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose installed successfully${NC}"
else
    echo -e "${GREEN}Docker Compose already installed${NC}"
fi

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p /etc/kei
mkdir -p /var/lib/kei

# Pull Kei Docker image (using dokploy image as base for now)
echo -e "${YELLOW}Pulling Kei Docker image...${NC}"
docker pull dokploy/dokploy:latest

# Create docker-compose.yml
echo -e "${YELLOW}Creating docker-compose configuration...${NC}"
cat > /etc/kei/docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  kei:
    image: dokploy/dokploy:latest
    container_name: kei
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/kei:/app/data
      - /etc/kei/.env:/app/.env
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - NODE_ENV=production
    depends_on:
      - postgres
      - redis
    networks:
      - kei-network

  postgres:
    image: postgres:16
    container_name: kei-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=kei
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-keipassword}
      - POSTGRES_DB=kei
    volumes:
      - kei-postgres-data:/var/lib/postgresql/data
    networks:
      - kei-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U kei"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: kei-redis
    restart: unless-stopped
    volumes:
      - kei-redis-data:/data
    networks:
      - kei-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  kei-postgres-data:
  kei-redis-data:

networks:
  kei-network:
    driver: bridge
COMPOSE_EOF

# Generate random password
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Create .env file
echo -e "${YELLOW}Creating environment configuration...${NC}"
cat > /etc/kei/.env << ENV_EOF
DATABASE_URL=postgres://kei:${POSTGRES_PASSWORD}@kei-postgres:5432/kei
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
NODE_ENV=production
PORT=3000
ENV_EOF

# Create systemd service
echo -e "${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/kei.service << 'SERVICE_EOF'
[Unit]
Description=Kei Deployment Platform
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/etc/kei
ExecStart=/usr/local/bin/docker-compose -f /etc/kei/docker-compose.yml up -d
ExecStop=/usr/local/bin/docker-compose -f /etc/kei/docker-compose.yml down
ExecReload=/usr/local/bin/docker-compose -f /etc/kei/docker-compose.yml restart

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable kei.service

# Start Kei
echo -e "${YELLOW}Starting Kei...${NC}"
cd /etc/kei
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 15

# Check if services are running
if docker ps | grep -q kei; then
    echo -e "${GREEN}✓ Kei is running!${NC}"
else
    echo -e "${RED}✗ Failed to start Kei${NC}"
    exit 1
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "localhost")

# Apply customizations (change organization name from "My Organization" to "Kei Organization")
echo -e "${YELLOW}Applying customizations...${NC}"
sleep 5
docker exec kei-postgres psql -U kei -d kei -c "UPDATE organization SET name = 'Kei Organization' WHERE name = 'My Organization';" 2>/dev/null || true

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Kei Installation Complete! 🎉${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Access Kei at:${NC}"
echo -e "  ${GREEN}http://${SERVER_IP}:3000${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Open the URL above in your browser"
echo -e "  2. Create your admin account"
echo -e "  3. Start deploying your applications!"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  View logs:      ${GREEN}docker logs -f kei${NC}"
echo -e "  Restart Kei:    ${GREEN}systemctl restart kei${NC}"
echo -e "  Stop Kei:       ${GREEN}systemctl stop kei${NC}"
echo -e "  Start Kei:      ${GREEN}systemctl start kei${NC}"
echo -e "  Update Kei:     ${GREEN}cd /etc/kei && docker-compose pull && docker-compose up -d${NC}"
echo ""
echo -e "${BLUE}Configuration files:${NC}"
echo -e "  Docker Compose: ${GREEN}/etc/kei/docker-compose.yml${NC}"
echo -e "  Environment:    ${GREEN}/etc/kei/.env${NC}"
echo -e "  Data:           ${GREEN}/var/lib/kei${NC}"
echo ""
echo -e "${YELLOW}Database credentials:${NC}"
echo -e "  Username: kei"
echo -e "  Password: ${POSTGRES_PASSWORD}"
echo -e "  Database: kei"
echo ""
echo -e "${GREEN}Thank you for using Kei! 🚀${NC}"
echo ""
