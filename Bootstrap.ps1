#Requires -RunAsAdministrator
<#
    Bootstrap.ps1  -  baked into the unattended Win11 ISO; runs once at first-logon.
    ------------------------------------------------------------------------------
    Pulls the LATEST Install-Apps.ps1 from git and runs it, so provisioning can be
    updated by pushing to the repo -- no ISO rebuild. Falls back to the copy baked
    into the ISO if the network / repo is unreachable.

    Repo:  https://github.com/Biggoan1/MyPowershell   (raw main branch)
#>

$ErrorActionPreference = 'Continue'
$RawUrl = 'https://raw.githubusercontent.com/Biggoan1/MyPowershell/main/Install-Apps.ps1'
$ScriptDir = 'C:\Distrib\Scripts'
$LogDir    = 'C:\Distrib\Logs'
$Dest      = Join-Path $ScriptDir 'Install-Apps.ps1'   # baked fallback + download target
$Log       = Join-Path $LogDir   'bootstrap.log'
New-Item -ItemType Directory -Path $ScriptDir, $LogDir -Force | Out-Null
function Log($m) { "$(Get-Date -Format o)  $m" | Tee-Object -FilePath $Log -Append | Write-Host }

Log "=== bootstrap start ==="

# First-logon runs before DHCP/DNS are guaranteed -- wait for real connectivity to GitHub.
$deadline = (Get-Date).AddSeconds(180)
$online = $false
while ((Get-Date) -lt $deadline) {
    try { $online = Test-NetConnection raw.githubusercontent.com -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue } catch { $online = $false }
    if ($online) { break }
    Start-Sleep -Seconds 5
}
Log ("network to raw.githubusercontent.com:443 = {0}" -f $online)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
$pulled = $false
if ($online) {
    try {
        $tmp = "$Dest.new"
        Invoke-WebRequest -Uri $RawUrl -OutFile $tmp -UseBasicParsing -TimeoutSec 90
        if ((Test-Path $tmp) -and (Get-Item $tmp).Length -gt 500) {
            Move-Item $tmp $Dest -Force
            $pulled = $true
            Log "pulled latest Install-Apps.ps1 from git ($((Get-Item $Dest).Length) bytes)"
        } else {
            Log "download too small / empty - keeping baked copy"
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Log "git pull FAILED: $($_.Exception.Message) - falling back to baked copy"
    }
} else {
    Log "no network - falling back to baked copy"
}

if (Test-Path $Dest) {
    Log ("running Install-Apps.ps1 ({0})" -f $(if ($pulled) { 'from git' } else { 'baked fallback' }))
    & powershell.exe -ExecutionPolicy Bypass -NoProfile -File $Dest
    Log "Install-Apps.ps1 exited ($LASTEXITCODE)"
} else {
    Log "FATAL: no Install-Apps.ps1 available (git failed and no baked copy present)"
}
Log "=== bootstrap end ==="
