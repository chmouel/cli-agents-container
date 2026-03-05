# Multi-stage Dockerfile for AI Tools on Arch Linux
# Packages: openai-codex-bin, gemini-cli, claude-code, opencode
# Platform: linux/amd64, linux/arm64

FROM lopsided/archlinux:latest AS builder

# Fix mirrorlist to use reliable mirrors and update system
RUN echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' > /etc/pacman.d/mirrorlist && \
    echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist && \
    echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist && \
    sed -i 's/^#DisableSandbox$/DisableSandbox/' /etc/pacman.conf && \
    pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Sy --noconfirm archlinux-keyring && \
    pacman -Su --noconfirm

# Install base packages needed for AUR building
RUN pacman -S --noconfirm \
    base-devel \
    git \
    sudo \
    wget \
    && pacman -Scc --noconfirm

# Create a non-root user for building AUR packages
# AUR packages cannot be built as root
RUN useradd -m -G wheel -s /bin/bash builduser && \
    echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to builduser
USER builduser
WORKDIR /home/builduser

# Install yay (AUR helper)
RUN git clone https://aur.archlinux.org/yay.git && \
    cd yay && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -rf yay

# Install AI tools from AUR
# Using yay with --noconfirm and --needed flags
RUN yay -S --noconfirm --needed \
    openai-codex-bin \
    gemini-cli-git \
    claude-code \
    opencode-bin

# Clean yay cache to reduce image size
RUN yay -Scc --noconfirm

# Switch back to root for final stage preparation
USER root

# Final stage - create optimized runtime image
FROM lopsided/archlinux:latest

# Fix mirrorlist to use reliable mirrors and update system
RUN echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' > /etc/pacman.d/mirrorlist && \
    echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist && \
    echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist && \
    sed -i 's/^#DisableSandbox$/DisableSandbox/' /etc/pacman.conf && \
    pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Sy --noconfirm archlinux-keyring && \
    pacman -Su --noconfirm

# Install minimal runtime dependencies
RUN pacman -S --noconfirm \
    sudo \
    git \
    base-devel \
    && pacman -Scc --noconfirm

# Create builduser in final image (for yay usage)
RUN useradd -m -G wheel -s /bin/bash builduser && \
    echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Copy yay binary and configuration from builder
COPY --from=builder /usr/bin/yay /usr/bin/yay
COPY --from=builder /home/builduser/.config/yay /home/builduser/.config/yay

# Copy installed packages from builder
# This copies the actual installed binaries and libraries
COPY --from=builder /usr/bin/codex /usr/bin/codex
COPY --from=builder /usr/bin/gemini /usr/bin/gemini
COPY --from=builder /usr/bin/claude /usr/bin/claude
COPY --from=builder /usr/bin/opencode /usr/bin/opencode

# Copy any shared libraries or dependencies if needed
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/share /usr/share

# Set ownership for copied files
RUN chown -R builduser:builduser /home/builduser

# Clean up unnecessary files to reduce image size
RUN rm -rf /usr/share/man/* \
    /usr/share/doc/* \
    /tmp/* \
    /var/tmp/* \
    /var/cache/pacman/pkg/*

# Set default user
USER builduser
WORKDIR /home/builduser

# Add labels for GitHub Container Registry
LABEL org.opencontainers.image.source="https://github.com/chmouel/aibot-autobuild"
LABEL org.opencontainers.image.description="Arch Linux with AI tools: openai-codex-bin, gemini-cli, claude-code, opencode"
LABEL org.opencontainers.image.licenses="MIT"

# Default command
CMD ["/bin/bash"]
