#!/usr/bin/env python3

import crypt
import getpass
import os
from pathlib import Path

# Ask for password securely
password = getpass.getpass("Enter password to hash: ")

if not password:
    raise SystemExit("ERROR: Password cannot be empty")

# Generate SHA-512 hash
hashed_password = crypt.crypt(
    password,
    crypt.mksalt(crypt.METHOD_SHA512)
)

# Target vault file
vault_dir = Path.home() / "ansible" / "group_vars"
vault_file = vault_dir / "vault.yml"

# Ensure directory exists
vault_dir.mkdir(parents=True, exist_ok=True)

# Write YAML
with open(vault_file, "w") as f:
    f.write(f'user_password: "{hashed_password}"\n')

print(f"\n✅ Password hash written to: {vault_file}")
print("⚠️  IMPORTANT: Encrypt this file using:")
print(f"   ansible-vault encrypt {vault_file}")
