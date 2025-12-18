# =============================================================================
# Ansible Managed Node (Docker Container)
# -----------------------------------------------------------------------------
# Purpose:
#   - Act as Ansible target node (dev / sit / uat / prod)
#   - Create environment-specific OS user at build time
#   - Provide SSH access
#   - Run services WITHOUT systemd
#
# Design:
#   - Ansible connects as root
#   - Environment user exists for app ownership & isolation
#   - No sudo / no become required
# =============================================================================

FROM ubuntu:22.04

LABEL role="ansible-managed-node"
LABEL maintainer="ansible-lab"

# -----------------------------------------------------------------------------
# Build-time arguments (injected from docker-compose.yml)
# -----------------------------------------------------------------------------
ARG NODE_USER
ARG NODE_PASSWORD

# -----------------------------------------------------------------------------
# Persist ARGs as ENV (important for runtime visibility & debugging)
# -----------------------------------------------------------------------------
ENV NODE_USER=${NODE_USER}
ENV NODE_PASSWORD=${NODE_PASSWORD}

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# -----------------------------------------------------------------------------
# Install base OS packages required for Ansible + SSH
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    python3 \
    python3-apt \
    python3-distutils \
    ca-certificates \
    curl \
    wget \
    iproute2 \
    procps \
    net-tools \
    cron \
    tzdata \
    vim \
    nano \
    less \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# SSH server setup
# -----------------------------------------------------------------------------
RUN mkdir -p /var/run/sshd && \
    mkdir -p /root/.ssh && chmod 700 /root/.ssh

# -----------------------------------------------------------------------------
# Create environment-specific user (FROM ARG)
# -----------------------------------------------------------------------------
RUN test -n "${NODE_USER}" && \
    useradd -m -s /bin/bash "${NODE_USER}" && \
    echo "${NODE_USER}:${NODE_PASSWORD}" | chpasswd

# -----------------------------------------------------------------------------
# SSH configuration (container-safe)
# -----------------------------------------------------------------------------
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's@#AuthorizedKeysFile.*@AuthorizedKeysFile %h/.ssh/authorized_keys@' /etc/ssh/sshd_config

# -----------------------------------------------------------------------------
# Prepare SSH directories for NODE_USER
# -----------------------------------------------------------------------------
RUN mkdir -p /home/${NODE_USER}/.ssh && \
    chmod 700 /home/${NODE_USER}/.ssh && \
    touch /home/${NODE_USER}/.ssh/authorized_keys && \
    chmod 600 /home/${NODE_USER}/.ssh/authorized_keys && \
    chown -R ${NODE_USER}:${NODE_USER} /home/${NODE_USER}/.ssh

# -----------------------------------------------------------------------------
# Expose SSH
# -----------------------------------------------------------------------------
EXPOSE 22

# -----------------------------------------------------------------------------
# Container entrypoint
# -----------------------------------------------------------------------------
CMD ["/usr/sbin/sshd", "-D"]
