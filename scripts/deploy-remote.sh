#!/bin/bash

# ALNWOKS Remote Server Deployment Script
# This script automates deployment to a remote server using SSH

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SSH_KEY="${HOME}/Documents/alnwoks/openwebui-llm-pipeline/terraform/hetzner_openwebui_key"
REMOTE_HOST="88.198.218.93"
REMOTE_USER="root"
REMOTE_PATH="/opt/alnwoks"
DOMAIN=${DOMAIN:-"alnwoks.com"}
EMAIL=${EMAIL:-"al@alnwoks.com"}

echo "🚀 ALNWOKS Remote Deployment Automation"
echo "=================================================="
echo "Target Server: ${REMOTE_USER}@${REMOTE_HOST}"
echo "Remote Path: ${REMOTE_PATH}"
echo "Domain: ${DOMAIN}"
echo ""

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY" ]; then
        echo "ERROR: SSH key not found: $SSH_KEY"
        exit 1
    fi
    
    # Check SSH key permissions
    chmod 600 "$SSH_KEY" 2>/dev/null || true
    
    # Check if required tools are available
    for tool in ssh scp tar; do
        if ! command -v $tool &> /dev/null; then
            echo "ERROR: $tool is required but not installed"
            exit 1
        fi
    done
    
    # Test SSH connection
    echo "Testing SSH connection..."
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH connection successful'" &> /dev/null; then
        echo "ERROR: Cannot connect to remote server"
        echo "  - SSH key: $SSH_KEY"
        echo "  - Server: $REMOTE_USER@$REMOTE_HOST"
        exit 1
    fi
    
    echo "✓ All prerequisites met"
}

# Create deployment package
create_deployment_package() {
    local temp_dir=$(mktemp -d)
    local package_name="alnwoks-deployment-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    echo "Creating deployment package..."
    
    cd "$PROJECT_ROOT"
    
    # Create package structure
    mkdir -p "$temp_dir/alnwoks"
    
    # Copy files
    echo "  - Copying frontend files..."
    cp -r frontend/ "$temp_dir/alnwoks/" 2>/dev/null
    
    echo "  - Copying deployment scripts..."
    cp -r scripts/ "$temp_dir/alnwoks/" 2>/dev/null
    
    echo "  - Copying Docker configuration..."
    cp docker-compose.yml "$temp_dir/alnwoks/" 2>/dev/null
    
    # Create deployment info file
    cat > "$temp_dir/alnwoks/deployment-info.txt" << EOF
ALNWOKS Deployment Package
==========================
Created: $(date)
Version: $(git rev-parse HEAD 2>/dev/null || echo "unknown")
Domain: $DOMAIN
Email: $EMAIL
Deployed by: $(whoami)
Source: $(hostname)
EOF
    
    # Create the package
    cd "$temp_dir"
    tar -czf "$PROJECT_ROOT/$package_name" alnwoks/ >/dev/null 2>&1
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo "✓ Deployment package created: $package_name"
    
    # Store package name in a file to avoid output capture issues
    echo "$package_name" > "$PROJECT_ROOT/.deploy_package_name"
}

# Deploy to remote server
deploy_to_server() {
    local package_name=$(cat "$PROJECT_ROOT/.deploy_package_name")
    
    echo "Deploying to remote server..."
    
    # Upload package
    echo "  - Uploading deployment package..."
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$PROJECT_ROOT/$package_name" "$REMOTE_USER@$REMOTE_HOST:/tmp/"
    
    # Execute remote deployment
    echo "  - Executing remote deployment..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" << EOF
set -e

echo "🔧 Setting up remote environment..."

# Install required packages
apt-get update >/dev/null 2>&1
apt-get install -y curl wget git unzip >/dev/null 2>&1

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh >/dev/null 2>&1
    rm get-docker.sh
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose >/dev/null 2>&1
    chmod +x /usr/local/bin/docker-compose
fi

# Create application directory
mkdir -p $REMOTE_PATH
cd $REMOTE_PATH

# Backup existing deployment if it exists
if [ -d "alnwoks" ]; then
    echo "Backing up existing deployment..."
    mv alnwoks alnwoks-backup-\$(date +%Y%m%d_%H%M%S)
fi

# Extract new deployment
echo "Extracting deployment package..."
tar -xzf /tmp/$package_name
cd alnwoks

# Make scripts executable
chmod +x scripts/*.sh

# Set environment variables
export DOMAIN="$DOMAIN"
export EMAIL="$EMAIL"

# Stop any existing services
echo "Stopping existing services..."
./scripts/deploy-docker.sh stop 2>/dev/null || true

# Build and start services
echo "Building Docker images..."
./scripts/deploy-docker.sh build >/dev/null 2>&1

echo "Starting services..."
./scripts/deploy-docker.sh start frontend >/dev/null 2>&1

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 15

# Run health checks
echo "Running health checks..."
if ./scripts/deploy-docker.sh test >/dev/null 2>&1; then
    echo "✅ Health checks passed"
else
    echo "⚠️ Health checks failed, but service may still be starting"
fi

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Service URLs:"
echo "  Frontend: http://$REMOTE_HOST:3000"
echo "  Health Check: http://$REMOTE_HOST:3000/health"
echo ""
echo "📋 Management Commands:"
echo "  Status: cd $REMOTE_PATH/alnwoks && ./scripts/deploy-docker.sh status"
echo "  Logs: cd $REMOTE_PATH/alnwoks && ./scripts/deploy-docker.sh logs"
echo "  Stop: cd $REMOTE_PATH/alnwoks && ./scripts/deploy-docker.sh stop"
echo ""

# Cleanup
rm -f /tmp/$package_name
EOF
    
    echo "✓ Remote deployment completed"
}

# Verify deployment
verify_deployment() {
    echo "Verifying deployment..."
    
    # Test HTTP connection
    echo "  - Testing HTTP connection..."
    if curl -f -s "http://$REMOTE_HOST:3000/health" > /dev/null; then
        echo "✓ HTTP health check passed"
    else
        echo "⚠ HTTP health check failed"
    fi
    
    # Get remote status
    echo "  - Getting remote service status..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" << EOF
cd $REMOTE_PATH/alnwoks
./scripts/deploy-docker.sh status
EOF
    
    echo "✓ Deployment verification completed"
}

# Cleanup local files
cleanup() {
    echo "Cleaning up..."
    
    # Remove deployment package
    if [ -f "$PROJECT_ROOT/.deploy_package_name" ]; then
        local package_name=$(cat "$PROJECT_ROOT/.deploy_package_name")
        rm -f "$PROJECT_ROOT/$package_name"
        rm -f "$PROJECT_ROOT/.deploy_package_name"
        echo "✓ Deployment package cleaned up"
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy         Deploy to development environment (Docker)"
    echo "  verify         Verify existing deployment"
    echo "  status         Show remote service status"
    echo "  logs           Show remote service logs"
    echo "  stop           Stop remote services"
    echo ""
    echo "Environment Variables:"
    echo "  DOMAIN         Target domain (default: alnwoks.com)"
    echo "  EMAIL          Admin email for SSL certificates"
    echo ""
    echo "Examples:"
    echo "  $0 deploy                                    # Deploy to development"
    echo "  $0 verify                                    # Verify deployment"
    echo "  $0 status                                    # Check status"
}

# Remote command execution
execute_remote_command() {
    local command="$1"
    
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" << EOF
cd $REMOTE_PATH/alnwoks
./scripts/deploy-docker.sh $command
EOF
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case $command in
        "deploy")
            check_prerequisites
            create_deployment_package
            deploy_to_server
            verify_deployment
            cleanup
            ;;
        "verify")
            check_prerequisites
            verify_deployment
            ;;
        "status")
            check_prerequisites
            execute_remote_command "status"
            ;;
        "logs")
            check_prerequisites
            execute_remote_command "logs"
            ;;
        "stop")
            check_prerequisites
            execute_remote_command "stop"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            echo "ERROR: Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'echo "Operation interrupted by user"; cleanup; exit 1' INT

# Run main function
main "$@"