### SSH key pair Generation.

#### 1. Windows (PowerShell, with OpenSSH built-in)
```sh
ssh-keygen -t ed25519 -C "trst_dev_23187" -f $env:USERPROFILE\.ssh\id_ed25519_trst_dev_23187
```
#### 1. PuTTYgen
1. Open PuTTYgen → choose Ed25519 → Generate.
2. Set Key comment to USERNAME.
3. Optionally set a passphrase.
4. Click Save private key and Save public key.
5. Copy the OpenSSH format from the top box if needed for authorized_keys.
