#!/bin/bash

# Quick script to check remote deployment status

SSH_KEY="${HOME}/Documents/alnwoks/openwebui-llm-pipeline/terraform/hetzner_openwebui_key"
REMOTE_HOST="88.198.218.93"
REMOTE_USER="root"
REMOTE_PATH="/opt/alnwoks"

echo "🔍 Checking remote deployment status..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" << 'EOF'
echo "📁 Checking directory structure:"
ls -la /opt/alnwoks/

if [ -d "/opt/alnwoks/alnwoks" ]; then
    echo ""
    echo "📂 Contents of alnwoks directory:"
    ls -la /opt/alnwoks/alnwoks/
    
    if [ -d "/opt/alnwoks/alnwoks/scripts" ]; then
        echo ""
        echo "📜 Scripts directory contents:"
        ls -la /opt/alnwoks/alnwoks/scripts/
        
        echo ""
        echo "🔧 Making scripts executable..."
        chmod +x /opt/alnwoks/alnwoks/scripts/*.sh
        
        echo ""
        echo "🐳 Checking Docker status..."
        cd /opt/alnwoks/alnwoks
        
        # Try to start the frontend
        echo "Starting frontend service..."
        ./scripts/deploy-docker.sh start frontend
        
        echo ""
        echo "🏥 Running health check..."
        sleep 10
        ./scripts/deploy-docker.sh test
        
        echo ""
        echo "📊 Service status:"
        ./scripts/deploy-docker.sh status
    else
        echo "❌ Scripts directory not found"
    fi
else
    echo "❌ alnwoks directory not found"
fi
EOF

echo ""
echo "🌐 Testing external access..."
if curl -f -s "http://$REMOTE_HOST:3000/health" > /dev/null; then
    echo "✅ Website is accessible at http://$REMOTE_HOST:3000"
else
    echo "❌ Website is not accessible"
fi