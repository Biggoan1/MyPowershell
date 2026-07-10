# MyPowershell — FAFO Lab Windows provisioning

Provisioning scripts for the unattended Windows 11 build (pve `/root/isobuild`).

## How it works
The Win11 unattended ISO bakes in **`Bootstrap.ps1`**, which at first-logon pulls the
latest **`Install-Apps.ps1`** from this repo (raw `main`) and runs it — with the baked
copy as an offline fallback. **So to change provisioning, just edit `Install-Apps.ps1`
and push here — no ISO rebuild needed.**

## Files
- `Install-Apps.ps1` — post-image provisioning: winget apps (incl. CMTrace Open + `.log`
  association), Node.js + Claude Code, OpenSSH Server (sshd + jumpbox key), Explorer/menu
  tweaks, debloat. Reboots at the end to finalize the OpenSSH FoD.
- `Bootstrap.ps1` — tiny fetch-and-run shim baked into the ISO (rarely changes).

## Rebuild the ISO (only when Bootstrap.ps1 or the autounattend changes)
`ssh root@10.100.0.213` → `bash /root/isobuild/build.sh` → output on the `ssd` store.
