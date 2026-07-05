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

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Rename existing node user to vscode (node image already has UID/GID 1000)
ARG USERNAME=vscode

RUN usermod -l $USERNAME -d /home/$USERNAME -m node \
    && groupmod -n $USERNAME node \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

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
