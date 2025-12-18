FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

###############################################################################
# 🔧 Build-time arguments
###############################################################################
ARG APP_USER
ARG APP_UID=1000
ARG APP_GID=1000

###############################################################################
# 🌍 Runtime environment variables
###############################################################################
ENV APP_USER=${APP_USER}
ENV HOME=/home/${APP_USER}

###############################################################################
# 📦 Install required packages
###############################################################################
RUN apt-get update && apt-get install -y \
    ansible \
    openssh-client \
    python3 \
    vim \
    git \
    curl \
    sudo \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

###############################################################################
# 👤 Create non-root Ansible user
###############################################################################
RUN groupadd -g ${APP_GID} ${APP_USER} && \
    useradd -m -u ${APP_UID} -g ${APP_GID} -s /bin/bash ${APP_USER} && \
    echo "${APP_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${APP_USER} && \
    chmod 0440 /etc/sudoers.d/${APP_USER}

###############################################################################
# 📁 Prepare directories using $HOME (CORRECT)
###############################################################################
RUN mkdir -p \
      $HOME/ansible \
      $HOME/.ansible \
      $HOME/.ssh && \
    chmod 700 $HOME/.ssh && \
    chown -R ${APP_USER}:${APP_USER} $HOME

###############################################################################
# 🔑 Switch to non-root user
###############################################################################
USER ${APP_USER}
WORKDIR $HOME/ansible
