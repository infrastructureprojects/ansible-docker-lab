# =============================================================================
# Ansible Managed Node (Docker Container)
# -----------------------------------------------------------------------------
# Purpose:
#   - Act as Ansible target node (dev / sit / uat / prod)
#   - Provide SSH access
#   - Support package installation via Ansible
#   - Run services WITHOUT systemd (nginx, cron, docker cli)
#
# IMPORTANT:
#   - No systemd
#   - Services are started via Ansible shell/command
#   - SSH is the only always-on service
# =============================================================================

FROM ubuntu:22.04

LABEL role="ansible-managed-node"
LABEL maintainer="ansible-lab"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# -----------------------------------------------------------------------------
# Install base OS packages required for Ansible + SSH
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    sudo \
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
# Create Ansible SSH user
# -----------------------------------------------------------------------------
ARG SSH_USER=ansible
ARG SSH_PASSWORD=ansible

RUN useradd -m -s /bin/bash ${SSH_USER} && \
    echo "${SSH_USER}:${SSH_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${SSH_USER} && \
    echo "${SSH_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# -----------------------------------------------------------------------------
# SSH hardening (container-safe)
# -----------------------------------------------------------------------------
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's@#AuthorizedKeysFile.*@AuthorizedKeysFile %h/.ssh/authorized_keys@' /etc/ssh/sshd_config

# -----------------------------------------------------------------------------
# Prepare SSH directories for ansible user
# -----------------------------------------------------------------------------
RUN mkdir -p /home/${SSH_USER}/.ssh && \
    chmod 700 /home/${SSH_USER}/.ssh && \
    touch /home/${SSH_USER}/.ssh/authorized_keys && \
    chmod 600 /home/${SSH_USER}/.ssh/authorized_keys && \
    chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh

# -----------------------------------------------------------------------------
# Expose SSH port
# -----------------------------------------------------------------------------
EXPOSE 22

# -----------------------------------------------------------------------------
# Container entrypoint
# -----------------------------------------------------------------------------
# NOTE:
# - No systemd
# - sshd runs in foreground
# - nginx, cron, docker daemon (if any) are started by Ansible
# -----------------------------------------------------------------------------
CMD ["/usr/sbin/sshd", "-D"]
