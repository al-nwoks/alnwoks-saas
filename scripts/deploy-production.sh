#!/bin/bash

# ALNWOKS Production Deployment Script
# This script handles production deployment with security and monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
COMPOSE_PROD_FILE="$PROJECT_ROOT/docker-compose.prod.yml"

# Production configuration
DOMAIN=${DOMAIN:-"alnwoks.com"}
EMAIL=${EMAIL:-"admin@alnwoks.com"}
ENVIRONMENT=${ENVIRONMENT:-"production"}

echo -e "${BLUE}🚀 ALNWOKS Production Deployment Manager${NC}"
echo "=================================================="

# Function to print status messages
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if running as root (required for production)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is required for production deployment."
    else
        print_error "Production deployment requires root privileges. Please run with sudo."
        exit 1
    fi
}

# Check production dependencies
check_production_dependencies() {
    echo -e "${BLUE}Checking production dependencies...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker from https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    # Check for required environment variables
    if [ -z "$DOMAIN" ]; then
        print_error "DOMAIN environment variable is required for production deployment"
        exit 1
    fi
    
    print_status "All production dependencies are available"
}

# Create production environment file
create_production_env() {
    echo -e "${BLUE}Creating production environment configuration...${NC}"
    
    local env_file="$PROJECT_ROOT/.env.production"
    
    cat > "$env_file" << EOF
# ALNWOKS Production Environment Configuration
ENVIRONMENT=production
DOMAIN=$DOMAIN
EMAIL=$EMAIL

# Database Configuration
POSTGRES_DB=alnwoks_prod
POSTGRES_USER=alnwoks
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Redis Configuration
REDIS_PASSWORD=$(openssl rand -base64 32)

# Security
JWT_SECRET=$(openssl rand -base64 64)
SESSION_SECRET=$(openssl rand -base64 64)

# SSL/TLS
LETSENCRYPT_EMAIL=$EMAIL

# Monitoring
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 16)

# Backup
BACKUP_ENCRYPTION_KEY=$(openssl rand -base64 32)

# Generated on: $(date)
EOF

    chmod 600 "$env_file"
    print_status "Production environment file created: $env_file"
}

# Create production docker-compose override
create_production_compose() {
    echo -e "${BLUE}Creating production Docker Compose configuration...${NC}"
    
    cat > "$COMPOSE_PROD_FILE" << EOF
version: '3.8'

services:
  frontend:
    restart: unless-stopped
    environment:
      - NODE_ENV=production
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(\`$DOMAIN\`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.routers.frontend.tls.certresolver=letsencrypt"
      - "traefik.http.services.frontend.loadbalancer.server.port=80"
    networks:
      - alnwoks-network
      - traefik-network

  postgres:
    restart: unless-stopped
    volumes:
      - postgres_data_prod:/var/lib/postgresql/data
      - ./backups:/backups
    environment:
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}

  redis:
    restart: unless-stopped
    command: redis-server --requirepass \${REDIS_PASSWORD}
    volumes:
      - redis_data_prod:/data

  traefik:
    image: traefik:v2.10
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.email=\${LETSENCRYPT_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--log.level=INFO"
      - "--accesslog=true"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - letsencrypt_data:/letsencrypt
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(\`traefik.$DOMAIN\`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik.service=api@internal"
    networks:
      - traefik-network

  prometheus:
    restart: unless-stopped
    volumes:
      - prometheus_data_prod:/prometheus

  grafana:
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=\${GRAFANA_ADMIN_PASSWORD}
      - GF_SERVER_DOMAIN=grafana.$DOMAIN
      - GF_SERVER_ROOT_URL=https://grafana.$DOMAIN
    volumes:
      - grafana_data_prod:/var/lib/grafana
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(\`grafana.$DOMAIN\`)"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.tls.certresolver=letsencrypt"

volumes:
  postgres_data_prod:
    driver: local
  redis_data_prod:
    driver: local
  prometheus_data_prod:
    driver: local
  grafana_data_prod:
    driver: local
  letsencrypt_data:
    driver: local

networks:
  traefik-network:
    external: true
EOF

    print_status "Production Docker Compose configuration created"
}

# Setup firewall rules
setup_firewall() {
    echo -e "${BLUE}Setting up firewall rules...${NC}"
    
    # Install ufw if not present
    if ! command -v ufw &> /dev/null; then
        apt-get update && apt-get install -y ufw
    fi
    
    # Reset firewall
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow Docker daemon (if needed)
    ufw allow 2376/tcp
    
    # Enable firewall
    ufw --force enable
    
    print_status "Firewall configured"
}

# Setup log rotation
setup_log_rotation() {
    echo -e "${BLUE}Setting up log rotation...${NC}"
    
    cat > /etc/logrotate.d/alnwoks << EOF
/var/lib/docker/containers/*/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    copytruncate
    maxsize 100M
}
EOF

    print_status "Log rotation configured"
}

# Create backup script
create_backup_script() {
    echo -e "${BLUE}Creating backup script...${NC}"
    
    cat > "$PROJECT_ROOT/scripts/backup-production.sh" << 'EOF'
#!/bin/bash

# ALNWOKS Production Backup Script

set -e

BACKUP_DIR="/opt/alnwoks/backups"
DATE=$(date +%Y%m%d_%H%M%S)
COMPOSE_CMD="docker-compose -f docker-compose.yml -f docker-compose.prod.yml"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting backup process..."

# Backup database
echo "Backing up PostgreSQL database..."
$COMPOSE_CMD exec -T postgres pg_dump -U alnwoks alnwoks_prod | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"

# Backup Redis
echo "Backing up Redis data..."
$COMPOSE_CMD exec -T redis redis-cli --rdb /data/dump.rdb
docker cp $(docker-compose ps -q redis):/data/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"

# Backup application files
echo "Backing up application files..."
tar -czf "$BACKUP_DIR/app_files_$DATE.tar.gz" -C /opt/alnwoks --exclude=backups .

# Cleanup old backups (keep last 7 days)
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.rdb" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR"
EOF

    chmod +x "$PROJECT_ROOT/scripts/backup-production.sh"
    
    # Setup cron job for daily backups
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/alnwoks/scripts/backup-production.sh") | crontab -
    
    print_status "Backup script created and scheduled"
}

# Deploy to production
deploy_production() {
    echo -e "${BLUE}Deploying ALNWOKS to production...${NC}"
    
    local compose_cmd="docker-compose -f $COMPOSE_FILE -f $COMPOSE_PROD_FILE"
    
    cd "$PROJECT_ROOT"
    
    # Create external network for Traefik
    docker network create traefik-network 2>/dev/null || true
    
    # Pull latest images
    print_info "Pulling latest Docker images..."
    $compose_cmd pull
    
    # Build custom images
    print_info "Building custom images..."
    $compose_cmd build
    
    # Start services
    print_info "Starting production services..."
    $compose_cmd --env-file .env.production up -d
    
    # Wait for services to be ready
    print_info "Waiting for services to be ready..."
    sleep 30
    
    # Run health checks
    run_production_health_checks
    
    print_status "Production deployment completed successfully"
    show_production_urls
}

# Run production health checks
run_production_health_checks() {
    echo -e "${BLUE}Running production health checks...${NC}"
    
    local compose_cmd="docker-compose -f $COMPOSE_FILE -f $COMPOSE_PROD_FILE"
    
    # Check frontend
    if curl -f -s https://$DOMAIN/health > /dev/null 2>&1; then
        print_status "Frontend is healthy"
    else
        print_warning "Frontend health check failed"
    fi
    
    # Check database
    if $compose_cmd exec postgres pg_isready -U alnwoks > /dev/null 2>&1; then
        print_status "PostgreSQL is healthy"
    else
        print_warning "PostgreSQL health check failed"
    fi
    
    # Check Redis
    if $compose_cmd exec redis redis-cli ping > /dev/null 2>&1; then
        print_status "Redis is healthy"
    else
        print_warning "Redis health check failed"
    fi
}

# Show production URLs
show_production_urls() {
    echo ""
    echo -e "${GREEN}🌐 Production URLs:${NC}"
    echo "  Main Site:    https://$DOMAIN"
    echo "  Health Check: https://$DOMAIN/health"
    echo "  Grafana:      https://grafana.$DOMAIN"
    echo "  Traefik:      https://traefik.$DOMAIN"
    echo ""
    echo -e "${YELLOW}📋 Important Notes:${NC}"
    echo "  - SSL certificates will be automatically generated by Let's Encrypt"
    echo "  - Monitor logs with: docker-compose logs -f"
    echo "  - Backups are scheduled daily at 2 AM"
    echo "  - Environment file: .env.production (keep secure!)"
    echo ""
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup      Setup production environment (run once)"
    echo "  deploy     Deploy application to production"
    echo "  update     Update running production deployment"
    echo "  backup     Run manual backup"
    echo "  logs       Show production logs"
    echo "  status     Show production status"
    echo "  rollback   Rollback to previous version"
    echo ""
    echo "Environment Variables:"
    echo "  DOMAIN     Production domain (default: alnwoks.com)"
    echo "  EMAIL      Admin email for SSL certificates"
    echo ""
    echo "Examples:"
    echo "  DOMAIN=alnwoks.com EMAIL=admin@alnwoks.com $0 setup"
    echo "  $0 deploy"
    echo "  $0 logs"
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case $command in
        "setup")
            check_root
            check_production_dependencies
            create_production_env
            create_production_compose
            setup_firewall
            setup_log_rotation
            create_backup_script
            print_status "Production environment setup completed"
            ;;
        "deploy")
            check_root
            check_production_dependencies
            deploy_production
            ;;
        "update")
            check_root
            check_production_dependencies
            deploy_production
            ;;
        "backup")
            "$PROJECT_ROOT/scripts/backup-production.sh"
            ;;
        "logs")
            docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_PROD_FILE" logs -f
            ;;
        "status")
            docker-compose -f "$COMPOSE_FILE" -f "$COMPOSE_PROD_FILE" ps
            run_production_health_checks
            ;;
        "rollback")
            print_warning "Rollback functionality not implemented yet"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Operation interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"