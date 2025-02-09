# Use an official Node.js runtime as the base image
FROM node:20-alpine AS base

FROM base AS builder
RUN apk update
RUN apk add --no-cache libc6-compat
# Set working directory
WORKDIR /app

RUN npm install -g turbo@1.13.0

# Copy package.json and package-lock.json (if available)
COPY . .

RUN turbo prune ecc-docs --docker

FROM base AS installer
RUN apk update
RUN apk add --no-cache libc6-compat

WORKDIR /app

COPY --from=builder /app/out/json/ .

# Install dependencies
RUN npm ci

COPY scripts /app/scripts

# Build the application
COPY --from=builder /app/out/full/ .
RUN npm run build --filter=ecc-docs...

# Use a lightweight web server to serve static files
FROM nginx:alpine

# Copy the built static files from the previous stage
COPY --from=installer /app/apps/documentation/out /usr/share/nginx/html

# Copy the Nginx configuration file
COPY --from=builder /app/apps/documentation/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
