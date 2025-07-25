# =============================================================================
# DOCKERFILE - REACT APPLICATION CONTAINER
# =============================================================================
# This Dockerfile creates a production-ready container for the React application
# It uses a multi-stage build to optimize the final image size and security
# =============================================================================

# =============================================================================
# BUILD STAGE - NODE.JS APPLICATION BUILD
# =============================================================================
# First stage: Build the React application from source code
# This stage creates the production build files that will be served by nginx
FROM node:16-alpine as builder

# Set the working directory inside the container
WORKDIR /app

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================
# Copy package.json and package-lock.json first for better Docker layer caching
# This allows Docker to cache the npm install step if only source code changes
COPY react-project/package*.json ./

# Install all Node.js dependencies
# This step will be cached unless package.json changes
RUN npm install

# =============================================================================
# SOURCE CODE COPY AND BUILD
# =============================================================================
# Copy all React source code from the react-project directory
COPY react-project/ .

# Build the React application for production
# This creates a 'build' folder with optimized static files (HTML, CSS, JS)
# The build process includes minification, bundling, and optimization
RUN npm run build

# =============================================================================
# PRODUCTION STAGE - NGINX WEB SERVER
# =============================================================================
# Second stage: Create the final production image with nginx
# This stage only contains the built files and nginx, making it much smaller
FROM nginx:alpine

# =============================================================================
# STATIC FILES DEPLOYMENT
# =============================================================================
# Copy the built React application files from the builder stage
# These files will be served by nginx
COPY --from=builder /app/build /usr/share/nginx/html

# =============================================================================
# NGINX CONFIGURATION
# =============================================================================
# Copy the custom nginx configuration file
# This configures nginx to serve the React app on port 81
COPY nginx.conf /etc/nginx/conf.d/default.conf

# =============================================================================
# CONTAINER CONFIGURATION
# =============================================================================
# Expose port 81 for external access
# This port matches the configuration in nginx.conf and the security group
EXPOSE 81

# Start nginx in the foreground
# This keeps the container running and allows Docker to manage the process
CMD ["nginx", "-g", "daemon off;"]