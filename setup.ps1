if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Write-Host "Запусти от имени администратора!" -ForegroundColor Red; Read-Host "Нажми Enter"; exit }
$AUTH_KEY = Read-Host "Введите ключ Tailscale (вам его даст друг)"
if (-not $AUTH_KEY) { Write-Host "Ключ не введён" -ForegroundColor Red; Read-Host; exit }
Write-Host "Скачивание Tailscale..." -ForegroundColor Cyan
$url = "https://pkgs.tailscale.com/stable/windows/tailscale-setup-latest.exe"
$installer = "$env:TEMP\tailscale-setup.exe"
try { Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing -ErrorAction Stop } catch { Write-Host "Ошибка скачивания: $_" -ForegroundColor Red; Read-Host; exit }
Write-Host "Установка..." -ForegroundColor Cyan
Start-Process -FilePath $installer -ArgumentList "/S" -Wait
$tsPath = "$env:ProgramFiles\Tailscale\tailscale.exe"
if (-not (Test-Path $tsPath)) { Write-Host "Ошибка установки" -ForegroundColor Red; Read-Host; exit }
Write-Host "Подключение..." -ForegroundColor Cyan
& $tsPath up --authkey $AUTH_KEY --accept-routes --unattended --ssh
if ($LASTEXITCODE -ne 0) { Write-Host "Ошибка подключения (проверь ключ)" -ForegroundColor Red; Read-Host; exit }
if (-not (Get-WindowsCapability -Online | Where-Object { $_.Name -like 'OpenSSH.Server*' -and $_.State -eq 'Installed' })) { Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 }
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType 'Automatic'
if (-not (Get-NetFirewallRule -DisplayName 'OpenSSH Server' -ErrorAction SilentlyContinue)) { New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 }
$tsIP = & $tsPath ip -4 2>$null | Select-Object -First 1
Clear-Host
Write-Host "=============================================" -ForegroundColor Green
Write-Host "ГОТОВО! IP: $tsIP, Пользователь: $env:USERNAME" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Green
Read-Host "Нажми Enter для выхода"
