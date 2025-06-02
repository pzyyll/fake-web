#-----------------------------------------------------------------------------
# Stage 1: Builder Stage - Install dependencies and build the application
#-----------------------------------------------------------------------------
FROM node:24-alpine AS builder

# Install pnpm
RUN npm install -g pnpm

WORKDIR /app

# Copy package.json and pnpm-lock.yaml first to leverage Docker cache
COPY package.json pnpm-lock.yaml ./

# Install dependencies using pnpm
# --frozen-lockfile ensures we use the exact versions from the lockfile
# If you have private packages or need ssh, configure pnpm store accordingly or use --shamefully-hoist if needed
RUN pnpm install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# (Optional) Set build-time arguments for Nuxt
# ARG NUXT_PUBLIC_API_BASE_URL
# ENV NUXT_PUBLIC_API_BASE_URL=$NUXT_PUBLIC_API_BASE_URL

# Build the Nuxt application
# This will generate the .output directory
RUN pnpm build

# (Optional) Prune development dependencies if you were to copy node_modules directly
# RUN pnpm prune --prod
# However, for Nuxt 3, it's better to rely on the self-contained .output directory

#-----------------------------------------------------------------------------
# Stage 2: Production Stage - Serve the built application
#-----------------------------------------------------------------------------
FROM node:24-alpine

WORKDIR /app

# Create a non-root user and group for better security
RUN addgroup -g 1001 -S appgroup && adduser -u 1001 -S appuser -G appgroup

# Copy only the necessary build artifacts from the builder stage
# Nuxt 3's build output is in the .output directory
COPY --from=builder --chown=appuser:appgroup /app/.output ./.output

# (Optional) If your application has a 'public' folder that is served directly
# and NOT part of the .output (uncommon for Nuxt 3 as .output/public is used),
# you might need to copy it. Usually, .output contains everything.
# COPY --from=builder --chown=appuser:appgroup /app/public ./public

# (Optional) If your server relies on package.json for metadata or scripts (unlikely for just running Nitro server)
# COPY --from=builder --chown=appuser:appgroup /app/package.json ./package.json

# Switch to the non-root user
USER appuser

# Set environment variables for the Nuxt 3 server (Nitro)
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

# Expose the port the app runs on
EXPOSE 3000

# The command to run the Nuxt 3 production server
# Nitro server entry point is typically .output/server/index.mjs
CMD ["node", ".output/server/index.mjs"]

