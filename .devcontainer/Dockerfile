# AI Agents Sandbox - Secure DevContainer
# Claude Code, Codex CLI, Antigravity CLI

FROM node:24-bookworm-slim

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
    sudo \
    jq \
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
    && mkdir -p /home/$USERNAME/.config/antigravity \
    && mkdir -p /home/$USERNAME/.ssh

# Install Claude Code and Codex CLI via npm
RUN npm install -g @anthropic-ai/claude-code \
    && npm install -g @openai/codex

# Install Antigravity CLI via official script
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

# Set working directory
WORKDIR /workspaces

# Default shell
SHELL ["/bin/bash", "-c"]
