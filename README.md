# Ansible Docker Lab (Production-Style) — Complete Guide

This repository provides a **production-style Ansible lab** using **Docker containers as destination nodes**:

- **1 Control Node**: `ansible-master` (runs Ansible)
- **4 Managed Nodes**: `dev-node`, `sit-node`, `uat-node`, `prod-node` (SSH-accessible containers)
- **No systemd inside destination nodes** (containers)
  - Services like **NGINX** and **cron** are started using **container-safe commands**, not `systemctl`
  - Docker daemon (`dockerd`) inside containers is **optional** and requires **privileged mode** (disabled by default)

The lab is designed to explore **all core Ansible components**:
- Inventory, Playbooks, Modules, Roles, Tasks, Handlers, Variables, Facts, Plugins
- Debugging and validation patterns
- Vault password generation via a Python utility
- Passwordless SSH bootstrap from control node to managed nodes

---

## 1) Pre-requisites — Software Installation & Setup

Install these on your **local host system** (Windows/macOS/Linux):

### 1. Docker Engine
- Required to run containers.

**Verify:**
```bash
docker --version
docker ps
```

### 2. Docker Compose
- Required to orchestrate multi-container topology.

**Verify:**
```bash
docker compose version
```

### 3. Git (recommended)
- For cloning and version control.

**Verify:**
```bash
git --version
```

### 4. Optional Tools
- VS Code (YAML, Dockerfiles, Ansible editing)
- Python 3 on host (optional; you can run the generator inside `ansible-master`)

---

## 2) Complete Folder Structure (Final)

```text
ansible-docker-lab/
│
├── README.md
├── ansible.cfg
├── requirements.yml
├── docker-compose.yml
│
├── docker/
│   ├── ansible-master/
│   │   └── Dockerfile
│   └── nodes/
│       └── Dockerfile
│
├── inventory/
│   └── hosts.ini
│
├── group_vars/
│   ├── all.yml
│   ├── dev.yml
│   ├── sit.yml
│   ├── uat.yml
│   └── prod.yml
│
├── playbooks/
│   ├── site.yml
│   ├── verify.yml
│   └── bootstrap.yml
│
├── plugins/
│   ├── filter/
│   │   └── env_filters.py
│   └── callback/
│       └── pretty_log.py
│
├── roles/
│   ├── users/
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   └── tasks/main.yml
│   ├── common/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   ├── packages/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   ├── users_extended/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   ├── filesystem/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   ├── nginx/
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   ├── tasks/main.yml
│   │   └── templates/default.conf.j2
│   ├── docker/
│   │   ├── defaults/main.yml
│   │   ├── handlers/main.yml
│   │   └── tasks/main.yml
│   ├── app_config/
│   │   ├── defaults/main.yml
│   │   ├── tasks/main.yml
│   │   └── templates/app.conf.j2
│   ├── cron_jobs/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   ├── monitoring_agent/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   └── validation/
│       └── tasks/main.yml
│
├── scripts/
│   ├── bootstrap_ssh.sh
│   └── generate_vault_password.py
│
├── vault/
│   └── secrets.yml
│
└── .gitignore
```

---

## 3) Ansible Components — Detailed Explanation

### A) Inventory (`inventory/hosts.ini`)
Inventory defines:
- **hosts** (dev/sit/uat/prod)
- **groups** (dev, sit, uat, prod)
- connection settings like `ansible_user`, interpreter, SSH args

Key outcomes:
- Run automation per environment group
- Use `--limit` to safely target only one environment

### B) Variables (`group_vars/*` + role defaults)
This lab follows production best practices:
- Environment-specific values in `group_vars/dev.yml`, `group_vars/prod.yml`, etc.
- Shared/global values in `group_vars/all.yml`
- Safe role defaults in `roles/<role>/defaults/main.yml`

Why it matters:
- Same playbook behaves differently per environment without duplication
- Keeps roles reusable and clean

### C) Playbooks (`playbooks/*.yml`)
- `playbooks/site.yml`: orchestrates all roles in correct sequence
- `playbooks/verify.yml`: post-execution validation checks
- `playbooks/bootstrap.yml`: optional bootstrap actions

### D) Roles (`roles/*`)
Roles represent modular features (users, packages, nginx, app config, etc.).
Each role contains:
- `defaults/`: safe defaults users can override
- `tasks/`: actual automation steps
- `handlers/`: triggered actions (e.g., nginx reload on config change)
- `templates/`: Jinja2 configs generated per environment

### E) Modules (Ansible built-ins)
Roles use standard modules:
- `apt`, `user`, `file`, `template`, `cron`, `stat`, `fail`, `debug`, `command`, `shell`
These modules deliver:
- idempotency (safe re-runs)
- predictable state management

### F) Facts (gathered system information)
Facts are collected at play start (`gather_facts: true`):
- OS family, network facts, container detection, etc.
Used for:
- conditional execution
- debugging

### G) Plugins (`plugins/`)
- Filter plugin: custom filter `pretty_env` to format environment names
- Callback plugin: produces “good looking” logs for successful/failed tasks

---

## 4) Detailed Role-by-Role Explanation (Execution Flow)

The main playbook applies roles in this order:

```yaml
roles:
  - users
  - common
  - packages
  - users_extended
  - filesystem
  - nginx
  - docker
  - app_config
  - cron_jobs
  - monitoring_agent
  - validation
```

### 4.1 `users`
- Ensures baseline SSH user exists (`ssh_user`, typically `ansible`)
- Ensures passwordless sudo for SSH user

### 4.2 `common`
- Creates baseline directories like `/var/log/lab`
- Writes a metadata file: `/var/log/lab/lab-info.txt` with env & host info

### 4.3 `packages`
- Installs common base packages across all nodes
- Adds optional env-specific packages (`packages_extra`)

### 4.4 `users_extended`
- Creates additional user(s) like `app_user`
- Grants passwordless sudo if required

### 4.5 `filesystem`
- Creates app directories:
  - `/opt/app`
  - `/opt/app/logs`
  - `/opt/app/data`
- Sets ownership to `app_user`

### 4.6 `nginx` (container-safe, no systemd)
- Installs nginx
- Deploys Jinja2 config (port varies by env)
- Starts nginx using `nginx` command if not running
- Uses handler to reload nginx via `nginx -s reload`

### 4.7 `docker` (container-safe)
- Installs Docker package (CLI)
- Prints docker version
- Optionally tries to start `dockerd` only if enabled and container is privileged

### 4.8 `app_config`
- Writes application config file `/opt/app/app.conf` using Jinja2 template
- Includes env_name, app_user, host, owner

### 4.9 `cron_jobs` (container-safe)
- Installs cron
- Starts cron via `cron` command if not running
- Adds scheduled cleanup job for `/tmp`

### 4.10 `monitoring_agent`
- Installs lightweight monitoring tools
- Captures health snapshot (uptime, free, df)

### 4.11 `validation`
- Validates app directory exists
- Validates app config exists
- Validates nginx is running and returns HTTP 200 (if enabled)

---

## 5) Docker & Docker Compose — Initial Setup + Commands

### 5.1 Build the images
From project root (host machine):
```bash
docker compose build
```

### 5.2 Start containers (detached)
```bash
docker compose up -d
```

### 5.3 Check status
```bash
docker ps
docker compose ps
```

### 5.4 View logs (optional)
```bash
docker compose logs -f
```

### 5.5 Stop and remove
```bash
docker compose down
```

### 5.6 Clean rebuild (fresh)
```bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

---

## 6) docker-compose.yml — Detailed Explanation

Key concepts:
- One bridge network `ansible-net` for DNS-based service discovery
- Container names match inventory hostnames (`dev-node`, `sit-node`, etc.)
- `ansible-master` mounts the repo into `/lab`
- SSH keys persist using a named volume `ansible_ssh` mounted at `/root/.ssh`

Typical blocks:
- `build`: builds from local Dockerfiles
- `networks`: ensures containers communicate
- `volumes`: persists SSH keys between restarts
- `depends_on`: starts managed nodes before ansible-master

---

## 7) Dockerfiles — Detailed Explanation

### 7.1 docker/ansible-master/Dockerfile (Control Node)
Purpose:
- Installs Ansible + tooling
- Includes SSH client and `sshpass` for first-time bootstrap
- Copies lab repository into `/lab`
- Supports plugins and fact caching

Important packages:
- `python3`, `pip`, `openssh-client`, `sshpass`, `ansible`, `ansible-lint`

No systemd:
- Control node runs interactive shell (`/bin/bash`)

### 7.2 docker/nodes/Dockerfile (Managed Nodes)
Purpose:
- Provides SSH server (`sshd`) for Ansible connections
- Provides Python3 for Ansible modules
- Provides sudo permissions
- Avoids systemd completely

Key design:
- `sshd` runs in the foreground as container CMD
- Services (nginx/cron) are started by Ansible tasks using container-safe commands

---

## 8) Ansible Commands — Full Execution

### 8.1 Enter ansible-master container
```bash
docker exec -it ansible-master bash
cd /lab
```

### 8.2 (Optional) Install collections
```bash
ansible-galaxy collection install -r requirements.yml
```

### 8.3 Bootstrap passwordless SSH (REQUIRED first run)
```bash
bash scripts/bootstrap_ssh.sh
```

### 8.4 Validate connectivity (ping module)
```bash
ansible -i inventory/hosts.ini all -m ping
```

### 8.5 Run complete deployment
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

### 8.6 Run verification playbook
```bash
ansible-playbook -i inventory/hosts.ini playbooks/verify.yml
```

### 8.7 Run only one environment group
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --limit dev
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --limit prod
```

---

## 9) Debug & Troubleshooting Commands (Production-Grade)

### 9.1 Increase verbosity
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -vv
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -vvv
```

### 9.2 Check mode (dry run)
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check
```

### 9.3 Diff mode (see config changes)
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --diff
```

### 9.4 List tasks and tags
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --list-tasks
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --list-tags
```

### 9.5 Inventory graph (group validation)
```bash
ansible-inventory -i inventory/hosts.ini --graph
```

### 9.6 Debug variables (helpful for undefined var issues)
```bash
ansible -i inventory/hosts.ini all -m debug -a "var=env_name"
ansible -i inventory/hosts.ini all -m debug -a "var=app_user"
ansible -i inventory/hosts.ini all -m debug -a "var=nginx_port"
```

### 9.7 Facts debugging
```bash
ansible -i inventory/hosts.ini all -m setup
ansible -i inventory/hosts.ini all -m setup -a "filter=ansible_distribution*"
ansible -i inventory/hosts.ini all -m setup -a "filter=ansible_virtualization*"
```

### 9.8 Ad-hoc commands to quickly test nodes
```bash
ansible -i inventory/hosts.ini all -a "hostname"
ansible -i inventory/hosts.ini all -a "whoami"
ansible -i inventory/hosts.ini all -b -a "id {{ app_user }}"
```

---

## 10) Vault Password Generation + Encryption Workflow

### 10.1 Where the script lives
Place it here:
```text
scripts/generate_vault_password.py
```

### 10.2 Generate vault password file (inside ansible-master)
```bash
python3 scripts/generate_vault_password.py > .vault_pass.txt
chmod 600 .vault_pass.txt
```

### 10.3 Create an encrypted vault file
```bash
ansible-vault create vault/secrets.yml --vault-password-file .vault_pass.txt
```

### 10.4 Edit/view vault later
```bash
ansible-vault edit vault/secrets.yml --vault-password-file .vault_pass.txt
ansible-vault view vault/secrets.yml --vault-password-file .vault_pass.txt
```

### 10.5 Use vault in playbook (example)
Add this in your playbook:
```yaml
vars_files:
  - vault/secrets.yml
```

Security best practice:
- Use `no_log: true` on tasks that may print secrets.

---

## 11) bootstrap_ssh.sh — Detailed Explanation

### Purpose
This script runs on `ansible-master` and:
1. Ensures `sshpass` exists (only needed for first-time bootstrap)
2. Creates SSH keypair at `/root/.ssh/id_rsa` if missing
3. Copies public key into each node’s:
   - `/home/ansible/.ssh/authorized_keys`
4. Validates passwordless SSH connectivity

### Why it’s required
- Ansible uses SSH
- Passwordless SSH is required for automation and CI/CD

### Run it
```bash
bash scripts/bootstrap_ssh.sh
```

If you changed usernames/passwords, run with env vars:
```bash
SSH_USER=ansible SSH_PASSWORD=ansible bash scripts/bootstrap_ssh.sh
```

---

## 12) Verification Inside Destination Nodes (dev/sit/uat/prod)

You can verify in two ways:

### 12.1 Verify via Ansible (recommended)
```bash
# Check nginx process
ansible -i inventory/hosts.ini all -a "pgrep nginx || true"

# Verify nginx HTTP locally on each node (ports differ by env)
ansible -i inventory/hosts.ini dev  -a "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8081"
ansible -i inventory/hosts.ini sit  -a "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8082"
ansible -i inventory/hosts.ini uat  -a "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8083"
ansible -i inventory/hosts.ini prod -a "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080"

# Verify app config file exists
ansible -i inventory/hosts.ini all -a "ls -la /opt/app && cat /opt/app/app.conf"

# Verify cron running (container-safe)
ansible -i inventory/hosts.ini all -a "pgrep cron || true"
```

### 12.2 Verify by entering a node container (manual)
From host machine:
```bash
docker exec -it dev-node bash
```

Inside node:
```bash
hostname
whoami
id ansible
ls -la /opt/app
cat /opt/app/app.conf

# Nginx checks
pgrep nginx || true
nginx -t || true
curl -I http://127.0.0.1:8081 || true

# Cron checks
pgrep cron || true
crontab -l || true
```

Repeat similarly for:
```bash
docker exec -it sit-node bash
docker exec -it uat-node bash
docker exec -it prod-node bash
```

---

## 13) Recommended .gitignore

```gitignore
.vault_pass.txt
*.retry
.facts/
__pycache__/
*.pyc
```

---

## 14) Quick Start (Most Common Commands)

```bash
# Host machine
docker compose build
docker compose up -d
docker exec -it ansible-master bash

# Inside ansible-master
cd /lab
bash scripts/bootstrap_ssh.sh
ansible -i inventory/hosts.ini all -m ping
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
ansible-playbook -i inventory/hosts.ini playbooks/verify.yml
```

---

### End of README
