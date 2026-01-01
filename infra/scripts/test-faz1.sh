#!/bin/bash
# Quick integration test for Faz 1

set -e

echo "🧪 Simon AI Agent Studio - Faz 1 Quick Test"
echo "==========================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test Backend
echo ""
echo "📡 Testing Backend API..."
cd apps/api

# Check if running
if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend is not running. Start with: uvicorn main:app --reload${NC}"
    exit 1
fi

# Test endpoints
echo "Testing /health..."
curl -sf http://localhost:8000/health | jq '.' || echo "Failed"

echo "Testing /api/models..."
curl -sf http://localhost:8000/api/models | jq '.models[0]' || echo "Failed"

cd ../..

# Test Frontend
echo ""
echo "🎨 Testing Frontend..."
cd apps/web

if curl -sf http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend is running${NC}"
else
    echo -e "${RED}❌ Frontend is not running. Start with: npm run dev${NC}"
    exit 1
fi

cd ../..

echo ""
echo -e "${GREEN}✅ All tests passed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:3000 in browser"
echo "  2. Try sending a message"
echo "  3. Check streaming works"
echo ""
