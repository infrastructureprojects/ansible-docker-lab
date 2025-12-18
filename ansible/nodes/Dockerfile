FROM ubuntu:22.04

###############################################################################
# 🌍 Build arguments (MUST be passed from docker-compose)
###############################################################################
ARG APP_USER

###############################################################################
# 🌍 Runtime environment variables
###############################################################################
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/${APP_USER}

###############################################################################
# ❗ Validate build argument (STRICT MODE)
###############################################################################
RUN test -n "$APP_USER" || (echo "ERROR: APP_USER is not set" && exit 1)

###############################################################################
# 📦 Install required packages
###############################################################################
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    python3 \
    curl \
    vim \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

###############################################################################
# 🔧 Prepare SSH runtime directory + generate host keys (MANDATORY)
###############################################################################
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A

###############################################################################
# 👤 Create environment-specific non-root user
###############################################################################
RUN useradd -m -s /bin/bash ${APP_USER} && \
    echo "${APP_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${APP_USER} && \
    chmod 0440 /etc/sudoers.d/${APP_USER} && \
    mkdir -p ${HOME}/.ssh && \
    chmod 700 ${HOME}/.ssh && \
    chown -R ${APP_USER}:${APP_USER} ${HOME}

###############################################################################
# 🔐 SSH hardening
###############################################################################
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's@#AuthorizedKeysFile.*@AuthorizedKeysFile .ssh/authorized_keys@' /etc/ssh/sshd_config

###############################################################################
# 🌐 Expose SSH
###############################################################################
EXPOSE 22

###############################################################################
# ▶ Start SSH daemon (MUST run as root)
###############################################################################
CMD ["/usr/sbin/sshd", "-D"]
