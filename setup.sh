#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$HOME/deepseek_setup.log"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }
die() { log "ОШИБКА: $*"; exit 1; }

exec > >(tee -a "$LOG") 2>&1

log "=== DeepSeek setup ==="

ping -c 2 8.8.8.8 >/dev/null 2>&1 || die "Нет интернета"

sudo -v || die "sudo failed"
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
trap "kill $SUDO_KEEPALIVE 2>/dev/null || true" EXIT

if grep -qE "ftp\.halifax|kali\.download" /etc/apt/sources.list 2>/dev/null; then
    log "Меняю зеркало на http.kali.org"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%s)
    sudo sed -i 's|ftp\.halifax\.rwth-aachen\.de|http.kali.org|g; s|kali\.download|http.kali.org|g' /etc/apt/sources.list
    sudo sed -i 's|http://http\.kali\.org|http.kali.org|g' /etc/apt/sources.list
fi

sudo apt update || true
sudo dpkg --configure -a || true
sudo apt --fix-broken install -y || true

command -v chromium >/dev/null 2>&1 || sudo apt install -y chromium chromium-driver
chromium --version

sudo apt install -y libnss3 libgbm1 libxss1 libxtst6 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libpango-1.0-0 libxfixes3 libxext6 \
    fonts-liberation xdg-utils || true

sudo apt install -y libatk-bridge2.0-0t64 libgtk-3-0t64 libcups2t64 libatspi2.0-0t64 2>/dev/null || \
    sudo apt install -y libatk-bridge2.0-0 libgtk-3-0 libcups2 libatspi2.0-0 || true

mkdir -p "$HOME/antidetect/venv" "$HOME/antidetect/profiles" "$HOME/antidetect/logs"

[ -d "$HOME/antidetect/venv/bin" ] || python3 -m venv "$HOME/antidetect/venv"
source "$HOME/antidetect/venv/bin/activate"
pip install --upgrade pip setuptools >/dev/null 2>&1 || true
python3 -c "import nodriver" 2>/dev/null || pip install nodriver

cp "$REPO_DIR/deepseek_launcher.py" "$HOME/antidetect/"
cp "$REPO_DIR/test_chrome.py" "$HOME/antidetect/"
chmod +x "$HOME/antidetect/"*.py

mkdir -p "$HOME/Desktop" "$HOME/.local/share/applications"
cp "$REPO_DIR/deepseek.desktop" "$HOME/Desktop/" 2>/dev/null || true
cp "$REPO_DIR/deepseek.desktop" "$HOME/.local/share/applications/" 2>/dev/null || true
chmod +x "$HOME/Desktop/deepseek.desktop" 2>/dev/null || true
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

touch "$HOME/.zshrc"
grep -q "alias act=" "$HOME/.zshrc" 2>/dev/null || \
    echo 'alias act="source $HOME/antidetect/venv/bin/activate"' >> "$HOME/.zshrc"
grep -q "alias ds=" "$HOME/.zshrc" 2>/dev/null || \
    echo 'alias ds="source $HOME/antidetect/venv/bin/activate && python3 $HOME/antidetect/deepseek_launcher.py"' >> "$HOME/.zshrc"

command -v setxkbmap >/dev/null 2>&1 && \
    setxkbmap -layout "us,ru" -option "grp:alt_shift_toggle" 2>/dev/null || true

echo
echo "===================================================="
echo " УСТАНОВКА ЗАВЕРШЕНА"
echo "===================================================="
chromium --version
python3 -c "import nodriver; print('nodriver OK')"
echo
echo "Запуск: открой НОВЫЙ терминал и напиши: ds"
echo "Лог: $LOG"
echo "===================================================="
