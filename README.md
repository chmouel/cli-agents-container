# AI Agents Auto-Build Docker Image

Automated daily builds of an Ubuntu-based Docker image with popular AI coding assistants pre-installed.

## Included Tools

- **@openai/codex** - OpenAI Codex CLI coding agent
- **@anthropic-ai/claude-code** - Anthropic Claude Code CLI
- **@google/gemini-cli** - Google Gemini CLI
- **opencode** - OpenCode AI assistant

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

MIT
