#!/bin/sh
set -e

echo "🚀 Starting Medusa in production mode..."

# Run migrations from source directory
echo "📊 Running database migrations..."
npx medusa db:migrate

# Check worker mode
if [ "$MEDUSA_WORKER_MODE" = "worker" ]; then
    # Workers don't need admin build, start directly
    echo "👷 Starting Medusa worker (background jobs only)..."
    npx medusa start
else
    # Server mode - build and run from build directory
    echo "🔨 Building Medusa application (backend + admin)..."
    npx medusa build

    echo "📦 Installing dependencies in build directory..."
    cd /server/.medusa/server
    yarn install --production --frozen-lockfile

    echo "🌐 Starting Medusa server from build directory..."
    NODE_ENV=production yarn start
fi
