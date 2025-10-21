# Production Dockerfile for Medusa
FROM node:20-alpine AS base

# Set working directory
WORKDIR /server

# Copy package files
COPY package.json yarn.lock ./

# Install all dependencies using yarn
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Don't build here - the volume mount will override it anyway
# Build happens in start.prod.sh after volume is mounted

# Expose the port Medusa runs on
EXPOSE 9000

# Start with migrations and then the server
CMD ["sh", "-c", "if [ \"$NODE_ENV\" = \"production\" ]; then ./start.prod.sh; else ./start.sh; fi"]
