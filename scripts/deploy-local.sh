#!/bin/bash

# ALNWOKS Local Development Deployment Script
# This script sets up the local development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

echo -e "${BLUE}🚀 ALNWOKS Local Development Deployment${NC}"
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

# Check if required tools are installed
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js 16+ from https://nodejs.org/"
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install npm."
        exit 1
    fi
    
    # Check if live-server is available globally or locally
    if ! command -v live-server &> /dev/null && ! npm list -g live-server &> /dev/null; then
        print_warning "live-server not found globally. Will use local installation."
    fi
    
    print_status "All dependencies are available"
}

# Install frontend dependencies
install_dependencies() {
    echo -e "${BLUE}Installing frontend dependencies...${NC}"
    
    cd "$FRONTEND_DIR"
    
    if [ ! -f "package.json" ]; then
        print_error "package.json not found in frontend directory"
        exit 1
    fi
    
    npm install
    print_status "Frontend dependencies installed"
}

# Build the frontend
build_frontend() {
    echo -e "${BLUE}Building frontend...${NC}"
    
    cd "$FRONTEND_DIR"
    
    # Build CSS if build script exists
    if npm run build:css &> /dev/null; then
        print_status "CSS built successfully"
    else
        print_warning "No CSS build script found, using CDN version"
    fi
    
    # Build JavaScript if build script exists
    if npm run build:js &> /dev/null; then
        print_status "JavaScript built successfully"
    else
        print_warning "No JavaScript build script found, using source files"
    fi
}

# Start the development server
start_dev_server() {
    echo -e "${BLUE}Starting development server...${NC}"
    
    cd "$FRONTEND_DIR"
    
    # Check if dev script exists in package.json
    if npm run dev --silent &> /dev/null; then
        print_status "Starting development server with npm run dev"
        echo -e "${GREEN}🌐 Frontend will be available at: http://localhost:3000${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
        npm run dev
    else
        # Fallback to live-server
        if command -v live-server &> /dev/null; then
            print_status "Starting development server with live-server"
            echo -e "${GREEN}🌐 Frontend will be available at: http://localhost:8080${NC}"
            echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
            live-server --port=8080 --host=localhost --open=complete_website.html
        else
            print_error "No development server available. Please install live-server globally:"
            echo "npm install -g live-server"
            exit 1
        fi
    fi
}

# Test the website
test_website() {
    echo -e "${BLUE}Testing website accessibility...${NC}"
    
    # Wait for server to start
    sleep 3
    
    # Test if the website is accessible
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1 || curl -f -s http://localhost:8080 > /dev/null 2>&1; then
        print_status "Website is accessible"
    else
        print_warning "Website accessibility test failed (this is normal for live-server)"
    fi
}

# Main execution
main() {
    echo "Starting local development deployment..."
    echo "Project root: $PROJECT_ROOT"
    echo "Frontend directory: $FRONTEND_DIR"
    echo ""
    
    check_dependencies
    install_dependencies
    build_frontend
    
    echo ""
    echo -e "${GREEN}🎉 Local development environment is ready!${NC}"
    echo ""
    echo "Available URLs:"
    echo "  - Main website: http://localhost:3000 or http://localhost:8080"
    echo "  - Complete website: http://localhost:3000/complete_website.html"
    echo "  - Alternative version: http://localhost:3000/index.html"
    echo ""
    
    # Ask user if they want to start the server
    read -p "Do you want to start the development server now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_dev_server
    else
        echo -e "${BLUE}To start the development server later, run:${NC}"
        echo "  cd frontend && npm run dev"
        echo "  or"
        echo "  cd frontend && live-server --port=8080 --open=complete_website.html"
    fi
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Deployment interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"