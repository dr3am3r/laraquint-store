# Medusa Backend Deployment Guide - Hetzner Cloud

Complete step-by-step guide to deploy your Medusa backend to Hetzner Cloud using Docker.

## Prerequisites

- [ ] Hetzner Cloud account
- [ ] Domain name (for SSL/HTTPS)
- [ ] GitHub account (code repository)
- [ ] SSH key pair

## Cost Estimate

**Hetzner CX22**: €3.79/month (~$4.15/month)
- 2 vCPU
- 4GB RAM
- 40GB NVMe SSD
- 20TB traffic

---

## Step 1: Create Hetzner Server

### 1.1 Sign up and Create Project
1. Go to https://console.hetzner.cloud
2. Create new project: "laraquint-production"

### 1.2 Create Server
1. Click "Add Server"
2. **Location**: Choose closest to your users (Falkenstein, Nuremberg, or Helsinki for EU)
3. **Image**: Ubuntu 24.04 LTS
4. **Type**: Shared vCPU → CX22 (€3.79/mo)
5. **Networking**:
   - Enable IPv4
   - Enable IPv6 (optional)
6. **SSH Keys**:
   - Add your SSH public key (if you have one)
   - Or use password (will be emailed)
7. **Volumes**: None needed
8. **Firewalls**: We'll configure later
9. **Backups**: Enable if desired (+20% cost)
10. **Name**: laraquint-medusa-prod
11. Click "Create & Buy Now"

### 1.3 Note Server IP
Once created, note down the server's IP address (e.g., 123.45.67.89)

---

## Step 2: Configure Domain DNS

### 2.1 Add A Record
In your domain registrar's DNS settings:
```
Type: A
Name: api (or @ for root domain)
Value: <your-server-ip>
TTL: 300
```

Example:
- `api.laraquint.com` → Points to your server IP
- Wait 5-10 minutes for DNS propagation

### 2.2 Verify DNS
```bash
# From your local machine
dig api.laraquint.com
# Should show your server IP
```

---

## Step 3: Initial Server Setup

### 3.1 SSH into Server
```bash
ssh root@<your-server-ip>
# Or if using domain:
ssh root@api.laraquint.com
```

### 3.2 Update System
```bash
apt update && apt upgrade -y
```

### 3.3 Create Deploy User
```bash
# Create non-root user
adduser deploy
usermod -aG sudo deploy

# Copy SSH keys to deploy user
mkdir -p /home/deploy/.ssh
cp ~/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Test login (from another terminal)
# ssh deploy@<your-server-ip>
```

### 3.4 Configure Firewall
```bash
# Enable UFW
ufw allow OpenSSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw enable
ufw status
```

---

## Step 4: Install Docker

### 4.1 Install Docker
```bash
# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### 4.2 Add Deploy User to Docker Group
```bash
sudo usermod -aG docker deploy

# Log out and log back in for group changes to take effect
exit
ssh deploy@<your-server-ip>

# Verify docker works without sudo
docker ps
```

---

## Step 5: Deploy Application

### 5.1 Clone Repository
```bash
# Switch to deploy user if not already
su - deploy

# Clone your repository
git clone git@github.com:dr3am3r/laraquint-store.git
cd laraquint-store
```

### 5.2 Create Production Environment File
```bash
# Copy template
cp .env.production.template .env.production

# Generate secrets
echo "JWT_SECRET=$(openssl rand -base64 32)"
echo "COOKIE_SECRET=$(openssl rand -base64 32)"
echo "POSTGRES_PASSWORD=$(openssl rand -base64 32)"

# Edit the file
nano .env.production
```

Fill in:
```bash
# Your domain
DOMAIN=api.laraquint.com

# Database credentials
POSTGRES_DB=medusa-store
POSTGRES_USER=medusa
POSTGRES_PASSWORD=<paste generated password>

# Secrets
JWT_SECRET=<paste generated secret>
COOKIE_SECRET=<paste generated secret>

# CORS - Update with your actual frontend domain
STORE_CORS=https://laraquint.com
ADMIN_CORS=https://api.laraquint.com,https://laraquint.com
AUTH_CORS=https://api.laraquint.com,https://laraquint.com
```

### 5.3 Update Caddyfile
```bash
nano Caddyfile
```

Make sure it references your domain correctly (should use `{$DOMAIN}` which reads from .env.production)

### 5.4 Build and Start Services
```bash
# Load environment variables
export $(cat .env.production | xargs)

# Build and start in detached mode
docker compose -f docker-compose.prod.yml up -d --build

# Check logs
docker compose -f docker-compose.prod.yml logs -f
```

### 5.5 Verify Services
```bash
# Check running containers
docker ps

# Should see:
# - medusa_postgres
# - medusa_redis
# - medusa_server
# - medusa_worker
# - medusa_caddy

# Check individual service logs
docker logs medusa_server
docker logs medusa_worker
docker logs medusa_caddy
```

---

## Step 6: Initial Database Setup

### 6.1 Seed Database (First Time Only)
```bash
# Run seed script in server container
docker exec -it medusa_server yarn seed
```

### 6.2 Create Admin User
```bash
# Access the admin dashboard at https://api.laraquint.com
# Create your admin user account
```

---

## Step 7: Testing

### 7.1 Test API
```bash
# From your local machine
curl https://api.laraquint.com/health

# Should return: {"status":"ok"}
```

### 7.2 Test Admin Dashboard
Open in browser: `https://api.laraquint.com/app`

### 7.3 Test Store API
```bash
curl https://api.laraquint.com/store/products
```

---

## Step 8: Maintenance & Operations

### 8.1 View Logs
```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker logs -f medusa_server
docker logs -f medusa_worker
```

### 8.2 Restart Services
```bash
docker compose -f docker-compose.prod.yml restart

# Or specific service
docker restart medusa_server
```

### 8.3 Update Application
```bash
cd ~/laraquint-store

# Pull latest changes
git pull origin development

# Rebuild and restart
docker compose -f docker-compose.prod.yml up -d --build

# Check logs
docker compose -f docker-compose.prod.yml logs -f
```

### 8.4 Database Backup
```bash
# Create backup
docker exec medusa_postgres pg_dump -U medusa medusa-store > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
docker exec -i medusa_postgres psql -U medusa medusa-store < backup_20250119_120000.sql
```

---

## Step 9: Monitoring & Troubleshooting

### 9.1 Check Service Health
```bash
# Docker health check
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check resource usage
docker stats
```

### 9.2 Common Issues

**Issue**: Containers keep restarting
```bash
# Check logs for errors
docker logs medusa_server

# Check environment variables
docker exec medusa_server env | grep MEDUSA
```

**Issue**: Database connection errors
```bash
# Check postgres is running
docker exec medusa_postgres pg_isready -U medusa

# Check connection from server
docker exec medusa_server nc -zv postgres 5432
```

**Issue**: SSL not working
```bash
# Check Caddy logs
docker logs medusa_caddy

# Verify DNS is pointing correctly
dig api.laraquint.com
```

---

## Security Checklist

- [ ] Changed all default passwords
- [ ] Using strong random secrets for JWT and COOKIE
- [ ] Firewall enabled (UFW)
- [ ] SSH key authentication (not password)
- [ ] Database not exposed publicly (only docker network)
- [ ] Redis not exposed publicly (only docker network)
- [ ] HTTPS enabled via Caddy
- [ ] Regular backups configured

---

## Performance Optimization

### Enable PostgreSQL Performance Tweaks
```bash
# Edit postgres config
docker exec -it medusa_postgres sh

# Inside container
echo "max_connections = 100
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
work_mem = 10MB
min_wal_size = 1GB
max_wal_size = 4GB" >> /var/lib/postgresql/data/postgresql.conf

exit

# Restart postgres
docker restart medusa_postgres
```

---

## Useful Commands Reference

```bash
# Start services
docker compose -f docker-compose.prod.yml up -d

# Stop services
docker compose -f docker-compose.prod.yml down

# View logs
docker compose -f docker-compose.prod.yml logs -f

# Rebuild specific service
docker compose -f docker-compose.prod.yml up -d --build medusa-server

# Execute command in container
docker exec -it medusa_server sh

# Remove all containers and volumes (DANGEROUS!)
docker compose -f docker-compose.prod.yml down -v
```

---

## Next Steps

1. Set up automated backups (cron job)
2. Configure monitoring (Uptime Robot, etc.)
3. Set up log rotation
4. Deploy your frontend
5. Configure CDN (Cloudflare) for static assets

---

## Support

If you encounter issues:
1. Check logs: `docker compose -f docker-compose.prod.yml logs`
2. Verify environment variables
3. Check Medusa docs: https://docs.medusajs.com
4. GitHub issues: https://github.com/medusajs/medusa
