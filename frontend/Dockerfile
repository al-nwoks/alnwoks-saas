# ALNWOKS Frontend Dockerfile
# Single-stage Node image that builds the app and serves it with the project's server.js (npm run dev)

FROM node:22-alpine

# Create app directory
WORKDIR /app

# Copy package manifests and install (including devDeps required for build)
COPY package*.json ./
RUN npm ci --include=dev

# Copy source and build
COPY . .
RUN npm run build
ENV NODE_ENV=production

# Expose the port the app listens on (server.js uses env or defaults; adjust if different)
EXPOSE 3000

# Start the application using the existing npm script that runs server.js
CMD ["npm", "run", "dev"]