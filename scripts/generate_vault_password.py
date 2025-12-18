#!/usr/bin/env python3
"""
===============================================================================
Generate Ansible Vault Password (Secure & CI/CD Friendly)
-------------------------------------------------------------------------------
Purpose:
  - Generate a strong random password for Ansible Vault
  - Output is safe for CLI, CI pipelines, and password files

Usage:
  python3 scripts/generate_vault_password.py
  python3 scripts/generate_vault_password.py > .vault_pass.txt
===============================================================================
"""

import secrets
import string
import sys

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
PASSWORD_LENGTH = 32

# Characters chosen to avoid shell-breaking issues
ALPHABET = (
    string.ascii_letters +
    string.digits +
    "!@#%^_-+="
)

# ------------------------------------------------------------------------------
# Generate password
# ------------------------------------------------------------------------------
def generate_password(length: int) -> str:
    return "".join(secrets.choice(ALPHABET) for _ in range(length))

def main():
    try:
        password = generate_password(PASSWORD_LENGTH)
        print(password)
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
