#!/bin/bash

# ALNWOKS Simple Frontend Deployment Script
# This script deploys only the frontend to the server on port 3001

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SSH_KEY="${HOME}/Documents/alnwoks/openwebui-llm-pipeline/terraform/hetzner_openwebui_key"
REMOTE_HOST="88.198.218.93"
REMOTE_USER="root"
REMOTE_PATH="/opt/alnwoks-frontend"

echo "🚀 ALNWOKS Simple Frontend Deployment"
echo "====================================="
echo "Target Server: ${REMOTE_USER}@${REMOTE_HOST}"
echo "Remote Path: ${REMOTE_PATH}"
echo "Port: 3001"
echo ""

# Function to print status messages
print_status() {
    echo "✓ $1"
}

print_info() {
    echo "ℹ $1"
}

print_error() {
    echo "✗ $1"
}

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY" ]; then
        print_error "SSH key not found: $SSH_KEY"
        exit 1
    fi
    
    # Check SSH key permissions
    chmod 600 "$SSH_KEY" 2>/dev/null || true
    
    # Test SSH connection
    print_info "Testing SSH connection..."
    if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH connection successful'" &> /dev/null; then
        print_error "Cannot connect to remote server"
        exit 1
    fi
    
    print_status "All prerequisites met"
}

# Deploy frontend
deploy_frontend() {
    echo "Deploying frontend..."
    
    # Create deployment package
    print_info "Creating frontend package..."
    local temp_dir=$(mktemp -d)
    local package_name="alnwoks-frontend-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    cd "$PROJECT_ROOT"
    
    # Copy frontend files and Docker Compose
    cp -r frontend/ "$temp_dir/"
    cp docker-compose.frontend.yml "$temp_dir/"
    
    # Create the package
    cd "$temp_dir"
    tar -czf "$PROJECT_ROOT/$package_name" . >/dev/null 2>&1
    rm -rf "$temp_dir"
    
    print_status "Frontend package created: $package_name"
    
    # Upload package
    print_info "Uploading frontend package..."
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$PROJECT_ROOT/$package_name" "$REMOTE_USER@$REMOTE_HOST:/tmp/"
    
    # Execute remote deployment
    print_info "Executing remote deployment..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" << EOF
set -e

echo "🔧 Setting up frontend environment..."

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

# Stop existing services
echo "Stopping existing services..."
if [ -f "docker-compose.frontend.yml" ]; then
    docker-compose -f docker-compose.frontend.yml down 2>/dev/null || true
fi

# Backup existing deployment if it exists
if [ -d "frontend" ]; then
    echo "Backing up existing deployment..."
    mv frontend frontend-backup-\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Extract new deployment
echo "Extracting frontend package..."
tar -xzf /tmp/$package_name

# Build and start the frontend service
echo "Building frontend Docker image..."
docker-compose -f docker-compose.frontend.yml build >/dev/null 2>&1

echo "Starting frontend service on port 3001..."
docker-compose -f docker-compose.frontend.yml up -d

# Wait for service to be ready
echo "Waiting for service to start..."
sleep 15

# Check if service is running
if docker-compose -f docker-compose.frontend.yml ps | grep -q "Up"; then
    echo "✅ Frontend service started successfully!"
else
    echo "❌ Frontend service failed to start"
    docker-compose -f docker-compose.frontend.yml logs
    exit 1
fi

echo ""
echo "🌐 Frontend URLs:"
echo "  Website: http://$REMOTE_HOST:3001"
echo "  Health Check: http://$REMOTE_HOST:3001/health"
echo ""
echo "📋 Management Commands:"
echo "  Status: cd $REMOTE_PATH && docker-compose -f docker-compose.frontend.yml ps"
echo "  Logs: cd $REMOTE_PATH && docker-compose -f docker-compose.frontend.yml logs"
echo "  Stop: cd $REMOTE_PATH && docker-compose -f docker-compose.frontend.yml down"
echo "  Restart: cd $REMOTE_PATH && docker-compose -f docker-compose.frontend.yml restart"
echo ""

# Cleanup
rm -f /tmp/$package_name
EOF
    
    # Cleanup local package
    rm -f "$PROJECT_ROOT/$package_name"
    
    print_status "Frontend deployment completed"
}

# Verify deployment
verify_deployment() {
    echo "Verifying deployment..."
    
    # Test HTTP connection
    print_info "Testing HTTP connection..."
    sleep 5
    if curl -f -s "http://$REMOTE_HOST:3001" > /dev/null; then
        print_status "Frontend is accessible at http://$REMOTE_HOST:3001"
    else
        print_error "Frontend is not accessible"
        return 1
    fi
    
    # Check service status
    print_info "Checking service status..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" << EOF
cd $REMOTE_PATH
echo "Docker container status:"
docker-compose -f docker-compose.frontend.yml ps
EOF
    
    print_status "Deployment verification completed"
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy         Deploy frontend to server"
    echo "  status         Show service status"
    echo "  logs           Show service logs"
    echo "  stop           Stop frontend service"
    echo "  restart        Restart frontend service"
    echo ""
    echo "Examples:"
    echo "  $0 deploy      # Deploy frontend to port 3001"
    echo "  $0 status      # Check service status"
    echo "  $0 logs        # View service logs"
}

# Remote command execution
execute_remote_command() {
    local command="$1"
    
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" << EOF
cd $REMOTE_PATH
case "$command" in
    "status")
        echo "Frontend service status:"
        docker-compose -f docker-compose.frontend.yml ps
        echo ""
        echo "Container details:"
        docker ps | grep alnwoks-frontend || echo "No frontend container running"
        ;;
    "logs")
        echo "Frontend service logs:"
        docker-compose -f docker-compose.frontend.yml logs --tail=50
        ;;
    "stop")
        echo "Stopping frontend service..."
        docker-compose -f docker-compose.frontend.yml down
        echo "Frontend service stopped"
        ;;
    "restart")
        echo "Restarting frontend service..."
        docker-compose -f docker-compose.frontend.yml restart
        echo "Frontend service restarted"
        ;;
    *)
        echo "Unknown command: $command"
        exit 1
        ;;
esac
EOF
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case $command in
        "deploy")
            check_prerequisites
            deploy_frontend
            verify_deployment
            ;;
        "status"|"logs"|"stop"|"restart")
            check_prerequisites
            execute_remote_command "$command"
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
trap 'echo "Operation interrupted by user"; exit 1' INT

# Run main function
main "$@"