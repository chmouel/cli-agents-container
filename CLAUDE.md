# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Automated daily-built Ubuntu rolling Docker image with four AI coding assistants and Kubernetes/Tekton debugging tools pre-installed:
- `@openai/codex` and `@google/gemini-cli` — installed via npm globally
- `claude` — installed via official `https://claude.ai/install.sh` script
- `opencode` — installed from GitHub release binary (anomalyco/opencode)
- `kubectl`, `stern` — Kubernetes CLI tools for cluster debugging

Published to `ghcr.io/chmouel/agents-image` via GitHub Actions.

## Architecture

Multi-stage Dockerfile (`builder` + runtime):
- **builder**: installs Node.js 20.19.1 from official binary tarball (not NodeSource), runs all npm installs and binary downloads
- **runtime**: fresh Ubuntu rolling, copies `/usr/local/lib/node_modules` and `/usr/local/bin` from builder, runs as non-root `aiuser`

Both stages install Node.js by downloading the official tarball directly to handle `linux/amd64` and `linux/arm64` with the `TARGETARCH` build arg.

## User Configuration

- **User**: `aiuser` (UID/GID 1000:1000)
- **Home directory**: `/user` (not `/home/aiuser`)
- **Shell**: `/bin/bash`
- **Notes**: The `ubuntu` user is removed from the base image to avoid conflicts. UID/GID 1000 ensures predictable file permissions when mounting volumes.

## Key Build Commands

```bash
# Local single-arch build
docker build -t agents-image .

# Local multi-arch build (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t agents-image .
```

## Triggering and Monitoring the CI Workflow

Use the helper script (requires `gh` CLI authenticated):

```bash
# Trigger and tail the workflow
./run-and-tail-workflow.sh

# Trigger with debug mode enabled
./run-and-tail-workflow.sh -d
```

The script triggers `.github/workflows/build-docker.yml`, waits for the run to appear, then watches it with `gh run watch`. On failure it dumps logs automatically.

## Version Pinning

- Node.js version is hardcoded in the Dockerfile (`NODE_VERSION="20.19.1"`) in **both** the builder and runtime stages — update both when bumping.
- OpenCode version is resolved dynamically at build time via the GitHub API (`/repos/anomalyco/opencode/releases/latest`) — no version to maintain.
- All tool installs (npm, claude install.sh, opencode) are cache-busted on every CI run via `ARG CACHEBUST` (set to `github.run_id` in the workflow), while the Node.js download layer remains cached.
