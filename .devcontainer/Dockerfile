# AI Agents Sandbox - Secure DevContainer
# Claude Code, Codex CLI, Antigravity CLI

# Pinned to a patch version + digest for reproducible builds.
# To update: bump the tag and re-resolve the digest for node:<tag>.
FROM node:24.18.0-bookworm-slim@sha256:b31e7a42fdf8b8aa5f5ed477c72d694301273f1069c5a2f71d53c6482e99a2fc

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv \
    python-is-python3 \
    sudo \
    jq \
    tmux \
    bubblewrap \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI is installed later (as the vscode user) from a pinned upstream
# release, mirroring the gitleaks install. The previous apt-based install had
# no version pin, so the gh version drifted build-to-build — the one exception
# to this repo's "pin everything" supply-chain policy.

# Rename existing node user to vscode (node image already has UID/GID 1000).
ARG USERNAME=vscode

# NOTE: deliberately NO passwordless-sudo grant. `no-new-privileges:true`
# (docker-compose.yml) already makes setuid sudo fail to escalate at runtime,
# so a NOPASSWD:ALL sudoers entry would be inert here — while still handing out
# free root if the container were ever launched without that flag. Omitting it
# is defense-in-depth with zero change to runtime behavior (see SECURITY.md).
RUN usermod -l $USERNAME -d /home/$USERNAME -m node \
    && groupmod -n $USERNAME node

# Set npm global directory for non-root user
ENV NPM_CONFIG_PREFIX=/home/$USERNAME/.npm-global
ENV PATH=/home/$USERNAME/.local/bin:$NPM_CONFIG_PREFIX/bin:$PATH

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Create necessary directories
RUN mkdir -p /home/$USERNAME/.npm-global \
    && mkdir -p /home/$USERNAME/.local/bin \
    && mkdir -p /home/$USERNAME/.claude \
    && mkdir -p /home/$USERNAME/.codex \
    && mkdir -p /home/$USERNAME/.gemini/antigravity-cli \
    && mkdir -p /home/$USERNAME/.ssh \
    && mkdir -p /home/$USERNAME/.config/git/hooks \
    # Pre-create ~/.config/gh as vscode so the gh-auth named volume seeds with
    # vscode ownership (an empty volume otherwise mounts root-owned, breaking
    # `gh auth login` for the non-root user).
    && mkdir -p /home/$USERNAME/.config/gh

# Install Claude Code, Codex CLI, and dev tools via npm (pinned versions)
RUN npm install -g @anthropic-ai/claude-code@2.1.195 \
    && npm install -g @openai/codex@0.142.3 \
    && npm install -g lefthook \
    && npm install -g secretlint @secretlint/secretlint-rule-preset-recommend

# Install gitleaks for additional secret scanning.
# Pick the binary matching the build platform so arm64 hosts (e.g. Apple
# Silicon) build without manual edits. TARGETARCH is provided by BuildKit.
ARG GITLEAKS_VERSION=8.30.1
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
      amd64) GL_ARCH=x64 ;; \
      arm64) GL_ARCH=arm64 ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -sSfL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${GL_ARCH}.tar.gz" \
    | tar -xz -C /home/$USERNAME/.local/bin gitleaks

# Install GitHub CLI from the official pinned release (replaces the unpinned
# apt install above). gh's release assets are named by Docker's TARGETARCH
# values (amd64/arm64), so no arch remapping is needed. The tarball nests the
# binary under gh_<ver>_linux_<arch>/bin/gh; strip those path components so it
# lands directly on PATH in ~/.local/bin.
ARG GH_VERSION=2.95.0
ARG TARGETARCH
RUN curl -sSfL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz" \
    | tar -xz -C /home/$USERNAME/.local/bin --strip-components=2 "gh_${GH_VERSION}_linux_${TARGETARCH}/bin/gh"

# Install uv (Python package/project manager) via the official pinned installer.
# The versioned URL pins the release for reproducible builds and verifies a
# checksum of the download. Installs to ~/.local/bin (already on PATH).
# NOTE: uv does NOT read PIP_CONFIG_FILE; it is routed through the same
# Takumi Guard secure index via a global ~/.config/uv/uv.toml (installed by
# postCreateCommand) so package installs keep the malware/quarantine protection.
ARG UV_VERSION=0.11.25
RUN curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | sh

# Note: global git hooks (core.hooksPath) are configured in postCreateCommand
# to avoid conflicts with lefthook install during npm install

# Install Antigravity CLI via official script.
# NOTE: the official installer always fetches the latest release and offers
# no version-pin option, so this step is intentionally unpinned. It does
# verify a sha512 of the download against the release manifest.
# Retry logic added to handle intermittent HTTP/2 stream errors in Docker.
RUN for i in 1 2 3 4 5; do \
      curl -fsSL https://antigravity.google/cli/install.sh | bash && break; \
      echo "Attempt $i failed, retrying in 5s..."; sleep 5; \
    done

# Set working directory
WORKDIR /workspaces

# Default shell
SHELL ["/bin/bash", "-c"]
