# tools\setup-ssh.ps1
#Requires -RunAsAdministrator

function Write-Title($t) { 
    Write-Host "`n╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $t" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Step($t) { Write-Host "`n>>> $t" -ForegroundColor Yellow }
function Write-Ok($t)    { Write-Host "  ✓ $t" -ForegroundColor Green }
function Write-Warn($t)  { Write-Host "  ⚠ $t" -ForegroundColor Yellow }

Write-Title "WINDOWS SSH SERVER KURULUMU"

Write-Step "1/6 - OpenSSH Server kontrolü..."
$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshServer.State -eq "Installed") {
    Write-Ok "OpenSSH Server zaten kurulu"
} else {
    Write-Warn "OpenSSH Server kuruluyor..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Ok "OpenSSH Server kuruldu"
}

Write-Step "2/6 - SSH servisi başlatılıyor..."
Set-Service -Name sshd -StartupType 'Automatic'
Start-Service sshd
Write-Ok "SSH servisi otomatik başlatma modunda"

Write-Step "3/6 - Firewall kuralı..."
$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue

if ($firewallRule) {
    Write-Ok "Firewall kuralı mevcut"
} else {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Ok "Firewall kuralı eklendi (Port 22)"
}

Write-Step "4/6 - PowerShell default shell..."
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null
Write-Ok "PowerShell default shell"

Write-Step "5/6 - SSH config..."
$sshConfig = "C:\ProgramData\ssh\sshd_config"
Add-Content -Path $sshConfig -Value "`nPasswordAuthentication yes"
Restart-Service sshd
Write-Ok "Password authentication aktif"

Write-Step "6/6 - Bağlantı bilgileri..."
$currentUser = $env:USERNAME
$hostname = $env:COMPUTERNAME

Write-Title "SSH KURULUMU TAMAMLANDI"
Write-Host ""
Write-Host "  📡 Host: localhost" -ForegroundColor Yellow
Write-Host "  🔌 Port: 22" -ForegroundColor Yellow
Write-Host "  👤 User: $currentUser" -ForegroundColor Yellow
Write-Host "  🔑 Pass: [Windows şifreniz]" -ForegroundColor Cyan
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✓✓✓ SSH HAZIR - CLAUDE TAM OTOMASYON YAPABİLİR! ✓✓✓║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Test: ssh $currentUser@localhost" -ForegroundColor White
