#Requires -RunAsAdministrator
<#
    Install-Apps.ps1  -  Post-image provisioning
    --------------------------------------------
    Runs once on a freshly imaged Windows 11 box and does, in order:
      1. Installs a list of winget apps (silently).
      2. Installs Node.js LTS, then Claude Code globally via npm.
      3. Restores the classic (Windows 10) right-click context menu.
      4. Debloats: removes non-whitelisted Appx packages + Features on Demand.
      5. Writes a detection marker to the registry.

    RUN IT (elevated):
        powershell.exe -ExecutionPolicy Bypass -File .\Install-Apps.ps1

    NOTE: run under Windows PowerShell 5.1 (powershell.exe), NOT pwsh 7 -
    the Appx / DISM cmdlets in the debloat phase are happiest there.

    Toggle the big phases with the switches in the CONFIG block below.
#>

# ============================ CONFIG ============================

# winget IDs to install. (Node.js is handled in the dev phase, not here.)
$Apps = @(
#    'Bambulab.Bambustudio'
    'RedHat.VirtIO'
    '7zip.7zip'
    'Notepad++.Notepad++'
#    'Microsoft.PowerToys'
#    'Greenshot.Greenshot'
    'Microsoft.PowerShell'
    'Microsoft.Sysinternals.ProcessMonitor'
    'Microsoft.Terminal'
    'AdamGell.CMTraceOpen'
#    'Telegram.TelegramDesktop'
#    'Git.Git'
)

# Flip any phase off without deleting code.
$InstallApps           = $true
$InstallNodeAndClaude  = $false
$SetHighPerformance    = $true
$SetExecutionPolicy    = $true
$ExplorerTweaks        = $true
$RestoreClassicMenu    = $true
$RunDebloat            = $true
$ConfigureOpenSSH      = $true
$AssociateCMTraceLogs  = $true
$RebootWhenDone        = $true
$ApplyTerminalAndTheme = $true
$TerminalSettingsUrl   = 'https://raw.githubusercontent.com/Biggoan1/MyPowershell/main/WindowsTerminal/settings.json'

# First-logon fires before the NIC has DHCP/DNS/internet and before winget's
# source is reachable, so wait for real connectivity before the download phases.
$WaitForNetworkSecs    = 180

$Version = '1.2'
$LogFile = 'C:\Distrib\Logs\Install-Apps.log'
$RegPath = 'HKLM:\SOFTWARE\FAFOLAB\Provisioning'

# winget exit codes that are NOT failures (already installed / no upgrade needed).
$BenignWingetCodes = @(0, -1978335189, -1978335212, -1978335215)

# ============================ SETUP ============================

$ErrorActionPreference = 'Continue'
$logDir = Split-Path -Path $LogFile -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
Start-Transcript -Path $LogFile -Append -Force | Out-Null

$script:AppResults  = @()   # @{ Id; Ok }
$script:ExplorerDirty = $false

# ====================== HELPER FUNCTIONS ======================

function Resolve-Winget {
    # Prefer PATH; fall back to the WindowsApps install (needed in SYSTEM / first-logon
    # contexts where winget isn't on PATH yet).
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $exe = Get-ChildItem "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    return $exe
}

function Install-WingetApp {
    param([string]$WingetPath, [string]$Id)

    Write-Host "  installing $Id ..." -ForegroundColor Cyan
    # --source winget: force the community source; the msstore source throws a cert
    # error (0x8a15005e) on fresh images and tanks the whole command.
    & $WingetPath install --id $Id -e --silent --source winget `
        --accept-package-agreements --accept-source-agreements
    $code = $LASTEXITCODE

    $ok = $BenignWingetCodes -contains $code
    if ($ok) {
        Write-Host "    OK: $Id" -ForegroundColor Green
    } else {
        Write-Host "    FAILED ($code): $Id" -ForegroundColor Yellow
    }
    $script:AppResults += [pscustomobject]@{ Id = $Id; Ok = $ok }
}

function Restart-Explorer {
    Write-Host 'Restarting explorer.exe ...'
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer.exe
    }
}

function Set-ExplorerPrefs {
    # Writes the Explorer preferences under the given registry root (reg.exe format),
    # e.g. 'HKCU' for the current user or 'HKU\DefaultProvision' for the default hive.
    param([string]$Root)
    $key = "$Root\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    reg add $key /v HideFileExt     /t REG_DWORD /d 0 /f | Out-Null  # show file extensions
    reg add $key /v Hidden          /t REG_DWORD /d 1 /f | Out-Null  # show hidden files
    reg add $key /v ShowSuperHidden /t REG_DWORD /d 1 /f | Out-Null  # show protected OS files
    reg add $key /v LaunchTo        /t REG_DWORD /d 1 /f | Out-Null  # open Explorer to This PC
}

function Wait-ForNetwork {
    # First-logon runs before the NIC has DHCP/DNS/internet + before winget's
    # source is reachable. Poll for REAL connectivity (ping + DNS resolve) instead
    # of a blind sleep. Returns $true once online, $false on timeout.
    param([int]$TimeoutSec = 180)
    Write-Host "`n=== Waiting for internet connectivity (up to $TimeoutSec s) ===" -ForegroundColor White
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
        $dns  = $false
        try { if (Resolve-DnsName -Name 'www.microsoft.com' -ErrorAction Stop) { $dns = $true } } catch {}
        if ($ping -and $dns) {
            Write-Host 'Internet is up.' -ForegroundColor Green
            Start-Sleep -Seconds 3   # brief settle so winget's source is reachable
            return $true
        }
        Start-Sleep -Seconds 5
    }
    Write-Host "No internet after $TimeoutSec s - continuing anyway (downloads may fail)." -ForegroundColor Yellow
    return $false
}

# ============================ MAIN ============================

try {
    Write-Host ("=== Provisioning v{0} starting ===" -f $Version) -ForegroundColor White

    # ----- Power plan: High Performance -----
    if ($SetHighPerformance) {
        Write-Host "`n=== Power plan: High Performance ===" -ForegroundColor White
        $hpGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
        powercfg /setactive $hpGuid 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Plan hidden/absent (common on laptops): clone it from the template, then activate.
            powercfg /duplicatescheme $hpGuid 2>$null
            powercfg /setactive $hpGuid 2>$null
        }
        if ($LASTEXITCODE -eq 0) {
            Write-Host 'High Performance plan active.' -ForegroundColor Green
        } else {
            Write-Host 'Could not set High Performance plan.' -ForegroundColor Yellow
        }
    }

    # ----- PowerShell execution policy -----
    if ($SetExecutionPolicy) {
        Write-Host "`n=== PowerShell execution policy: Bypass (LocalMachine) ===" -ForegroundColor White
        try {
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
            Write-Host 'Execution policy set to Bypass.' -ForegroundColor Green
        } catch {
            Write-Host "Could not set execution policy: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Don't touch the internet until the NIC is actually up.
    Wait-ForNetwork -TimeoutSec $WaitForNetworkSecs | Out-Null

    $WingetPath = Resolve-Winget
    if (-not $WingetPath) {
        Write-Host "winget not found. Install 'App Installer' from the Microsoft Store first." -ForegroundColor Red
        return
    }
    Write-Host "Using winget: $WingetPath"

    # Fresh images often have empty/stale winget source data - refresh it.
    Write-Host 'Refreshing winget sources ...'
    & $WingetPath source reset --force 2>&1 | Out-Null
    & $WingetPath source update        2>&1 | Out-Null

    # ----- Phase 1: winget apps -----
    if ($InstallApps) {
        Write-Host "`n=== Phase 1: winget apps ===" -ForegroundColor White
        foreach ($id in $Apps) { Install-WingetApp -WingetPath $WingetPath -Id $id }
    }

    # ----- Phase 1b: CMTrace Open -> default .log viewer -----
    if ($AssociateCMTraceLogs) {
        Write-Host "`n=== Phase 1b: CMTrace .log association ===" -ForegroundColor White
        $cmDir = 'C:\Program Files\CMTraceOpen'
        $cmExe = Join-Path $cmDir 'CMTraceOpen.exe'
        # winget installs CMTrace Open as a versioned *portable* exe; stage it to a stable path.
        $roots = @("$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
                   "$env:ProgramFiles\WinGet\Packages",
                   "${env:ProgramFiles(x86)}\WinGet\Packages") | Where-Object { $_ -and (Test-Path $_) }
        $src = Get-ChildItem -Path $roots -Recurse -Filter 'CMTrace-Open*_x64.exe' -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($src) {
            New-Item -ItemType Directory -Path $cmDir -Force | Out-Null
            Copy-Item $src.FullName $cmExe -Force
            cmd /c "assoc .log=CMTraceOpen.Log" | Out-Null
            cmd /c "ftype CMTraceOpen.Log=`"$cmExe`" `"%1`"" | Out-Null
            New-Item -Path 'HKLM:\SOFTWARE\Classes\CMTraceOpen.Log\shell\open\command' -Force | Out-Null
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Classes\CMTraceOpen.Log' -Name '(default)' -Value 'Log File'
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Classes\CMTraceOpen.Log\shell\open\command' -Name '(default)' -Value ("`"$cmExe`" `"%1`"")
            New-Item -Path 'HKLM:\SOFTWARE\Classes\.log' -Force | Out-Null
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Classes\.log' -Name '(default)' -Value 'CMTraceOpen.Log'
            Write-Host "  .log -> $cmExe" -ForegroundColor Green
        } else {
            Write-Host '  CMTrace Open exe not found (winget install may have failed) - skipped.' -ForegroundColor Yellow
        }
    }

    # ----- Phase 2: Node.js LTS + Claude Code -----
    if ($InstallNodeAndClaude) {
        Write-Host "`n=== Phase 2: Node.js + Claude Code ===" -ForegroundColor White

        $nodeInstalled = Get-ChildItem `
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' `
                -ErrorAction SilentlyContinue |
            Get-ItemProperty |
            Where-Object { $_.DisplayName -like '*Node.js*' } |
            Select-Object -First 1

        if (-not $nodeInstalled) {
            Write-Host 'Installing Node.js LTS ...'
            & $WingetPath install --id OpenJS.NodeJS.LTS -e --silent --source winget `
                --accept-package-agreements --accept-source-agreements
            if (-not ($BenignWingetCodes -contains $LASTEXITCODE)) {
                Write-Host "Node.js install failed ($LASTEXITCODE) - skipping Claude Code." -ForegroundColor Yellow
            }
            # Refresh PATH into this session so npm resolves immediately.
            $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                        [Environment]::GetEnvironmentVariable('Path', 'User')
        } else {
            Write-Host "Node.js already present: $($nodeInstalled.DisplayVersion)"
        }

        # Locate npm.
        $npmCmd = "$env:ProgramFiles\nodejs\npm.cmd"
        if (-not (Test-Path $npmCmd)) { $npmCmd = (Get-Command npm -ErrorAction SilentlyContinue).Source }

        if ($npmCmd -and (Test-Path $npmCmd)) {
            Write-Host "Installing @anthropic-ai/claude-code via npm ..."
            & $npmCmd install -g '@anthropic-ai/claude-code'
            if ($LASTEXITCODE -ne 0) {
                Write-Host "npm install failed ($LASTEXITCODE)." -ForegroundColor Yellow
            } else {
                # Make sure npm's global bin is on the user PATH so 'claude' resolves.
                $npmBinDir = "$env:APPDATA\npm"
                $userPath  = [Environment]::GetEnvironmentVariable('Path', 'User')
                if ($userPath -notlike "*$npmBinDir*") {
                    $newPath = if ($userPath) { "$userPath;$npmBinDir" } else { $npmBinDir }
                    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
                    Write-Host "Added $npmBinDir to user PATH (new terminal needed for 'claude')."
                }
                Write-Host 'Claude Code installed.' -ForegroundColor Green
            }
        } else {
            Write-Host 'npm not found - skipping Claude Code.' -ForegroundColor Yellow
        }
    }

    # ----- Phase 2b: OpenSSH Server (Win32-OpenSSH GitHub zip, not the slow WU FoD) + jumpbox key -----
    if ($ConfigureOpenSSH) {
        Write-Host "`n=== Phase 2b: OpenSSH Server ===" -ForegroundColor White
        # Pull the Win32-OpenSSH release zip straight from GitHub (~5MB, seconds) and register
        # sshd with install-sshd.ps1. No winget package (none reliably exists), no Windows Update,
        # no reboot. Config dir is still C:\ProgramData\ssh.
        $osshDir = Join-Path $env:ProgramFiles 'OpenSSH'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $zipUrl = $null
        try {
            $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/latest' `
                     -UseBasicParsing -Headers @{ 'User-Agent' = 'fafolab-provision' } -TimeoutSec 30
            $zipUrl = ($rel.assets | Where-Object { $_.name -eq 'OpenSSH-Win64.zip' } | Select-Object -First 1).browser_download_url
        } catch { }
        if (-not $zipUrl) { $zipUrl = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip' }
        try {
            Write-Host "  downloading Win32-OpenSSH: $zipUrl"
            $zip = Join-Path $env:TEMP 'OpenSSH-Win64.zip'
            Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing -TimeoutSec 120
            $ex = Join-Path $env:TEMP 'osshx'
            Remove-Item $ex -Recurse -Force -ErrorAction SilentlyContinue
            Expand-Archive -Path $zip -DestinationPath $ex -Force
            $inner = Get-ChildItem $ex -Directory | Select-Object -First 1   # OpenSSH-Win64\
            New-Item -ItemType Directory -Path $osshDir -Force | Out-Null
            Copy-Item (Join-Path $inner.FullName '*') $osshDir -Recurse -Force
            Write-Host "  OpenSSH binaries -> $osshDir" -ForegroundColor Green
        } catch {
            Write-Host "  OpenSSH download/extract FAILED: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        $sshdSetup = Join-Path $osshDir 'install-sshd.ps1'
        if (Test-Path $sshdSetup) {
            & powershell.exe -ExecutionPolicy Bypass -NoProfile -File $sshdSetup | Out-Null
            Write-Host '  sshd service registered (install-sshd.ps1)' -ForegroundColor Green
        } else {
            Write-Host '  install-sshd.ps1 not found - OpenSSH download may have failed.' -ForegroundColor Yellow
        }
        Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue
        # default shell -> Windows PowerShell
        New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell `
            -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force | Out-Null
        # firewall (the winget build may not add one)
        if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
                -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
        }
        Set-NetFirewallRule -DisplayName 'OpenSSH SSH Server (sshd)' -Profile Any -ErrorAction SilentlyContinue
        Start-Service sshd -ErrorAction SilentlyContinue
        Restart-Service sshd -ErrorAction SilentlyContinue
        # jumpbox / fleet key -> admin logins use administrators_authorized_keys
        $akf = 'C:\ProgramData\ssh\administrators_authorized_keys'
        $pub = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsqdUWpUrTO6Qtv8Jq13QtHGcWLYgZzKLGcbtRcP+vu jumpbox-dashboard'
        New-Item -ItemType Directory -Path (Split-Path $akf) -Force | Out-Null
        $have = if (Test-Path $akf) { Get-Content $akf -Raw } else { '' }
        if ($have -notmatch 'OsqdUWpUrTO6Qtv8Jq13QtHGcWLYgZzKLGcbtRcP\+vu') {
            Add-Content -Path $akf -Value $pub -Encoding ascii
        }
        icacls $akf /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
        Write-Host ("  sshd: " + (Get-Service sshd).Status + " / " + (Get-Service sshd).StartType) -ForegroundColor Green
    }

    # ----- Phase 3: classic right-click context menu -----
    if ($RestoreClassicMenu) {
        Write-Host "`n=== Phase 3: classic context menu ===" -ForegroundColor White
        $clsid     = '{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
        $clsidKey  = "HKCU:\Software\Classes\CLSID\$clsid"
        $inprocKey = "$clsidKey\InprocServer32"
        try {
            if (-not (Test-Path $clsidKey)) {
                New-Item -Path 'HKCU:\Software\Classes\CLSID' -Name $clsid -Force | Out-Null
            }
            New-Item -Path $clsidKey -Name 'InprocServer32' -Value '' -Force | Out-Null
            $script:ExplorerDirty = $true
            Write-Host 'Classic context menu enabled.' -ForegroundColor Green
        } catch {
            Write-Host "Context menu tweak failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # ----- Explorer / shell preferences -----
    if ($ExplorerTweaks) {
        Write-Host "`n=== Explorer preferences ===" -ForegroundColor White

        # Current user (Admin).
        Set-ExplorerPrefs -Root 'HKCU'

        # Default profile, so every future user inherits these. Use reg.exe (not the
        # registry provider) so the hive unloads cleanly without leaked handles.
        $defaultHive = 'C:\Users\Default\NTUSER.DAT'
        if (Test-Path $defaultHive) {
            reg load 'HKU\DefaultProvision' $defaultHive | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Set-ExplorerPrefs -Root 'HKU\DefaultProvision'
                reg unload 'HKU\DefaultProvision' | Out-Null
            } else {
                Write-Host '  (could not load default hive - applied to current user only)' -ForegroundColor Yellow
            }
        }

        $script:ExplorerDirty = $true
        Write-Host 'Explorer preferences applied.' -ForegroundColor Green
    }

    # ----- Phase 3b: Windows Terminal settings + Windows dark theme -----
    if ($ApplyTerminalAndTheme) {
        Write-Host "`n=== Phase 3b: Windows Terminal + dark theme ===" -ForegroundColor White

        # Seed Windows Terminal settings.json (pulled from the repo) for the current
        # admin AND the Default user profile so future users inherit it.
        $wtPkg = 'Microsoft.WindowsTerminal_8wekyb3d8bbwe'
        $wtTargets = @(
            (Join-Path $env:LOCALAPPDATA "Packages\$wtPkg\LocalState"),
            "C:\Users\Default\AppData\Local\Packages\$wtPkg\LocalState"
        )
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $wt = Invoke-WebRequest -Uri $TerminalSettingsUrl -UseBasicParsing -TimeoutSec 30
            if ($wt.Content -and $wt.Content.Length -gt 50) {
                foreach ($t in $wtTargets) {
                    New-Item -ItemType Directory -Path $t -Force | Out-Null
                    [IO.File]::WriteAllText((Join-Path $t 'settings.json'), $wt.Content)
                    Write-Host "  WT settings -> $t" -ForegroundColor Green
                }
            } else {
                Write-Host '  WT settings download empty - skipped.' -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  WT settings fetch failed: $($_.Exception.Message) - skipped." -ForegroundColor Yellow
        }

        # Per-user setup for current user + the Default profile (future users):
        #   - Default terminal application = Windows Terminal (Console\%%Startup delegation GUIDs)
        #   - Desktop wallpaper = Windows dark default (img19.jpg)
        # (Windows dark-MODE toggling intentionally left out - set it via the OS if wanted.)
        # reg.exe root: 'HKCU' for current user, 'HKU\DefProv' for the loaded Default hive.
        $wallpaper = 'C:\Windows\Web\Wallpaper\Windows\img19.jpg'
        function Set-Personalization([string]$Root) {
            $cons = "$Root\Console\%%Startup"
            reg add $cons /v DelegationConsole  /t REG_SZ /d "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}" /f | Out-Null
            reg add $cons /v DelegationTerminal /t REG_SZ /d "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}" /f | Out-Null
            $desk = "$Root\Control Panel\Desktop"
            reg add $desk /v Wallpaper      /t REG_SZ /d "C:\Windows\Web\Wallpaper\Windows\img19.jpg" /f | Out-Null
            reg add $desk /v WallpaperStyle /t REG_SZ /d "10" /f | Out-Null
            reg add $desk /v TileWallpaper  /t REG_SZ /d "0"  /f | Out-Null
        }
        Set-Personalization 'HKCU'
        $defHive = 'C:\Users\Default\NTUSER.DAT'
        if (Test-Path $defHive) {
            reg load 'HKU\DefProv' $defHive | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Set-Personalization 'HKU\DefProv'
                [gc]::Collect(); Start-Sleep -Milliseconds 500
                reg unload 'HKU\DefProv' | Out-Null
            }
        }

        # Apply the wallpaper now for the current user (SPI_SETDESKWALLPAPER = 0x0014).
        $sig = '[DllImport("user32.dll",SetLastError=true,CharSet=CharSet.Auto)] public static extern bool SystemParametersInfo(uint uiAction,uint uiParam,string pvParam,uint fWinIni);'
        try {
            $u = Add-Type -MemberDefinition $sig -Name WinApiWp -Namespace Native -PassThru -ErrorAction Stop
            $u::SystemParametersInfo(0x0014, 0, $wallpaper, 3) | Out-Null
        } catch { }

        $script:ExplorerDirty = $true
        Write-Host 'Applied: WT default terminal + dark wallpaper.' -ForegroundColor Green
    }

    # ----- Phase 4: debloat -----
    if ($RunDebloat) {
        Write-Host "`n=== Phase 4: debloat ===" -ForegroundColor White

        # Apps to KEEP; everything else (incl. Bing*, Xbox*, Teams, Widgets, DevHome,
        # YourPhone, Solitaire, QuickAssist, CrossDevice, new Outlook, ...) gets removed.
        $WhiteListedApps = @(
            'Microsoft.DesktopAppInstaller','Microsoft.WindowsStore','Microsoft.StorePurchaseApp',
            'Microsoft.WindowsTerminal','Microsoft.WindowsNotepad','Microsoft.Paint',
            'Microsoft.ScreenSketch','Microsoft.WindowsCalculator','Microsoft.Windows.Photos',
            'Microsoft.WindowsSoundRecorder','Microsoft.SecHealthUI','Microsoft.MicrosoftEdge.Stable',
            'Microsoft.ApplicationCompatibilityEnhancements',
            'Microsoft.HEIFImageExtension','Microsoft.HEVCVideoExtension','Microsoft.VP9VideoExtensions',
            'Microsoft.WebMediaExtensions','Microsoft.WebpImageExtension','Microsoft.RawImageExtension',
            'Microsoft.AV1VideoExtension','Microsoft.AVCEncoderVideoExtension','Microsoft.MPEG2VideoExtension'
        )
        function Test-Whitelisted {
            param([string]$Name)
            foreach ($pattern in $WhiteListedApps) { if ($Name -like $pattern) { return $true } }
            return $false
        }

        Write-Host '--- Appx packages ---'
        # Iterate the PROVISIONED list directly so bloat is stripped from the image (new
        # users) and before it finishes installing for the current user. The old loop only
        # touched already-installed bundles, which on first-logon missed almost everything.
        foreach ($pp in (Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)) {
            if (Test-Whitelisted $pp.DisplayName) { continue }
            Remove-AppxProvisionedPackage -Online -PackageName $pp.PackageName -ErrorAction SilentlyContinue | Out-Null
            if ($?) { Write-Host "  removed provisioned:  $($pp.DisplayName)" }
            else    { Write-Host "  skip (not removable): $($pp.DisplayName)" -ForegroundColor DarkGray }
        }
        # Also strip any already-installed instances (all users).
        foreach ($app in (Get-AppxPackage -PackageTypeFilter Bundle -AllUsers -ErrorAction SilentlyContinue | Sort-Object Name -Unique)) {
            if (Test-Whitelisted $app.Name) { continue }
            Get-AppxPackage -Name $app.Name -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        }

        Write-Host '--- Features on Demand ---'
        $WhiteListOnDemand = @(
            'NetFX3','Tools.Graphics.DirectX','Tools.DeveloperMode.Core','Language',
            'ContactSupport','OneCoreUAP','Media.WindowsMediaPlayer',
            'Microsoft.Windows.MSPaint','Microsoft.Windows.Notepad',
            'Microsoft.Windows.PowerShell.ISE','Microsoft.Windows.WordPad',
            'Print.Fax.Scan','Print.Management.Console','Windows.Client.ShellComponents',
            'OpenSSH.Client~~~~0.0.1.0','OpenSSH.Server~~~~0.0.1.0','Microsoft.Windows.Sense.Client','VBSCRIPT~~~~'
        ) -join '|'
        try {
            $build = [int](Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber
            $capParams = @{ Online = $true; ErrorAction = 'Stop' }
            if ($build -gt 16299) { $capParams.LimitAccess = $true }

            Get-WindowsCapability @capParams |
                Where-Object { $_.Name -notmatch $WhiteListOnDemand -and $_.State -eq 'Installed' } |
                ForEach-Object {
                    Remove-WindowsCapability -Online -Name $_.Name -ErrorAction SilentlyContinue | Out-Null
                    if ($?) { Write-Host "  removed FoD: $($_.Name)" }
                    else    { Write-Host "  skip FoD (not removable): $($_.Name)" -ForegroundColor DarkGray }
                }
        } catch {
            Write-Host "Listing FoD failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # ----- Detection marker -----
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    Set-ItemProperty -Path $RegPath -Name 'Version' -Value $Version
    Set-ItemProperty -Path $RegPath -Name 'LastRun' -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')

    # ----- Summary -----
    Write-Host "`n==================== Summary ====================" -ForegroundColor White
    if ($InstallApps) {
        $okCount   = ($script:AppResults | Where-Object Ok).Count
        $failApps  = $script:AppResults | Where-Object { -not $_.Ok }
        Write-Host ("winget apps OK : {0}/{1}" -f $okCount, $script:AppResults.Count) -ForegroundColor Green
        if ($failApps) {
            Write-Host ("winget failed  : {0}" -f $failApps.Count) -ForegroundColor Yellow
            $failApps | ForEach-Object { Write-Host "   - $($_.Id)" -ForegroundColor Yellow }
        }
    }

    # One explorer restart at the very end (so the context-menu change takes effect).
    if ($script:ExplorerDirty) { Restart-Explorer }

    Write-Host ("=== Provisioning v{0} complete ===" -f $Version) -ForegroundColor White

    if ($RebootWhenDone) {
        Write-Host 'Rebooting to finalize servicing (OpenSSH FoD) ...' -ForegroundColor White
        Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
        Start-Sleep -Seconds 3
        Restart-Computer -Force
    }
}
finally {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
}
