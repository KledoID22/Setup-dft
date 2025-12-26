#!/bin/bash

# Быстрая установка всех пакетов одной командой
set -e

# Проверка прав
if [ "$EUID" -ne 0 ]; then 
    echo "Пожалуйста, запустите с sudo!"
    exit 1
fi

echo "=== Установка пакетов ==="
echo "Будут установлены:"
echo "  Основные: ufw, screen, nano, telnet"
echo "  Дополнительные: dust, bottom"
echo "  Python: python3, python3-pip"
echo "=========================="

read -p "Продолжить установку? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

echo "Обновление системы..."
apt-get update
apt-get upgrade -y

echo "Установка основных пакетов..."
apt-get install -y ufw screen nano telnet curl wget

echo "Настройка UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 22/tcp
ufw --force enable

echo "Установка dust..."
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    DUST_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    DUST_ARCH="aarch64"
else
    echo "Неподдерживаемая архитектура для dust: $ARCH"
    DUST_ARCH=""
fi

if [ -n "$DUST_ARCH" ]; then
    curl -sL "https://github.com/bootandy/dust/releases/latest/download/dust-$DUST_ARCH-unknown-linux-gnu.tar.gz" | tar -xz
    find . -name "dust" -type f -executable -exec cp {} /usr/local/bin/ \; 2>/dev/null || true
    chmod +x /usr/local/bin/dust 2>/dev/null || true
fi

echo "Установка bottom..."
if [ "$ARCH" = "x86_64" ]; then
    BTM_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    BTM_ARCH="aarch64"
else
    echo "Неподдерживаемая архитектура для bottom: $ARCH"
    BTM_ARCH=""
fi

if [ -n "$BTM_ARCH" ]; then
    curl -sL "https://github.com/ClementTsang/bottom/releases/latest/download/bottom_${BTM_ARCH}-unknown-linux-gnu.tar.gz" | tar -xz
    find . -name "btm" -type f -executable -exec cp {} /usr/local/bin/ \; 2>/dev/null || true
    find . -name "bottom" -type f -executable -exec cp {} /usr/local/bin/btm \; 2>/dev/null || true
    chmod +x /usr/local/bin/btm 2>/dev/null || true
fi

echo "Установка Python..."
apt-get install -y python3 python3-pip python3-venv
pip3 install --upgrade pip

echo "=== Установка завершена! ==="
echo ""
echo "Доступные команды:"
echo "  screen    - менеджер терминальных сессий"
echo "  ufw       - фаервол"
echo "  nano      - текстовый редактор"
echo "  dust      - анализ дискового пространства"
echo "  btm       - монитор процессов (bottom)"
echo "  python3   - Python интерпретатор"
echo "  pip3      - менеджер пакетов Python"
