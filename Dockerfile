# Use the official Node.js image as the base image for building
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package.json and pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./

# Install pnpm
RUN npm install -g pnpm --registry=https://registry.npmmirror.com

# Install dependencies with mirror
RUN pnpm config set registry https://registry.npmmirror.com && pnpm install

# Copy source files
COPY . .

# Build the Hexo site
RUN pnpm run build

# Use Nginx as the production server
FROM nginx:alpine

# Copy the built static files from the builder stage
COPY --from=builder /app/public /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Set environment variable with default port
ENV PORT=4000

# Expose the port
EXPOSE ${PORT}

# Use entrypoint script to substitute environment variables
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"] 