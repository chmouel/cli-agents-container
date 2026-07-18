# AI Agents Auto-Build Docker Image

Automated daily builds of an Ubuntu-based Docker image with popular AI coding assistants pre-installed.

## Included Tools

- **@openai/codex** - OpenAI Codex CLI coding agent
- **@anthropic-ai/claude-code** - Anthropic Claude Code CLI
- **@google/gemini-cli** - Google Gemini CLI
- **opencode** - OpenCode AI assistant

## Current Versions

<!-- versions-start -->
| Tool | Version |
|------|---------|
| node | 20.19.1 |
| codex | codex-cli 0.144.5 |
| claude | 2.1.214 (Claude Code) |
| gemini | 0.51.0 |
| opencode | 1.18.3 |
| copilot | GitHub Copilot CLI 1.0.71. |
| sg | ast-grep 0.44.1 |
| yq | yq (https://github.com/mikefarah/yq/) version v4.53.3 |
| gh | gh version 2.96.0 (2026-07-02) |
| glab | glab 1.108.0 (5de20850) |
| kubectl | Client Version: v1.36.2 |
| stern | version: 1.34.0 |
| rg | ripgrep 15.1.0 |
| fd | fdfind 10.3.0 |
| jq | jq-1.8.1 |
| shellcheck | 0.11.0 |

_Last updated: 2026-07-18T05:02:33Z_
<!-- versions-end -->

## Usage

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/chmouel/agents-image:latest
```

### Run the container

```bash
docker run -it ghcr.io/chmouel/agents-image:latest
```

### Run a specific tool

```bash
# Run Codex
docker run -it ghcr.io/chmouel/agents-image:latest codex --help

# Run Gemini
docker run -it ghcr.io/chmouel/agents-image:latest gemini --help

# Run Claude
docker run -it ghcr.io/chmouel/agents-image:latest claude --help

# Run OpenCode
docker run -it ghcr.io/chmouel/agents-image:latest opencode --help
```

### Install additional npm packages

The image includes Node.js, so you can install additional npm packages globally:

```bash
docker run -it ghcr.io/chmouel/agents-image:latest bash
# Inside container:
npm install -g <package-name>
```

## Build Locally

```bash
docker build -t agents-image .
```

For multi-architecture builds:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t agents-image .
```

## Automated Builds

This image is automatically built and pushed to GitHub Container Registry:

- **Daily**: Every day at 2 AM UTC
- **On push**: When changes are pushed to the main branch
- **On PR**: For testing (not pushed to registry)
- **Manual**: Via GitHub Actions workflow dispatch

## Architecture Support

- `linux/amd64` (x86_64)
- `linux/arm64` (ARM 64-bit)
  - **Compatible with Apple Silicon** (M1, M2, M3, M4 Macs)
  - Native ARM64 performance (not emulated)

## Image Size Optimization

The Dockerfile uses multi-stage builds to minimize the final image size while keeping essential tools and Node.js runtime for package management.

## Base Image

Built on **Ubuntu 24.04 LTS** for:

- Official multi-architecture support (AMD64 + ARM64)
- Long-term stability and security updates
- Reliable Node.js packages via NodeSource

## User Configuration

The container runs as a non-root user for better security:

- **Username**: `aiuser`
- **UID/GID**: 1000:1000
- **Home directory**: `/user`

### Volume Mounting Example

```bash
# Mount your project directory with correct permissions
docker run -it -v $(pwd):/workspace ghcr.io/chmouel/agents-image:latest
```

## License

[Apache License 2.0](./LICENSE)
