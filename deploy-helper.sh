#!/bin/bash
# Deployment Helper Script for Hetzner
# This script helps with common deployment tasks

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Server configuration - UPDATE THESE
SERVER_IP="YOUR_SERVER_IP"
SERVER_USER="deploy"
SERVER_PATH="/home/deploy/laraquint-store"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if server IP is configured
check_config() {
    if [ "$SERVER_IP" = "YOUR_SERVER_IP" ]; then
        print_error "Please edit this script and set SERVER_IP to your actual server IP"
        exit 1
    fi
}

# Function to deploy
deploy() {
    check_config
    print_info "Deploying to $SERVER_IP..."

    ssh $SERVER_USER@$SERVER_IP << 'ENDSSH'
        cd /home/deploy/laraquint-store
        git pull origin development
        export $(cat .env.production | xargs)
        docker compose -f docker-compose.prod.yml up -d --build
        docker compose -f docker-compose.prod.yml ps
ENDSSH

    print_info "Deployment complete!"
    print_info "Check logs with: $0 logs"
}

# Function to view logs
logs() {
    check_config
    print_info "Viewing logs from $SERVER_IP..."
    ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && docker compose -f docker-compose.prod.yml logs -f"
}

# Function to check status
status() {
    check_config
    print_info "Checking status on $SERVER_IP..."
    ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && docker compose -f docker-compose.prod.yml ps"
}

# Function to restart services
restart() {
    check_config
    print_info "Restarting services on $SERVER_IP..."
    ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && docker compose -f docker-compose.prod.yml restart"
    print_info "Services restarted!"
}

# Function to create backup
backup() {
    check_config
    local backup_name="backup_$(date +%Y%m%d_%H%M%S).sql"
    print_info "Creating database backup: $backup_name"

    ssh $SERVER_USER@$SERVER_IP << ENDSSH
        cd $SERVER_PATH
        docker exec medusa_postgres pg_dump -U medusa medusa-store > backups/$backup_name
        echo "Backup created: backups/$backup_name"
ENDSSH

    print_info "Backup complete!"
}

# Function to run migrations
migrate() {
    check_config
    print_info "Running database migrations on $SERVER_IP..."
    ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && docker exec medusa_server npx medusa db:migrate"
    print_info "Migrations complete!"
}

# Function to open shell
shell() {
    check_config
    print_info "Opening shell on $SERVER_IP..."
    ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && docker exec -it medusa_server sh"
}

# Function to show help
show_help() {
    echo "Deployment Helper for Laraquint Medusa Backend"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy     - Pull latest code and deploy to server"
    echo "  logs       - View live logs from server"
    echo "  status     - Check status of all services"
    echo "  restart    - Restart all services"
    echo "  backup     - Create database backup"
    echo "  migrate    - Run database migrations"
    echo "  shell      - Open shell in medusa_server container"
    echo "  help       - Show this help message"
    echo ""
    echo "Before first use:"
    echo "  1. Edit this script and set SERVER_IP"
    echo "  2. Make sure you can SSH to the server: ssh $SERVER_USER@SERVER_IP"
}

# Main script logic
case "${1}" in
    deploy)
        deploy
        ;;
    logs)
        logs
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    backup)
        backup
        ;;
    migrate)
        migrate
        ;;
    shell)
        shell
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: ${1}"
        echo ""
        show_help
        exit 1
        ;;
esac
