FROM node:20-slim

# Build tools needed for better-sqlite3 native module
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies first (layer caching)
COPY package.json ./
COPY package-lock.json* ./

RUN npm install

# Copy workspace sources
COPY apps/api ./apps/api
COPY packages/shared ./packages/shared

# Build the API bundle
RUN npm run build:api

# SQLite data directory
RUN mkdir -p /app/data

EXPOSE 4000

ENV NODE_ENV=production
ENV PORT=4000
ENV HOST=0.0.0.0
ENV CORS_ORIGIN=*

# Persist SQLite data across restarts
VOLUME ["/app/data"]

CMD ["node", "apps/api/dist/index.js"]
