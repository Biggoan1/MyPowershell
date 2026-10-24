# MyPowershell — FAFO Lab Windows provisioning

Provisioning scripts for the unattended Windows 11 build (pve `/root/isobuild`).

## How it works
The Win11 unattended ISO bakes in **`Bootstrap.ps1`**, which at first-logon pulls the
latest **`Install-Apps.ps1`** from this repo (raw `main`) and runs it — with the baked
copy as an offline fallback. **So to change provisioning, just edit `Install-Apps.ps1`
and push here — no ISO rebuild needed.**

## Quick start on an existing box (no reimage)
Both from an **elevated** PowerShell. Order matters only if you want to watch the second one over ssh.

1. Fleet SSH (OpenSSH Server + the jumpbox key for local admins, PowerShell as the ssh shell).
   Served LAN/VPN-only from the jumpbox because it carries the fleet public key:
   ```powershell
   irm http://10.100.0.245:7790/Install-FafoSsh.ps1 -OutFile $env:TEMP\fafo.ps1
   powershell -ExecutionPolicy Bypass -File $env:TEMP\fafo.ps1 -DefaultShellPowerShell
   ```
   It prints the login to use at the end (`ssh <user>@<box>`) — that is the account to give the jumpbox.
2. The app/provisioning script itself (same thing a fresh image runs at first logon):
   ```powershell
   irm https://raw.githubusercontent.com/Biggoan1/MyPowershell/main/Install-Apps.ps1 -OutFile $env:TEMP\Install-Apps.ps1
   powershell -ExecutionPolicy Bypass -File $env:TEMP\Install-Apps.ps1
   ```
   Logs land in `C:\Distrib\Logs\Install-Apps.log`. It reboots at the end.

## Files
- `Install-Apps.ps1` — post-image provisioning: winget apps (`$Apps`: VirtIO, 7-Zip, Notepad++,
  PowerShell 7, ProcMon, Windows Terminal, CMTrace Open + `.log` association, **WireGuard**),
  **Windows Terminal provisioned machine-wide** (Phase 1c: winget only installs it for the user
  running the script, so the release PreinstallKit is also added with `Add-AppxProvisionedPackage`
  — every later profile gets Terminal too; flag `$ProvisionTerminal`), Node.js + Claude Code,
  OpenSSH Server (sshd + jumpbox key), Explorer/menu tweaks, debloat (keep-list in Phase 4 —
  Terminal is on it). Reboots at the end to finalize the OpenSSH FoD.
- `Bootstrap.ps1` — tiny fetch-and-run shim baked into the ISO (rarely changes).

## Rebuild the ISO (only when Bootstrap.ps1 or the autounattend changes)
The build tree `/root/isobuild` lived on the Dell 5820 Proxmox host, which was retired on
2026-10-23 (its NVMe reused); re-home it on `ai3` (`ssh root@10.100.0.13`) before the next rebuild.
