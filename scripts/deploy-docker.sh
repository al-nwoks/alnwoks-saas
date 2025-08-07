#!/bin/bash

# ALNWOKS Docker Deployment Script
# This script manages Docker-based deployment of the ALNWOKS application

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

echo -e "${BLUE}🐳 ALNWOKS Docker Deployment Manager${NC}"
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

# Check if required tools are installed
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
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
    
    print_status "All dependencies are available"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start [profile]     Start the application stack"
    echo "  stop               Stop the application stack"
    echo "  restart [profile]  Restart the application stack"
    echo "  build              Build all Docker images"
    echo "  logs [service]     Show logs for all services or specific service"
    echo "  status             Show status of all services"
    echo "  clean              Clean up containers, networks, and volumes"
    echo "  shell [service]    Open shell in running container"
    echo "  test               Run health checks on all services"
    echo ""
    echo "Profiles:"
    echo "  frontend           Frontend only (default)"
    echo "  backend            Frontend + Backend + Database"
    echo "  monitoring         Frontend + Monitoring stack"
    echo "  full               All services"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start frontend only"
    echo "  $0 start backend           # Start with backend services"
    echo "  $0 start full              # Start all services"
    echo "  $0 logs frontend           # Show frontend logs"
    echo "  $0 shell frontend          # Open shell in frontend container"
}

# Get Docker Compose command
get_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        echo "docker compose"
    fi
}

# Build Docker images
build_images() {
    echo -e "${BLUE}Building Docker images...${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    
    cd "$PROJECT_ROOT"
    
    # Build frontend image
    print_info "Building frontend image..."
    $compose_cmd build frontend
    
    print_status "Docker images built successfully"
}

# Start services
start_services() {
    local profile=${1:-"frontend"}
    
    echo -e "${BLUE}Starting ALNWOKS application stack (profile: $profile)...${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    case $profile in
        "frontend")
            $compose_cmd up -d frontend
            ;;
        "backend")
            $compose_cmd --profile backend up -d
            ;;
        "monitoring")
            $compose_cmd --profile monitoring up -d frontend prometheus grafana
            ;;
        "full")
            $compose_cmd --profile backend --profile monitoring --profile proxy up -d
            ;;
        *)
            print_error "Unknown profile: $profile"
            show_usage
            exit 1
            ;;
    esac
    
    print_status "Services started successfully"
    show_service_urls $profile
}

# Stop services
stop_services() {
    echo -e "${BLUE}Stopping ALNWOKS application stack...${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    $compose_cmd down
    
    print_status "Services stopped successfully"
}

# Restart services
restart_services() {
    local profile=${1:-"frontend"}
    
    echo -e "${BLUE}Restarting ALNWOKS application stack...${NC}"
    
    stop_services
    sleep 2
    start_services $profile
}

# Show logs
show_logs() {
    local service=${1:-""}
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    if [ -n "$service" ]; then
        echo -e "${BLUE}Showing logs for service: $service${NC}"
        $compose_cmd logs -f $service
    else
        echo -e "${BLUE}Showing logs for all services${NC}"
        $compose_cmd logs -f
    fi
}

# Show service status
show_status() {
    echo -e "${BLUE}Service Status:${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    $compose_cmd ps
    
    echo ""
    echo -e "${BLUE}Docker Images:${NC}"
    docker images | grep -E "(alnwoks|nginx|postgres|redis)" || echo "No ALNWOKS images found"
    
    echo ""
    echo -e "${BLUE}Network Status:${NC}"
    docker network ls | grep alnwoks || echo "No ALNWOKS networks found"
}

# Clean up resources
clean_resources() {
    echo -e "${YELLOW}This will remove all ALNWOKS containers, networks, and volumes.${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cleaning up ALNWOKS resources...${NC}"
        
        local compose_cmd=$(get_compose_cmd)
        cd "$PROJECT_ROOT"
        
        # Stop and remove containers
        $compose_cmd down -v --remove-orphans
        
        # Remove images
        docker images | grep alnwoks | awk '{print $3}' | xargs -r docker rmi -f
        
        # Remove unused networks
        docker network prune -f
        
        # Remove unused volumes
        docker volume prune -f
        
        print_status "Cleanup completed"
    else
        print_info "Cleanup cancelled"
    fi
}

# Open shell in container
open_shell() {
    local service=${1:-"frontend"}
    
    echo -e "${BLUE}Opening shell in $service container...${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    # Check if container is running
    if ! $compose_cmd ps $service | grep -q "Up"; then
        print_error "Service $service is not running. Start it first with: $0 start"
        exit 1
    fi
    
    $compose_cmd exec $service /bin/sh
}

# Run health checks
run_health_checks() {
    echo -e "${BLUE}Running health checks...${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    # Check frontend
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        print_status "Frontend is healthy"
    else
        print_warning "Frontend health check failed"
    fi
    
    # Check if other services are running and test them
    if $compose_cmd ps postgres | grep -q "Up"; then
        if $compose_cmd exec postgres pg_isready -U alnwoks > /dev/null 2>&1; then
            print_status "PostgreSQL is healthy"
        else
            print_warning "PostgreSQL health check failed"
        fi
    fi
    
    if $compose_cmd ps redis | grep -q "Up"; then
        if $compose_cmd exec redis redis-cli ping > /dev/null 2>&1; then
            print_status "Redis is healthy"
        else
            print_warning "Redis health check failed"
        fi
    fi
}

# Show service URLs
show_service_urls() {
    local profile=${1:-"frontend"}
    
    echo ""
    echo -e "${GREEN}🌐 Service URLs:${NC}"
    echo "  Frontend:     http://localhost:3000"
    echo "  Health Check: http://localhost:3000/health"
    
    case $profile in
        "backend"|"full")
            echo "  Backend API:  http://localhost:3001"
            echo "  PostgreSQL:   localhost:5432"
            echo "  Redis:        localhost:6379"
            ;;
    esac
    
    case $profile in
        "monitoring"|"full")
            echo "  Prometheus:   http://localhost:9090"
            echo "  Grafana:      http://localhost:3002 (admin/admin)"
            ;;
    esac
    
    case $profile in
        "full")
            echo "  Traefik:      http://localhost:8080"
            ;;
    esac
    
    echo ""
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case $command in
        "start")
            check_dependencies
            start_services $2
            ;;
        "stop")
            check_dependencies
            stop_services
            ;;
        "restart")
            check_dependencies
            restart_services $2
            ;;
        "build")
            check_dependencies
            build_images
            ;;
        "logs")
            check_dependencies
            show_logs $2
            ;;
        "status")
            check_dependencies
            show_status
            ;;
        "clean")
            check_dependencies
            clean_resources
            ;;
        "shell")
            check_dependencies
            open_shell $2
            ;;
        "test")
            check_dependencies
            run_health_checks
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