# Quick Start Guide - Hetzner Deployment

This is a condensed version of the deployment guide. For detailed instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md).

## What You'll Need

1. Hetzner account
2. Domain name
3. 30-45 minutes

## 5-Minute Setup Checklist

### 1. Create Hetzner Server (5 min)
- [ ] Go to https://console.hetzner.cloud
- [ ] Create project: "laraquint-production"
- [ ] Add Server: Ubuntu 24.04, CX22 (€3.79/mo)
- [ ] Note server IP: `_______________`

### 2. Point Domain (2 min)
- [ ] Add A record: `api.laraquint.com` → `<server-ip>`
- [ ] Wait 5-10 minutes for DNS propagation

### 3. Server Setup (15 min)

```bash
# SSH into server
ssh root@<server-ip>

# Update system
apt update && apt upgrade -y

# Create deploy user
adduser deploy
usermod -aG sudo deploy

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker deploy

# Configure firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Switch to deploy user
su - deploy
```

### 4. Deploy Application (15 min)

```bash
# Clone repository
git clone git@github.com:dr3am3r/laraquint-store.git
cd laraquint-store

# Generate secrets
JWT_SECRET=$(openssl rand -base64 32)
COOKIE_SECRET=$(openssl rand -base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Create .env.production
cat > .env.production << EOF
DOMAIN=api.laraquint.com
POSTGRES_DB=medusa-store
POSTGRES_USER=medusa
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
JWT_SECRET=$JWT_SECRET
COOKIE_SECRET=$COOKIE_SECRET
STORE_CORS=https://laraquint.com
ADMIN_CORS=https://api.laraquint.com,https://laraquint.com
AUTH_CORS=https://api.laraquint.com,https://laraquint.com
EOF

# Create backups directory
mkdir -p backups

# Load environment and deploy
export $(cat .env.production | xargs)
docker compose -f docker-compose.prod.yml up -d --build

# Check status
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f
```

### 5. Initial Setup (5 min)

```bash
# Seed database (first time only)
docker exec -it medusa_server yarn seed

# Visit admin dashboard
open https://api.laraquint.com/app
```

## Daily Operations

### Deploy Updates
```bash
cd ~/laraquint-store
git pull
docker compose -f docker-compose.prod.yml up -d --build
```

### View Logs
```bash
docker compose -f docker-compose.prod.yml logs -f
```

### Backup Database
```bash
docker exec medusa_postgres pg_dump -U medusa medusa-store > backups/backup_$(date +%Y%m%d).sql
```

### Restart Service
```bash
docker restart medusa_server
```

## Troubleshooting

**Services won't start?**
```bash
docker compose -f docker-compose.prod.yml logs
```

**SSL not working?**
```bash
# Check Caddy logs
docker logs medusa_caddy

# Verify DNS
dig api.laraquint.com
```

**Database errors?**
```bash
# Check postgres
docker exec medusa_postgres pg_isready -U medusa
```

## Using deploy-helper.sh (From Local Machine)

```bash
# Edit script first and set SERVER_IP
nano deploy-helper.sh

# Make executable
chmod +x deploy-helper.sh

# Deploy from local machine
./deploy-helper.sh deploy

# View logs
./deploy-helper.sh logs

# Check status
./deploy-helper.sh status
```

## Important URLs

- **API**: https://api.laraquint.com
- **Admin**: https://api.laraquint.com/app
- **Health**: https://api.laraquint.com/health

## Cost

**Monthly**: €3.79 (~$4.15)
**Yearly**: €45.48 (~$50)

---

That's it! Your Medusa backend is now running on Hetzner Cloud. 🚀

For detailed documentation, troubleshooting, and advanced configuration, see [DEPLOYMENT.md](./DEPLOYMENT.md).
