#!/bin/bash

# ALNWOKS Frontend Deployment Script
# This script manages frontend development, testing, and deployment

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
FRONTEND_DIR="$PROJECT_ROOT/frontend"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.frontend.yml"

echo -e "${BLUE}🚀 ALNWOKS Frontend Deployment Manager${NC}"
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
    
    # Check Node.js for development
    if ! command -v node &> /dev/null; then
        print_warning "Node.js is not installed. Some development features will be limited."
    fi
    
    print_status "All dependencies are available"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  dev              Start development server"
    echo "  build            Build frontend assets"
    echo "  start            Start frontend container"
    echo "  stop             Stop frontend container"
    echo "  restart          Restart frontend container"
    echo "  logs             Show container logs"
    echo "  status           Show container status"
    echo "  shell            Open shell in container"
    echo "  test             Run health checks"
    echo "  deploy           Deploy to remote server"
    echo "  clean            Clean build artifacts"
    echo ""
    echo "Examples:"
    echo "  $0 dev                    # Start development server"
    echo "  $0 build                  # Build production assets"
    echo "  $0 start                  # Start container"
    echo "  $0 deploy                 # Deploy to remote server"
}

# Get Docker Compose command
get_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        echo "docker compose"
    fi
}

# Start development server
start_dev_server() {
    echo -e "${BLUE}Starting development server...${NC}"
    
    cd "$FRONTEND_DIR"
    
    # Check if dev script exists
    if npm run dev --silent &> /dev/null; then
        print_status "Starting development server with npm run dev"
        echo -e "${GREEN}🌐 Frontend will be available at: http://localhost:3000${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
        npm run dev
    else
        print_error "No development server available in package.json"
        exit 1
    fi
}

# Build frontend assets
build_frontend() {
    echo -e "${BLUE}Building frontend assets...${NC}"
    
    cd "$FRONTEND_DIR"
    
    # Build CSS
    if npm run build:css &> /dev/null; then
        print_status "CSS built successfully"
    else
        print_warning "No CSS build script found"
    fi
    
    # Build JavaScript
    if npm run build:js &> /dev/null; then
        print_status "JavaScript built successfully"
    else
        print_warning "No JavaScript build script found"
    fi
    
    print_status "Frontend assets built successfully"
}

# Start frontend container
start_container() {
    echo -e "${BLUE}Starting frontend container...${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    # Build and start container
    $compose_cmd -f "$COMPOSE_FILE" up -d --build
    
    print_status "Frontend container started"
    echo -e "${GREEN}🌐 Frontend available at: http://localhost:3001${NC}"
    echo -e "${GREEN}  Health Check: http://localhost:3001/health${NC}"
}

# Stop frontend container
stop_container() {
    echo -e "${BLUE}Stopping frontend container...${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    $compose_cmd -f "$COMPOSE_FILE" down
    
    print_status "Frontend container stopped"
}

# Restart frontend container
restart_container() {
    echo -e "${BLUE}Restarting frontend container...${NC}"
    
    stop_container
    sleep 2
    start_container
}

# Show container logs
show_logs() {
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    $compose_cmd -f "$COMPOSE_FILE" logs -f
}

# Show container status
show_status() {
    echo -e "${BLUE}Frontend Container Status:${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    $compose_cmd -f "$COMPOSE_FILE" ps
    
    echo ""
    echo -e "${BLUE}Docker Images:${NC}"
    docker images | grep alnwoks-frontend || echo "No ALNWOKS frontend images found"
}

# Open shell in container
open_shell() {
    echo -e "${BLUE}Opening shell in frontend container...${NC}"
    
    local compose_cmd=$(get_compose_cmd)
    cd "$PROJECT_ROOT"
    
    # Check if container is running
    if ! $compose_cmd -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        print_error "Frontend container is not running. Start it first with: $0 start"
        exit 1
    fi
    
    $compose_cmd -f "$COMPOSE_FILE" exec frontend /bin/sh
}

# Run health checks
run_health_checks() {
    echo -e "${BLUE}Running health checks...${NC}"
    
    # Check if container is running
    local compose_cmd=$(get_compose_cmd)
    if ! $compose_cmd -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        print_warning "Frontend container is not running"
        return 1
    fi
    
    # Check health endpoint
    if curl -f -s http://localhost:3001/health > /dev/null 2>&1; then
        print_status "Frontend health check passed"
    else
        print_warning "Frontend health check failed"
    fi
    
    # Check website accessibility
    if curl -f -s http://localhost:3001 > /dev/null 2>&1; then
        print_status "Frontend website is accessible"
    else
        print_warning "Frontend website is not accessible"
    fi
}

# Deploy to remote server
deploy_to_remote() {
    echo -e "${BLUE}Deploying to remote server...${NC}"
    
    # Use existing deployment script
    if [ -f "$SCRIPT_DIR/deploy-frontend-simple.sh" ]; then
        "$SCRIPT_DIR/deploy-frontend-simple.sh" deploy
    else
        print_error "Remote deployment script not found"
        exit 1
    fi
}

# Clean build artifacts
clean_artifacts() {
    echo -e "${BLUE}Cleaning build artifacts...${NC}"
    
    cd "$FRONTEND_DIR"
    
    # Remove dist directory
    if [ -d "dist" ]; then
        rm -rf dist
        print_status "Removed dist directory"
    fi
    
    # Remove node_modules (optional)
    read -p "Remove node_modules? This will require reinstallation. (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf node_modules
        print_status "Removed node_modules directory"
    fi
    
    print_status "Cleanup completed"
}

# Main execution
main() {
    local command=${1:-"help"}
    
    case $command in
        "dev")
            check_dependencies
            start_dev_server
            ;;
        "build")
            check_dependencies
            build_frontend
            ;;
        "start")
            check_dependencies
            start_container
            ;;
        "stop")
            check_dependencies
            stop_container
            ;;
        "restart")
            check_dependencies
            restart_container
            ;;
        "logs")
            check_dependencies
            show_logs
            ;;
        "status")
            check_dependencies
            show_status
            ;;
        "shell")
            check_dependencies
            open_shell
            ;;
        "test")
            check_dependencies
            run_health_checks
            ;;
        "deploy")
            check_dependencies
            deploy_to_remote
            ;;
        "clean")
            check_dependencies
            clean_artifacts
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