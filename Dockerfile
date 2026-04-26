# Stage 1: Build the React app
FROM node:alpine as builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Build the React app for production
RUN npm run build

# Stage 2: Serve with Node/Express (lightweight server)
FROM node:alpine

WORKDIR /app

# Install serve to run the app
RUN npm install -g serve

# Copy built app from builder stage
COPY --from=builder /app/build ./build

# Expose the port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start the application
CMD ["serve", "-s", "build", "-l", "3000"]
