#!/bin/bash
set -e

# Instalar Docker
apt-get update
apt-get install -y docker.io docker-compose
systemctl start docker
systemctl enable docker

# Criar docker-compose.yml
cat > /home/ubuntu/docker-compose.yml <<'EOF'
version: '3.8'

services:
  kong:
    image: kong:3.5
    environment:
      KONG_DATABASE: "off"
      KONG_PROXY_LISTEN: "0.0.0.0:8000"
      KONG_ADMIN_LISTEN: "0.0.0.0:8001"
      KONG_DECLARATIVE_CONFIG: /kong/kong.yml
    ports:
      - "8000:8000"
      - "8001:8001"
    volumes:
      - ./kong.yml:/kong/kong.yml
    restart: always

  app:
    image: ${app_image}
    environment:
      NODE_ENV: production
      NEON_DATABASE_URL: "${neon_database_url}"
      JWT_SECRET: "${jwt_secret}"
      NEW_RELIC_LICENSE_KEY: "${newrelic_license_key}"
      NEW_RELIC_APP_NAME: "Oficina Mecanica API"
    ports:
      - "3000:3000"
    restart: always
    depends_on:
      - kong
EOF

# Criar configuração do Kong
cat > /home/ubuntu/kong.yml <<'EOF'
_format_version: "3.0"

services:
  - name: oficina-app
    url: http://app:3000
    routes:
      - name: app-route
        paths:
          - /
EOF

# Iniciar containers
cd /home/ubuntu
docker-compose pull
docker-compose up -d

# Log de inicialização
echo "Docker Compose iniciado em $(date)" > /var/log/user-data.log
