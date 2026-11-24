"""Convert a PKCS#1 PEM private key to OpenSSH format.

Windows OpenSSH rejects BEGIN RSA PRIVATE KEY (identity type -1).
Prints nothing except the output path.

Usage: python prepare_ssh_key.py <input.pem> <output-key>
"""

import sys
from pathlib import Path

from cryptography.hazmat.primitives import serialization


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: prepare_ssh_key.py <input.pem> <output-key>", file=sys.stderr)
        return 2
    source = Path(sys.argv[1])
    target = Path(sys.argv[2])
    key = serialization.load_pem_private_key(source.read_bytes(), password=None)
    payload = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.OpenSSH,
        encryption_algorithm=serialization.NoEncryption(),
    )
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(payload)
    print(target)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
