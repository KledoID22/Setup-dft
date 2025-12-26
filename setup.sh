#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ваши пакеты
PACKAGES=("ufw" "screen" "nano" "telnet")
PYTHON_PACKAGES=("python3" "python3-pip" "python3-venv" "python3-dev")

# Функция для вывода заголовка
print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              Установка пакетов на Linux                  ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Функция проверки системы
check_system_status() {
    echo -e "${YELLOW}📊 Проверка состояния системы...${NC}"
    echo ""
    
    echo "💻 Информация о системе:"
    echo "  Hostname: $(hostname)"
    
    # Определение дистрибутива
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "  OS: $NAME $VERSION"
    else
        echo "  OS: $(uname -s)"
    fi
    
    echo "  Kernel: $(uname -r)"
    echo "  Архитектура: $(uname -m)"
    echo "  Uptime: $(uptime -p | sed 's/up //')"
    
    echo ""
    echo "📈 Использование ресурсов:"
    
    # CPU
    CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "N/A")
    echo "  CPU: $CPU_CORES ядер"
    
    # RAM
    if command -v free &> /dev/null; then
        TOTAL_RAM=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "N/A")
        USED_RAM=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}' || echo "N/A")
        echo "  RAM: $USED_RAM/$TOTAL_RAM использовано"
    fi
    
    # Диск
    if command -v df &> /dev/null; then
        DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "N/A")
        DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}' || echo "N/A")
        echo "  Диск (/): $DISK_USED/$DISK_TOTAL использовано"
    fi
    
    echo ""
    echo "🌐 Сетевая информация:"
    
    # IP адреса
    if command -v hostname &> /dev/null; then
        IP_ADDRESSES=$(hostname -I 2>/dev/null || echo "N/A")
        echo "  IP: $IP_ADDRESSES"
    fi
    
    echo ""
    echo "📦 Проверка установленных пакетов:"
    
    # Проверяем основные пакеты
    for pkg in "${PACKAGES[@]}"; do
        if command -v "$pkg" &> /dev/null || dpkg -l | grep -q "^ii.*$pkg " 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $pkg установлен"
        else
            echo -e "  ${RED}✗${NC} $pkg не установлен"
        fi
    done
    
    # Проверяем dust и bottom
    if command -v dust &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} dust установлен"
    else
        echo -e "  ${RED}✗${NC} dust не установлен"
    fi
    
    if command -v btm &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} bottom установлен"
    else
        echo -e "  ${RED}✗${NC} bottom не установлен"
    fi
    
    # Проверка Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>/dev/null || echo "Неизвестно")
        echo -e "  ${GREEN}✓${NC} Python: $PYTHON_VERSION"
    else
        echo -e "  ${RED}✗${NC} Python3 не установлен"
    fi
    
    echo ""
}

# Полное обновление системы
full_system_update() {
    echo -e "${YELLOW}🔄 Начинаем полное обновление системы...${NC}"
    echo ""
    
    # Обновление списка пакетов
    echo "📦 Обновление списка пакетов..."
    apt-get update
    
    # Обновление установленных пакетов
    echo "🔄 Обновление установленных пакетов..."
    apt-get upgrade -y
    
    # Обновление дистрибутива
    echo "🚀 Обновление дистрибутива..."
    apt-get dist-upgrade -y
    
    # Очистка ненужных пакетов
    echo "🧹 Очистка системы..."
    apt-get autoremove -y
    apt-get autoclean -y
    
    echo -e "${GREEN}✅ Полное обновление завершено!${NC}"
    echo ""
}

# Установка основных пакетов
install_main_packages() {
    echo -e "${YELLOW}📦 Установка основных пакетов...${NC}"
    echo ""
    
    apt-get update
    
    for pkg in "${PACKAGES[@]}"; do
        echo "  Установка $pkg..."
        if apt-get install -y "$pkg" > /dev/null 2>&1; then
            echo -e "    ${GREEN}✓${NC} Успешно установлен"
        else
            echo -e "    ${RED}✗${NC} Ошибка установки"
        fi
    done
    
    echo ""
}

# Установка dust (аналог du)
install_dust() {
    echo -e "${YELLOW}🧹 Установка dust...${NC}"
    echo ""
    
    if command -v dust &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} dust уже установлен"
        return 0
    fi
    
    # Проверяем архитектуру
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        DUST_ARCH="x86_64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        DUST_ARCH="aarch64"
    else
        echo -e "  ${RED}✗${NC} Неподдерживаемая архитектура: $ARCH"
        echo "  Установите dust вручную: https://github.com/bootandy/dust"
        return 1
    fi
    
    # Скачиваем dust
    echo "  Скачивание dust для $DUST_ARCH..."
    
    # Создаем временную директорию
    TEMP_DIR=$(mktemp -d)
    
    # Пытаемся скачать через curl или wget
    if command -v curl &> /dev/null; then
        if curl -sL "https://github.com/bootandy/dust/releases/latest/download/dust-$DUST_ARCH-unknown-linux-gnu.tar.gz" -o "$TEMP_DIR/dust.tar.gz"; then
            echo "  Распаковка..."
            tar -xzf "$TEMP_DIR/dust.tar.gz" -C "$TEMP_DIR" --strip-components=1
            cp "$TEMP_DIR/dust" /usr/local/bin/
            chmod +x /usr/local/bin/dust
            echo -e "  ${GREEN}✓${NC} dust успешно установлен"
        else
            echo -e "  ${RED}✗${NC} Ошибка загрузки dust"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if wget -q "https://github.com/bootandy/dust/releases/latest/download/dust-$DUST_ARCH-unknown-linux-gnu.tar.gz" -O "$TEMP_DIR/dust.tar.gz"; then
            echo "  Распаковка..."
            tar -xzf "$TEMP_DIR/dust.tar.gz" -C "$TEMP_DIR" --strip-components=1
            cp "$TEMP_DIR/dust" /usr/local/bin/
            chmod +x /usr/local/bin/dust
            echo -e "  ${GREEN}✓${NC} dust успешно установлен"
        else
            echo -e "  ${RED}✗${NC} Ошибка загрузки dust"
            return 1
        fi
    else
        echo -e "  ${RED}✗${NC} Установите curl или wget для загрузки dust"
        return 1
    fi
    
    # Очистка
    rm -rf "$TEMP_DIR"
    echo ""
}

# Установка bottom (btm)
install_bottom() {
    echo -e "${YELLOW}📊 Установка bottom...${NC}"
    echo ""
    
    if command -v btm &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} bottom уже установлен"
        return 0
    fi
    
    # Проверяем архитектуру
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        BTM_ARCH="x86_64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        BTM_ARCH="aarch64"
    else
        echo -e "  ${RED}✗${NC} Неподдерживаемая архитектура: $ARCH"
        echo "  Альтернатива: установка htop"
        apt-get install -y htop
        return 1
    fi
    
    # Скачиваем bottom
    echo "  Скачивание bottom для $BTM_ARCH..."
    
    # Создаем временную директорию
    TEMP_DIR=$(mktemp -d)
    
    # Пытаемся скачать через curl или wget
    if command -v curl &> /dev/null; then
        if curl -sL "https://github.com/ClementTsang/bottom/releases/latest/download/bottom_${BTM_ARCH}-unknown-linux-gnu.tar.gz" -o "$TEMP_DIR/bottom.tar.gz"; then
            echo "  Распаковка..."
            tar -xzf "$TEMP_DIR/bottom.tar.gz" -C "$TEMP_DIR"
            
            # Ищем бинарник
            if [ -f "$TEMP_DIR/btm" ]; then
                BTM_BIN="$TEMP_DIR/btm"
            elif [ -f "$TEMP_DIR/bottom" ]; then
                BTM_BIN="$TEMP_DIR/bottom"
            else
                # Ищем в поддиректориях
                BTM_BIN=$(find "$TEMP_DIR" -name "btm" -type f -executable | head -1)
                if [ -z "$BTM_BIN" ]; then
                    BTM_BIN=$(find "$TEMP_DIR" -name "bottom" -type f -executable | head -1)
                fi
            fi
            
            if [ -n "$BTM_BIN" ]; then
                cp "$BTM_BIN" /usr/local/bin/btm
                chmod +x /usr/local/bin/btm
                echo -e "  ${GREEN}✓${NC} bottom успешно установлен"
            else
                echo -e "  ${RED}✗${NC} Не найден бинарник bottom"
                echo "  Альтернатива: установка htop"
                apt-get install -y htop
            fi
        else
            echo -e "  ${RED}✗${NC} Ошибка загрузки bottom"
            echo "  Альтернатива: установка htop"
            apt-get install -y htop
        fi
    elif command -v wget &> /dev/null; then
        if wget -q "https://github.com/ClementTsang/bottom/releases/latest/download/bottom_${BTM_ARCH}-unknown-linux-gnu.tar.gz" -O "$TEMP_DIR/bottom.tar.gz"; then
            echo "  Распаковка..."
            tar -xzf "$TEMP_DIR/bottom.tar.gz" -C "$TEMP_DIR"
            
            # Ищем бинарник
            if [ -f "$TEMP_DIR/btm" ]; then
                BTM_BIN="$TEMP_DIR/btm"
            elif [ -f "$TEMP_DIR/bottom" ]; then
                BTM_BIN="$TEMP_DIR/bottom"
            else
                # Ищем в поддиректориях
                BTM_BIN=$(find "$TEMP_DIR" -name "btm" -type f -executable | head -1)
                if [ -z "$BTM_BIN" ]; then
                    BTM_BIN=$(find "$TEMP_DIR" -name "bottom" -type f -executable | head -1)
                fi
            fi
            
            if [ -n "$BTM_BIN" ]; then
                cp "$BTM_BIN" /usr/local/bin/btm
                chmod +x /usr/local/bin/btm
                echo -e "  ${GREEN}✓${NC} bottom успешно установлен"
            else
                echo -e "  ${RED}✗${NC} Не найден бинарник bottom"
                echo "  Альтернатива: установка htop"
                apt-get install -y htop
            fi
        else
            echo -e "  ${RED}✗${NC} Ошибка загрузки bottom"
            echo "  Альтернатива: установка htop"
            apt-get install -y htop
        fi
    else
        echo -e "  ${RED}✗${NC} Установите curl или wget для загрузки bottom"
        echo "  Альтернатива: установка htop"
        apt-get install -y htop
    fi
    
    # Очистка
    rm -rf "$TEMP_DIR"
    echo ""
}

# Установка Python
install_python() {
    echo -e "${YELLOW}🐍 Установка Python...${NC}"
    echo ""
    
    apt-get update
    
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        echo "  Установка $pkg..."
        if apt-get install -y "$pkg" > /dev/null 2>&1; then
            echo -e "    ${GREEN}✓${NC} Успешно установлен"
        else
            echo -e "    ${RED}✗${NC} Ошибка установки"
        fi
    done
    
    # Проверка установки
    echo ""
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        echo -e "${GREEN}✅ $PYTHON_VERSION успешно установлен${NC}"
        
        # Проверка pip
        if command -v pip3 &> /dev/null; then
            echo -e "${GREEN}✅ pip установлен${NC}"
            
            # Обновление pip
            echo "Обновление pip..."
            pip3 install --upgrade pip --quiet
        fi
    else
        echo -e "${RED}❌ Ошибка установки Python${NC}"
    fi
    
    echo ""
}

# Настройка после установки
post_install_setup() {
    echo -e "${YELLOW}⚙️  Настройка после установки...${NC}"
    echo ""
    
    # Настройка UFW
    if command -v ufw &> /dev/null; then
        echo "Настройка фаервола (UFW)..."
        ufw default deny incoming > /dev/null 2>&1 || true
        ufw default allow outgoing > /dev/null 2>&1 || true
        ufw allow ssh > /dev/null 2>&1 || true
        ufw allow 22/tcp > /dev/null 2>&1 || true
        
        # Включаем UFW
        ufw --force enable > /dev/null 2>&1 || true
        echo -e "  ${GREEN}✓${NC} UFW настроен"
    fi
    
    # Настройка bash
    echo "Добавление алиасов в bash..."
    
    # Алиас для dust если он установлен
    if command -v dust &> /dev/null; then
        DUST_ALIAS="alias du='dust'"
    else
        DUST_ALIAS="# dust не установлен"
    fi
    
    # Алиас для bottom если он установлен
    if command -v btm &> /dev/null; then
        BTM_ALIAS="alias top='btm'"
    else
        BTM_ALIAS="# bottom не установлен"
    fi
    
    cat >> ~/.bashrc << EOF

# Пользовательские алиасы
alias ll='ls -la'
alias l='ls -CF'
alias update='sudo apt update && sudo apt upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean'
$DUST_ALIAS
$BTM_ALIAS
alias nano='nano -l'

# Цветной prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
    
    echo -e "  ${GREEN}✓${NC} Настройки bash добавлены"
    echo ""
    echo "Для применения настроек выполните: source ~/.bashrc"
    echo ""
}

# Функция для показа меню
show_menu() {
    clear
    print_header
    
    echo -e "${YELLOW}Доступные пакеты для установки:${NC}"
    echo ""
    echo -e "  ${BLUE}Основные:${NC}"
    for pkg in "${PACKAGES[@]}"; do
        echo "    - $pkg"
    done
    
    echo ""
    echo -e "  ${BLUE}Дополнительные:${NC}"
    echo "    - dust (аналог du, визуализация использования диска)"
    echo "    - bottom (аналог top/htop, монитор процессов)"
    
    echo ""
    echo -e "  ${BLUE}Python:${NC}"
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        echo "    - $pkg"
    done
    
    echo ""
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo "  1. 📊 Проверить состояние системы"
    echo "  2. 🔄 Полное обновление системы"
    echo "  3. 📦 Установить ВСЕ пакеты"
    echo "  4. 🛠️  Установить только основные пакеты (ufw, screen, nano, telnet)"
    echo "  5. 🧹 Установить dust (аналог du)"
    echo "  6. 📊 Установить bottom (аналог top)"
    echo "  7. 🐍 Установить Python"
    echo "  8. ⚙️  Настройка после установки"
    echo "  9. 🚪 Выйти"
    echo ""
}

# Основной скрипт
set -e

# Проверка прав
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Этот скрипт требует прав root. Запустите с sudo!${NC}"
    exit 1
fi

# Проверка дистрибутива
if ! command -v apt-get &> /dev/null; then
    echo -e "${RED}Этот скрипт работает только с Debian/Ubuntu${NC}"
    exit 1
fi

# Основной цикл
while true; do
    show_menu
    read -p "Ваш выбор [1-9]: " choice
    
    case $choice in
        1)
            check_system_status
            ;;
        2)
            echo -e "${YELLOW}Выбрано: Полное обновление системы${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                full_system_update
            else
                echo "Обновление отменено."
            fi
            ;;
        3)
            echo -e "${YELLOW}Выбрано: Установка ВСЕХ пакетов${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo "Начинаем установку всех пакетов..."
                apt-get update
                install_main_packages
                install_dust
                install_bottom
                install_python
                post_install_setup
                echo -e "${GREEN}✅ Все пакеты установлены и настроены!${NC}"
            else
                echo "Установка отменена."
            fi
            ;;
        4)
            echo -e "${YELLOW}Выбрано: Установка основных пакетов${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                install_main_packages
                echo -e "${GREEN}✅ Основные пакеты установлены!${NC}"
            else
                echo "Установка отменена."
            fi
            ;;
        5)
            echo -e "${YELLOW}Выбрано: Установка dust${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                install_dust
            else
                echo "Установка отменена."
            fi
            ;;
        6)
            echo -e "${YELLOW}Выбрано: Установка bottom${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                install_bottom
            else
                echo "Установка отменена."
            fi
            ;;
        7)
            echo -e "${YELLOW}Выбрано: Установка Python${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                install_python
            else
                echo "Установка отменена."
            fi
            ;;
        8)
            echo -e "${YELLOW}Выбрано: Настройка после установки${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                post_install_setup
            else
                echo "Настройка отменена."
            fi
            ;;
        9)
            echo -e "${GREEN}Выход. Хорошего дня!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор!${NC}"
            ;;
    esac
    
    echo ""
    read -p "Нажмите Enter для продолжения..."
done
