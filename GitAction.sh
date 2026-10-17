
#!/usr/bin/env bash
set -Eeuo pipefail

# GitActionServer - Workflow Generator
# Jalankan dari root repository GitHub.

if ! command -v git >/dev/null 2>&1; then
  echo "Error: Git belum terpasang."
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Jalankan script dari dalam repository Git."
  exit 1
}

cd "$ROOT"
mkdir -p .github/workflows

TARGET=".github/workflows/gitactionserver.yml"

if [[ -e "$TARGET" ]]; then
  read -r -p "$TARGET sudah ada. Timpa? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

cat > "$TARGET" <<'YAML'
name: GitActionServer

on:
  workflow_dispatch:
    inputs:
      runner_os:
        description: "Runner OS"
        type: choice
        options:
          - ubuntu-latest
          - windows-latest
          - macos-latest
        default: ubuntu-latest
        required: true

      environment:
        description: "Mode lingkungan"
        type: choice
        options:
          - runner-cli
          - runner-desktop
          - docker-cli
          - docker-desktop
        default: runner-cli
        required: true

      docker_image:
        description: "Docker image untuk mode Docker"
        type: choice
        options:
          - ubuntu:24.04
          - debian:bookworm
          - alpine:3.22
        default: ubuntu:24.04
        required: true

      apps:
        description: "Kategori aplikasi, pisahkan dengan koma: development,ai,database,network,web,system,multimedia"
        type: string
        default: "development,system"
        required: true

      backup_interval:
        description: "Interval backup dalam jam"
        type: choice
        options:
          - "1"
          - "2"
          - "3"
          - "4"
          - "5"
        default: "1"
        required: true

  schedule:
    # Pemeriksaan setiap jam. Interval pilihan diterapkan di dalam job.
    - cron: "17 * * * *"

permissions:
  contents: write

concurrency:
  group: gitactionserver-backup
  cancel-in-progress: false

jobs:
  runner:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      (inputs.environment == 'runner-cli' ||
       inputs.environment == 'runner-desktop')
    runs-on: ${{ inputs.runner_os }}
    timeout-minutes: 350

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.ref_name }}
          persist-credentials: true

      - name: Restore backup folder
        shell: bash
        run: |
          mkdir -p "$HOME/backupPush"
          if [ -d "$GITHUB_WORKSPACE/backupPush" ]; then
            cp -a "$GITHUB_WORKSPACE/backupPush/." "$HOME/backupPush/"
          fi

      - name: Install selected applications on Linux
        if: runner.os == 'Linux'
        shell: bash
        env:
          APPS: ${{ inputs.apps }}
          MODE: ${{ inputs.environment }}
        run: |
          set -e
          sudo apt-get update
          IFS=',' read -ra ITEMS <<< "$APPS"

          for item in "${ITEMS[@]}"; do
            item="$(echo "$item" | xargs)"
            case "$item" in
              development)
                sudo apt-get install -y git curl wget build-essential \
                  python3 python3-pip python3-venv nodejs npm
                ;;
              ai)
                sudo apt-get install -y python3 python3-pip
                ;;
              database)
                sudo apt-get install -y sqlite3
                ;;
              network)
                sudo apt-get install -y curl wget dnsutils net-tools
                ;;
              web)
                sudo apt-get install -y nginx
                ;;
              system)
                sudo apt-get install -y htop tmux zip unzip jq
                ;;
              multimedia)
                sudo apt-get install -y ffmpeg
                ;;
              *)
                echo "Kategori dilewati: $item"
                ;;
            esac
          done

          if [ "$MODE" = "runner-desktop" ]; then
            sudo apt-get install -y xfce4 xfce4-terminal \
              dbus-x11 x11vnc novnc
            echo "Desktop terpasang. Akses jarak jauh memerlukan konfigurasi"
            echo "tunnel dan autentikasi tersendiri."
          fi

      - name: Install selected applications on macOS
        if: runner.os == 'macOS'
        shell: bash
        env:
          APPS: ${{ inputs.apps }}
        run: |
          set -e
          IFS=',' read -ra ITEMS <<< "$APPS"
          for item in "${ITEMS[@]}"; do
            case "$(echo "$item" | xargs)" in
              development)
                brew install git node python
                ;;
              ai)
                brew install python
                ;;
              database)
                brew install sqlite
                ;;
              network)
                brew install curl wget
                ;;
              web)
                brew install nginx
                ;;
              system)
                brew install htop tmux jq
                ;;
              multimedia)
                brew install ffmpeg
                ;;
            esac
          done

      - name: Install selected applications on Windows
        if: runner.os == 'Windows'
        shell: pwsh
        env:
          APPS: ${{ inputs.apps }}
        run: |
          $items = $env:APPS -split ','
          foreach ($item in $items) {
            switch ($item.Trim()) {
              "development" {
                choco install git nodejs python -y --no-progress
              }
              "ai" {
                choco install python -y --no-progress
              }
              "database" {
                choco install sqlite -y --no-progress
              }
              "network" {
                choco install curl wget -y --no-progress
              }
              "web" {
                choco install nginx -y --no-progress
              }
              "system" {
                choco install 7zip jq -y --no-progress
              }
              "multimedia" {
                choco install ffmpeg -y --no-progress
              }
            }
          }

      - name: Install desktop packages on Linux
        if: >-
          runner.os == 'Linux' &&
          inputs.environment == 'runner-desktop'
        shell: bash
        run: |
          echo "Desktop packages are installed."
          echo "This does not create a public remote desktop session."
          echo "Configure an authenticated tunnel separately if needed."

      - name: Sync backupPush and commit
        if: always() && runner.os != ''
        shell: bash
        env:
          INTERVAL: ${{ inputs.backup_interval || '1' }}
          EVENT_NAME: ${{ github.event_name }}
        run: |
          set -euo pipefail

          # Scheduled jobs run hourly. Apply the selected interval in UTC.
          HOUR="$(date -u +%H)"
          if [ "$EVENT_NAME" = "schedule" ] &&
             [ $((10#$HOUR % INTERVAL)) -ne 0 ]; then
            echo "Belum waktunya backup untuk interval ${INTERVAL} jam."
            exit 0
          fi

          SRC="$HOME/backupPush"
          DEST="$GITHUB_WORKSPACE/backupPush"
          mkdir -p "$SRC" "$DEST"

          # Exclude every node_modules directory, at any depth.
          rsync -a --delete \
            --exclude='node_modules/' \
            "$SRC/" "$DEST/"

          git config user.name "github-actions[bot]"
          git config user.email \
            "41898282+github-actions[bot]@users.noreply.github.com"

          git add -A -- backupPush/

          if git diff --cached --quiet; then
            echo "Tidak ada perubahan untuk di-commit."
            exit 0
          fi

          git commit -m "Auto backup backupPush [skip ci]"
          git push origin "HEAD:${GITHUB_REF_NAME}"

  docker:
    if: >-
      github.event_name == 'workflow_dispatch' &&
      (inputs.environment == 'docker-cli' ||
       inputs.environment == 'docker-desktop')
    runs-on: ubuntu-latest
    timeout-minutes: 350

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.ref_name }}
          persist-credentials: true

      - name: Prepare backup folder
        shell: bash
        run: |
          mkdir -p "$HOME/backupPush"
          if [ -d "$GITHUB_WORKSPACE/backupPush" ]; then
            cp -a "$GITHUB_WORKSPACE/backupPush/." "$HOME/backupPush/"
          fi

      - name: Run selected Docker image
        env:
          IMAGE: ${{ inputs.docker_image }}
          MODE: ${{ inputs.environment }}
          APPS: ${{ inputs.apps }}
        shell: bash
        run: |
          set -euo pipefail

          # Docker container is temporary. Persisted data must live
          # in the mounted backupPush directory.
          mkdir -p "$HOME/backupPush"

          if [ "$IMAGE" = "alpine:3.22" ]; then
            echo "Alpine dipilih. Paket tambahan memakai apk."
            docker run --rm \
              -v "$HOME/backupPush:/backupPush" \
              "$IMAGE" sh -lc \
              'apk add --no-cache bash git curl wget; ls -la /backupPush'
          else
            docker run --rm \
              -v "$HOME/backupPush:/backupPush" \
              "$IMAGE" bash -lc \
              'apt-get update && apt-get install -y git curl wget python3 python3-pip nodejs npm; ls -la /backupPush'
          fi

          if [ "$MODE" = "docker-desktop" ]; then
            echo "Image desktop dipilih sebagai mode konfigurasi."
            echo "Akses desktop belum dipublikasikan. Jangan membuka port"
            echo "VNC/noVNC ke internet tanpa autentikasi dan tunnel aman."
          fi

      - name: Sync backupPush and commit
        shell: bash
        env:
          INTERVAL: ${{ inputs.backup_interval || '1' }}
          EVENT_NAME: ${{ github.event_name }}
        run: |
          set -euo pipefail
          HOUR="$(date -u +%H)"
          if [ "$EVENT_NAME" = "schedule" ] &&
             [ $((10#$HOUR % INTERVAL)) -ne 0 ]; then
            echo "Belum waktunya backup."
            exit 0
          fi

          SRC="$HOME/backupPush"
          DEST="$GITHUB_WORKSPACE/backupPush"
          mkdir -p "$DEST"

          rsync -a --delete \
            --exclude='node_modules/' \
            "$SRC/" "$DEST/"

          git config user.name "github-actions[bot]"
          git config user.email \
            "41898282+github-actions[bot]@users.noreply.github.com"

          git add -A -- backupPush/
          if git diff --cached --quiet; then
            echo "Tidak ada perubahan untuk di-commit."
            exit 0
          fi

          git commit -m "Auto backup backupPush [skip ci]"
          git push origin "HEAD:${GITHUB_REF_NAME}"
YAML

echo
echo "Workflow berhasil dibuat:"
echo "  $ROOT/$TARGET"
echo
echo "Berikutnya:"
echo "  1. Commit dan push workflow ini ke GitHub."
echo "  2. Buka tab Actions pada repository."
echo "  3. Pilih GitActionServer lalu Run workflow."
echo
echo "Catatan: Desktop memerlukan konfigurasi akses jarak jauh."
echo "Runner GitHub-hosted bersifat sementara."
