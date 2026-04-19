# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for AI Tools on Ubuntu (rolling)
# Packages: @openai/codex, @anthropic-ai/claude-code, @google/gemini-cli, opencode
# Platform: linux/amd64, linux/arm64

FROM ubuntu:rolling AS builder

# Build arguments for multi-platform support
ARG TARGETARCH
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

# Install developer utility tools
RUN apt-get update && \
    apt-get install -y \
        ripgrep \
        fd-find \
        make \
        jq \
        unzip \
        shellcheck && \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI via official apt repo
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js from official binary (supports both AMD64 and ARM64)
ARG TARGETARCH
RUN NODE_VERSION="20.19.1" && \
    if [ "$TARGETARCH" = "amd64" ]; then ARCH="x64"; elif [ "$TARGETARCH" = "arm64" ]; then ARCH="arm64"; fi && \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" | \
    tar -xJ -C /usr/local --strip-components=1 && \
    node --version && npm --version

ARG CACHEBUST

# Install ast-grep (sg) from GitHub releases
RUN ASG_ARCH=$([ "$TARGETARCH" = "amd64" ] && echo "x86_64" || echo "aarch64") && \
    ASG_VERSION=$(curl -fsSL "https://api.github.com/repos/ast-grep/ast-grep/releases/latest" | \
        jq -r '.tag_name') && \
    echo "Installing ast-grep ${ASG_VERSION}" && \
    curl -fsSL "https://github.com/ast-grep/ast-grep/releases/download/${ASG_VERSION}/app-${ASG_ARCH}-unknown-linux-gnu.zip" \
        -o /tmp/ast-grep.zip && \
    unzip -o /tmp/ast-grep.zip sg ast-grep -d /usr/local/bin && \
    rm /tmp/ast-grep.zip && \
    chmod +x /usr/local/bin/sg /usr/local/bin/ast-grep

# Install yq from GitHub releases
RUN TARGETARCH_VAL=$([ "$TARGETARCH" = "amd64" ] && echo "amd64" || echo "arm64") && \
    YQ_TAG=$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" | \
        jq -r '.tag_name') && \
    echo "Installing yq ${YQ_TAG}" && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_TAG}/yq_linux_${TARGETARCH_VAL}" \
        -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# Install glab (GitLab CLI) from GitLab releases
RUN TARGETARCH_VAL=$([ "$TARGETARCH" = "amd64" ] && echo "amd64" || echo "arm64") && \
    GLAB_VERSION=$(curl -fsSL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases?per_page=1" | \
        jq -r '.[0].tag_name | ltrimstr("v")') && \
    echo "Installing glab v${GLAB_VERSION}" && \
    curl -fsSL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/glab_${GLAB_VERSION}_linux_${TARGETARCH_VAL}.tar.gz" | \
    tar -xz -C /usr/local/bin --strip-components=1 bin/glab && \
    chmod +x /usr/local/bin/glab

# Install kubectl from official release
RUN TARGETARCH_VAL=$([ "$TARGETARCH" = "amd64" ] && echo "amd64" || echo "arm64") && \
    KUBECTL_VERSION=$(curl -fsSL "https://dl.k8s.io/release/stable.txt") && \
    echo "Installing kubectl ${KUBECTL_VERSION}" && \
    curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH_VAL}/kubectl" \
        -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install stern (multi-pod log tailing) from GitHub releases
RUN TARGETARCH_VAL=$([ "$TARGETARCH" = "amd64" ] && echo "amd64" || echo "arm64") && \
    STERN_TAG=$(curl -fsSL "https://api.github.com/repos/stern/stern/releases/latest" | \
        jq -r '.tag_name') && \
    STERN_VERSION=${STERN_TAG#v} && \
    echo "Installing stern ${STERN_TAG}" && \
    curl -fsSL "https://github.com/stern/stern/releases/download/${STERN_TAG}/stern_${STERN_VERSION}_linux_${TARGETARCH_VAL}.tar.gz" | \
    tar -xz -C /usr/local/bin stern && \
    chmod +x /usr/local/bin/stern

# Install tkn (Tekton CLI) from GitHub releases
RUN TARGETARCH_VAL=$([ "$TARGETARCH" = "amd64" ] && echo "amd64" || echo "arm64") && \
    TKN_TAG=$(curl -fsSL "https://api.github.com/repos/tektoncd/cli/releases/latest" | \
        jq -r '.tag_name') && \
    TKN_VERSION=${TKN_TAG#v} && \
    echo "Installing tkn ${TKN_TAG}" && \
    curl -fsSL "https://github.com/tektoncd/cli/releases/download/${TKN_TAG}/tkn_${TKN_VERSION}_Linux_${TARGETARCH_VAL}.tar.gz" | \
    tar -xz -C /usr/local/bin tkn && \
    chmod +x /usr/local/bin/tkn

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

# Install OpenCode from GitHub releases (platform-specific binary, latest version)
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        OPENCODE_ARCH="x64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        OPENCODE_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    OPENCODE_TAG=$(curl -fsSL "https://api.github.com/repos/anomalyco/opencode/releases/latest" | \
        jq -r '.tag_name') && \
    echo "Installing opencode ${OPENCODE_TAG}" && \
    curl -fsSL "https://github.com/anomalyco/opencode/releases/download/${OPENCODE_TAG}/opencode-linux-${OPENCODE_ARCH}.tar.gz" | \
    tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/opencode

# Verify installations
RUN codex --version && \
    claude --version && \
    gemini --version && \
    opencode --version && \
    sg --version && \
    yq --version && \
    gh --version && \
    glab --version && \
    kubectl version --client && \
    stern --version && \
    tkn version && \
    rg --version && \
    fd --version && \
    make --version && \
    jq --version && \
    shellcheck --version

# Final runtime stage
FROM ubuntu:rolling

# Build arguments
ARG NODE_MAJOR=20

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production \
    PATH="/user/.local/bin:${PATH}"

# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        git \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

# Install developer utility tools
RUN apt-get update && \
    apt-get install -y \
        ripgrep \
        fd-find \
        make \
        jq \
        shellcheck && \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI via official apt repo
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y gh && \
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
LABEL org.opencontainers.image.description="Ubuntu-based multi-arch image with AI coding assistants (Codex, Claude Code, Gemini CLI, OpenCode) and other developer tools"
LABEL org.opencontainers.image.licenses="MIT"

# Default command
CMD ["/bin/bash"]
