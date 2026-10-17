
@echo off
setlocal EnableExtensions
title GitActionServer Generator

cd /d "%~dp0"

echo.
echo ==========================================
echo       GitActionServer Generator
echo ==========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git tidak ditemukan.
    echo Git diperlukan untuk mendeteksi repository dan branch.
    echo https://git-scm.com/download/win
    pause
    exit /b 1
)

git rev-parse --show-toplevel >nul 2>&1
if errorlevel 1 (
    echo ERROR: Jalankan BAT dari dalam repository Git.
    pause
    exit /b 1
)

for /f "delims=" %%R in ('git rev-parse --show-toplevel') do set "ROOT=%%R"

set "WORKFLOW_DIR=%ROOT%\.github\workflows"
set "TARGET=%WORKFLOW_DIR%\gitactionserver.yml"

if not exist "%WORKFLOW_DIR%" mkdir "%WORKFLOW_DIR%"

if exist "%TARGET%" (
    echo Workflow sudah ada:
    echo %TARGET%
    set /p "OVERWRITE=Timpa workflow tersebut? [y/N]: "
    if /i not "%OVERWRITE%"=="y" (
        echo Dibatalkan.
        pause
        exit /b 0
    )
)

echo.
echo Pilih runner OS:
echo 1. Ubuntu
echo 2. Windows
echo 3. macOS
set /p "OS_CHOICE=Pilihan [1]: "
if not defined OS_CHOICE set "OS_CHOICE=1"

set "RUNNER=ubuntu-latest"
if "%OS_CHOICE%"=="2" set "RUNNER=windows-latest"
if "%OS_CHOICE%"=="3" set "RUNNER=macos-latest"
if not "%OS_CHOICE%"=="1" if not "%OS_CHOICE%"=="2" if not "%OS_CHOICE%"=="3" (
    echo Pilihan OS tidak valid.
    pause
    exit /b 1
)

echo.
echo Pilih mode:
echo 1. Runner CLI
echo 2. Runner Desktop
echo 3. Docker CLI
echo 4. Docker Desktop
set /p "MODE_CHOICE=Pilihan [1]: "
if not defined MODE_CHOICE set "MODE_CHOICE=1"

set "MODE=runner-cli"
if "%MODE_CHOICE%"=="2" set "MODE=runner-desktop"
if "%MODE_CHOICE%"=="3" set "MODE=docker-cli"
if "%MODE_CHOICE%"=="4" set "MODE=docker-desktop"
if not "%MODE_CHOICE%"=="1" if not "%MODE_CHOICE%"=="2" if not "%MODE_CHOICE%"=="3" if not "%MODE_CHOICE%"=="4" (
    echo Pilihan mode tidak valid.
    pause
    exit /b 1
)

echo.
echo Pilih Docker image:
echo 1. Ubuntu 24.04
echo 2. Debian Bookworm
echo 3. Alpine 3.22
set /p "IMAGE_CHOICE=Pilihan [1]: "
if not defined IMAGE_CHOICE set "IMAGE_CHOICE=1"

set "IMAGE=ubuntu:24.04"
if "%IMAGE_CHOICE%"=="2" set "IMAGE=debian:bookworm"
if "%IMAGE_CHOICE%"=="3" set "IMAGE=alpine:3.22"

echo.
echo Masukkan kategori aplikasi, dipisahkan koma:
echo development,ai,database,network,web,system,multimedia
set /p "APPS=Kategori [development,system]: "
if not defined APPS set "APPS=development,system"

echo.
echo Interval autobackup:
echo 1. Setiap 1 jam
echo 2. Setiap 2 jam
echo 3. Setiap 3 jam
echo 4. Setiap 4 jam
echo 5. Setiap 5 jam
set /p "INTERVAL=Pilihan [1]: "
if not defined INTERVAL set "INTERVAL=1"

if "%INTERVAL%"=="1" goto interval_ok
if "%INTERVAL%"=="2" goto interval_ok
if "%INTERVAL%"=="3" goto interval_ok
if "%INTERVAL%"=="4" goto interval_ok
if "%INTERVAL%"=="5" goto interval_ok
echo Interval tidak valid. Maksimal 5 jam.
pause
exit /b 1

:interval_ok
echo.
echo Membuat workflow...
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
 "$p = $env:TARGET; " ^
 "$runner = $env:RUNNER; " ^
 "$mode = $env:MODE; " ^
 "$image = $env:IMAGE; " ^
 "$apps = $env:APPS; " ^
 "$interval = [int]$env:INTERVAL; " ^
 "$yaml = @'
name: GitActionServer

on:
  workflow_dispatch:
  schedule:
    - cron: '17 * * * *'

permissions:
  contents: write

concurrency:
  group: gitactionserver-backup
  cancel-in-progress: false

jobs:
  setup:
    runs-on: __RUNNER__
    timeout-minutes: 350
    steps:
      - uses: actions/checkout@v4
        with:
          persist-credentials: true

      - name: Create backup folder
        shell: pwsh
        run: |
          $backup = Join-Path $HOME 'backupPush'
          New-Item -ItemType Directory -Force -Path $backup | Out-Null
          $repoBackup = Join-Path $env:GITHUB_WORKSPACE 'backupPush'
          New-Item -ItemType Directory -Force -Path $repoBackup | Out-Null
          Get-ChildItem -Force $repoBackup | ForEach-Object {
            Copy-Item $_.FullName $backup -Recurse -Force
          }

      - name: Install selected applications
        shell: pwsh
        env:
          APPS: __APPS__
          MODE: __MODE__
        run: |
          $items = $env:APPS -split ',' | ForEach-Object { $_.Trim() }
          if ($IsLinux) {
            sudo apt-get update
            foreach ($item in $items) {
              switch ($item) {
                'development' { sudo apt-get install -y git curl wget build-essential python3 python3-pip nodejs npm }
                'ai' { sudo apt-get install -y python3 python3-pip }
                'database' { sudo apt-get install -y sqlite3 }
                'network' { sudo apt-get install -y curl wget dnsutils net-tools }
                'web' { sudo apt-get install -y nginx }
                'system' { sudo apt-get install -y htop tmux zip unzip jq }
                'multimedia' { sudo apt-get install -y ffmpeg }
              }
            }
            if ($env:MODE -eq 'runner-desktop') {
              sudo apt-get install -y xfce4 xfce4-terminal dbus-x11
              Write-Host 'Desktop installed; remote access is not configured.'
            }
          } elseif ($IsMacOS) {
            foreach ($item in $items) {
              switch ($item) {
                'development' { brew install git node python }
                'ai' { brew install python }
                'database' { brew install sqlite }
                'network' { brew install curl wget }
                'web' { brew install nginx }
                'system' { brew install htop tmux jq }
                'multimedia' { brew install ffmpeg }
              }
            }
          } else {
            foreach ($item in $items) {
              switch ($item) {
                'development' { choco install git nodejs python -y --no-progress }
                'ai' { choco install python -y --no-progress }
                'database' { choco install sqlite -y --no-progress }
                'network' { choco install curl wget -y --no-progress }
                'web' { choco install nginx -y --no-progress }
                'system' { choco install 7zip jq -y --no-progress }
                'multimedia' { choco install ffmpeg -y --no-progress }
              }
            }
          }

      - name: Docker environment
        if: __MODE__ == 'docker-cli' || __MODE__ == 'docker-desktop'
        shell: bash
        run: |
          docker run --rm -v "$GITHUB_WORKSPACE/backupPush:/backupPush" __IMAGE__ sh -lc 'ls -la /backupPush'
          echo 'Docker containers are temporary. Data must be stored in backupPush.'

      - name: Commit backup
        shell: pwsh
        env:
          INTERVAL: __INTERVAL__
        run: |
          $backup = Join-Path $env:GITHUB_WORKSPACE 'backupPush'
          New-Item -ItemType Directory -Force -Path $backup | Out-Null
          $hour = [DateTime]::UtcNow.Hour
          if (($hour % [int]$env:INTERVAL) -ne 0 -and '${{ github.event_name }}' -eq 'schedule') {
            Write-Host 'Not scheduled for this interval.'
            exit 0
          }

          # Exclude node_modules directories at every level.
          Get-ChildItem -Path $backup -Directory -Filter node_modules -Recurse -Force |
            Sort-Object FullName -Descending |
            ForEach-Object { Remove-Item $_.FullName -Recurse -Force }

          git config user.name 'github-actions[bot]'
          git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
          git add -A -- backupPush/
          git diff --cached --quiet
          if ($LASTEXITCODE -eq 0) {
            Write-Host 'No changes to commit.'
            exit 0
          }
          git commit -m 'Auto backup backupPush [skip ci]'
          git push origin "HEAD:${{ github.ref_name }}"
'@; " ^
 "$yaml = $yaml.Replace('__RUNNER__', $runner).Replace('__MODE__', $mode).Replace('__IMAGE__', $image).Replace('__APPS__', $apps).Replace('__INTERVAL__', [string]$interval); " ^
 "[System.IO.File]::WriteAllText($p, $yaml, [System.Text.UTF8Encoding]::new($false));"

if errorlevel 1 (
    echo Gagal membuat workflow.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Workflow berhasil dibuat:
echo %TARGET%
echo ==========================================
echo.
echo Berikutnya:
echo 1. Commit dan push file workflow ke GitHub.
echo 2. Buka tab Actions pada repository.
echo 3. Jalankan workflow GitActionServer.
echo.
echo Catatan:
echo - GitHub-hosted runner bersifat sementara.
echo - Desktop belum memiliki remote access otomatis.
echo - Workflow memerlukan izin contents: write.
echo.
pause
