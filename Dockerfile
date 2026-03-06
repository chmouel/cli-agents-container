# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for AI Tools on Ubuntu
# Packages: @openai/codex, @anthropic-ai/claude-code, @google/gemini-cli, opencode
# Platform: linux/amd64, linux/arm64

FROM ubuntu:24.04 AS builder

# Build arguments for multi-platform support
ARG TARGETARCH
ARG OPENCODE_VERSION=1.2.17
ARG NODE_MAJOR=20

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production

# Install Node.js and build dependencies  
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        git \
        wget \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js from official binary (supports both AMD64 and ARM64)
ARG TARGETARCH
RUN NODE_VERSION="20.19.1" && \
    if [ "$TARGETARCH" = "amd64" ]; then ARCH="x64"; elif [ "$TARGETARCH" = "arm64" ]; then ARCH="arm64"; fi && \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" | \
    tar -xJ -C /usr/local --strip-components=1 && \
    node --version && npm --version

# Install npm-based AI tools globally
RUN npm install -g \
    @openai/codex \
    @google/gemini-cli && \
    npm cache clean --force

# Install Claude Code via official install script
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    cp /root/.local/bin/claude /usr/local/bin/claude && \
    chmod +x /usr/local/bin/claude && \
    claude --version

# Install OpenCode from GitHub releases (platform-specific binary)
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        OPENCODE_ARCH="x64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        OPENCODE_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${OPENCODE_ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/opencode

# Verify installations
RUN codex --version && \
    claude --version && \
    gemini --version && \
    opencode --version

# Final runtime stage
FROM ubuntu:24.04

# Build arguments
ARG NODE_MAJOR=20

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production

# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        git \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js from official binary (supports both AMD64 and ARM64)
ARG TARGETARCH
RUN NODE_VERSION="20.19.1" && \
    if [ "$TARGETARCH" = "amd64" ]; then ARCH="x64"; elif [ "$TARGETARCH" = "arm64" ]; then ARCH="arm64"; fi && \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" | \
    tar -xJ -C /usr/local --strip-components=1

# Copy installed tools from builder stage
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

# Remove ubuntu user if it exists from base image, then create aiuser with UID/GID 1000
RUN (userdel -r ubuntu 2>/dev/null || true) && \
    groupadd -g 1000 aiuser && \
    useradd -m -u 1000 -g 1000 -d /user -s /bin/bash aiuser && \
    chown -R aiuser:aiuser /user

# Set default user
USER aiuser
WORKDIR /user

# Add labels for GitHub Container Registry
LABEL org.opencontainers.image.source="https://github.com/chmouel/agents-image"
LABEL org.opencontainers.image.description="Ubuntu-based multi-arch image with AI coding assistants: Codex, Claude Code, Gemini CLI, OpenCode"
LABEL org.opencontainers.image.licenses="MIT"

# Default command
CMD ["/bin/bash"]
