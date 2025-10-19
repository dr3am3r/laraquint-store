# Production Dockerfile for Medusa
FROM node:20-alpine AS base

# Set working directory
WORKDIR /server

# Copy package files and yarn config
COPY package.json yarn.lock ./
COPY .yarnrc.yml ./ 2>/dev/null || :

# Install all dependencies using yarn
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build for production (creates .medusa directory with admin)
RUN NODE_ENV=production npx medusa build || echo "Build failed, will retry at startup"

# Expose the port Medusa runs on
EXPOSE 9000

# Start with migrations and then the server
CMD ["sh", "-c", "if [ \"$NODE_ENV\" = \"production\" ]; then ./start.prod.sh; else ./start.sh; fi"]
