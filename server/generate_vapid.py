"""
One-time setup: generates a VAPID keypair for Web Push and saves the private
key to vapid_private.pem next to this script. Run once per deployment (local
dev or a fresh VPS) — re-running overwrites the key and invalidates every
existing push subscription, so don't run it casually on a live server.

Usage:
    PythonEmbed312\\python.exe generate_vapid.py
"""
import base64
import os

from py_vapid import Vapid02
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat

PRIV_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vapid_private.pem")

if os.path.exists(PRIV_PATH):
    print(f"{PRIV_PATH} already exists — refusing to overwrite (delete it first if you really want a new key).")
    raise SystemExit(1)

v = Vapid02()
v.generate_keys()
v.save_key(PRIV_PATH)

raw = v.public_key.public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)
pub_b64url = base64.urlsafe_b64encode(raw).rstrip(b"=").decode()

print("VAPID key generated.")
print("Private key saved to:", PRIV_PATH)
print("Public key (served automatically at GET /api/push/vapid_public_key):", pub_b64url)
