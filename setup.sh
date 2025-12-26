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

# Пакеты для установки из сторонних репозиториев
EXTRA_PACKAGES=("dust" "bottom")

# Python пакеты
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
    CPU_CORES=$(grep -c '^processor' /proc/cpuinfo)
    CPU_MODEL=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    echo "  CPU: $CPU_CORES ядер, $CPU_MODEL"
    
    # RAM
    TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
    USED_RAM=$(free -h | awk '/^Mem:/ {print $3}')
    RAM_PERCENT=$(free | awk '/^Mem:/ {printf("%.1f", $3/$2 * 100)}')
    echo "  RAM: $USED_RAM/$TOTAL_RAM использовано ($RAM_PERCENT%)"
    
    # Диск
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_PERCENT=$(df / | awk 'NR==2 {print $5}')
    echo "  Диск (/): $DISK_USED/$DISK_TOTAL использовано ($DISK_PERCENT)"
    
    echo ""
    echo "🌐 Сетевая информация:"
    
    # IP адреса
    IP_ADDRESSES=$(hostname -I 2>/dev/null || ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -5)
    if [ -n "$IP_ADDRESSES" ]; then
        echo "  IP адреса:"
        for ip in $IP_ADDRESSES; do
            echo "    - $ip"
        done
    else
        echo "  IP адреса: Не найдены"
    fi
    
    # Внешний IP (если есть интернет)
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        EXTERNAL_IP=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "Недоступно")
        echo "  Внешний IP: $EXTERNAL_IP"
    fi
    
    echo ""
    echo "📦 Установленные пакеты:"
    for pkg in "${PACKAGES[@]}" "${EXTRA_PACKAGES[@]}" "${PYTHON_PACKAGES[@]:0:2}"; do
        if dpkg -l | grep -q "^ii.*$pkg "; then
            echo -e "  ${GREEN}✓${NC} $pkg установлен"
        else
            echo -e "  ${RED}✗${NC} $pkg не установлен"
        fi
    done
    
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
    apt-get clean -y
    
    echo -e "${GREEN}✅ Полное обновление завершено!${NC}"
    echo ""
}

# Установка основных пакетов
install_main_packages() {
    echo -e "${YELLOW}📦 Установка основных пакетов...${NC}"
    echo ""
    
    for pkg in "${PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii.*$pkg "; then
            echo -e "  ${GREEN}✓${NC} $pkg уже установлен"
        else
            echo "  Установка $pkg..."
            if apt-get install -y "$pkg" > /dev/null 2>&1; then
                echo -e "    ${GREEN}✓${NC} Успешно установлен"
            else
                echo -e "    ${RED}✗${NC} Ошибка установки"
            fi
        fi
    done
    
    echo ""
}

# Установка дополнительных пакетов (dust, bottom)
install_extra_packages() {
    echo -e "${YELLOW}🌟 Установка дополнительных пакетов...${NC}"
    echo ""
    
    # Установка dust
    if ! command -v dust &> /dev/null; then
        echo "Установка dust..."
        
        # Скачивание и установка dust (альтернатива du)
        DUST_URL="https://github.com/bootandy/dust/releases/latest/download/dust-musl-x86_64.tar.gz"
        
        if curl -s --head --fail "$DUST_URL" >/dev/null 2>&1; then
            wget -q "$DUST_URL" -O /tmp/dust.tar.gz
            tar -xzf /tmp/dust.tar.gz -C /tmp/
            cp /tmp/dust-*/dust /usr/local/bin/
            chmod +x /usr/local/bin/dust
            rm -rf /tmp/dust*
            echo -e "  ${GREEN}✓${NC} dust установлен"
        else
            echo -e "  ${RED}✗${NC} Не удалось скачать dust"
            echo "  Альтернатива: установка ncdu (аналог dust)"
            apt-get install -y ncdu
        fi
    else
        echo -e "  ${GREEN}✓${NC} dust уже установлен"
    fi
    
    # Установка bottom (btm)
    if ! command -v btm &> /dev/null; then
        echo "Установка bottom (btm)..."
        
        # Установка через cargo (если есть) или скачивание бинарника
        if command -v cargo &> /dev/null; then
            cargo install bottom
            echo -e "  ${GREEN}✓${NC} bottom установлен через cargo"
        else
            # Скачивание .deb пакета
            BTM_DEB_URL="https://github.com/ClementTsang/bottom/releases/latest/download/bottom_amd64.deb"
            
            if wget -q "$BTM_DEB_URL" -O /tmp/bottom.deb; then
                dpkg -i /tmp/bottom.deb || apt-get install -f -y
                rm /tmp/bottom.deb
                echo -e "  ${GREEN}✓${NC} bottom установлен"
            else
                echo -e "  ${RED}✗${NC} Не удалось установить bottom"
                echo "  Альтернатива: установка htop"
                apt-get install -y htop
            fi
        fi
    else
        echo -e "  ${GREEN}✓${NC} bottom уже установлен"
    fi
    
    echo ""
}

# Установка Python
install_python() {
    echo -e "${YELLOW}🐍 Установка Python и сопутствующих пакетов...${NC}"
    echo ""
    
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii.*$pkg "; then
            echo -e "  ${GREEN}✓${NC} $pkg уже установлен"
        else
            echo "  Установка $pkg..."
            if apt-get install -y "$pkg" > /dev/null 2>&1; then
                echo -e "    ${GREEN}✓${NC} Успешно установлен"
            else
                echo -e "    ${RED}✗${NC} Ошибка установки"
            fi
        fi
    done
    
    # Проверка установки
    echo ""
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        echo -e "${GREEN}✅ $PYTHON_VERSION успешно установлен${NC}"
        
        # Проверка pip
        if command -v pip3 &> /dev/null; then
            PIP_VERSION=$(pip3 --version | awk '{print $2}')
            echo -e "${GREEN}✅ pip $PIP_VERSION установлен${NC}"
            
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
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow 22/tcp
        
        # Включаем UFW (но не применяем правила, чтобы не заблокировать текущую сессию)
        ufw --force enable > /dev/null 2>&1 || true
        echo -e "  ${GREEN}✓${NC} UFW настроен (только SSH разрешен)"
    fi
    
    # Настройка screen
    if command -v screen &> /dev/null; then
        echo "Настройка screen..."
        if [ ! -f ~/.screenrc ]; then
            cat > ~/.screenrc << 'EOF'
# Настройки screen
defscrollback 5000
startup_message off
hardstatus alwayslastline "%{= kw}%-w%{= BW}%n %t%{-}%+w %-= %c:%s"
EOF
            echo -e "  ${GREEN}✓${NC} Конфигурация screen создана"
        fi
    fi
    
    # Настройка bash
    echo "Добавление алиасов в bash..."
    cat >> ~/.bashrc << 'EOF'

# Пользовательские алиасы
alias ll='ls -la'
alias l='ls -CF'
alias update='sudo apt update && sudo apt upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt autoclean'
alias diskspace='dust'
alias processes='btm'

# Цветной prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
    
    echo -e "  ${GREEN}✓${NC} Настройки bash добавлены"
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
    
    echo -e "  ${BLUE}Дополнительные:${NC}"
    for pkg in "${EXTRA_PACKAGES[@]}"; do
        echo "    - $pkg"
    done
    
    echo -e "  ${BLUE}Python:${NC}"
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        echo "    - $pkg"
    done
    
    echo ""
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo "  1. 📊 Проверить состояние системы"
    echo "  2. 🔄 Полное обновление системы"
    echo "  3. 📦 Установить ВСЕ пакеты (основные + дополнительные)"
    echo "  4. 🛠️  Установить только основные пакеты"
    echo "  5. 🌟 Установить дополнительные пакеты (dust, bottom)"
    echo "  6. 🐍 Установить Python"
    echo "  7. ⚙️  Настройка после установки"
    echo "  8. 🚪 Выйти"
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
    read -p "Ваш выбор [1-8]: " choice
    
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
                apt-get update
                install_main_packages
                install_extra_packages
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
                apt-get update
                install_main_packages
                echo -e "${GREEN}✅ Основные пакеты установлены!${NC}"
            else
                echo "Установка отменена."
            fi
            ;;
        5)
            echo -e "${YELLOW}Выбрано: Установка дополнительных пакетов${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                install_extra_packages
                echo -e "${GREEN}✅ Дополнительные пакеты установлены!${NC}"
            else
                echo "Установка отменена."
            fi
            ;;
        6)
            echo -e "${YELLOW}Выбрано: Установка Python${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                apt-get update
                install_python
                echo -e "${GREEN}✅ Python установлен!${NC}"
            else
                echo "Установка отменена."
            fi
            ;;
        7)
            echo -e "${YELLOW}Выбрано: Настройка после установки${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                post_install_setup
                echo -e "${GREEN}✅ Настройка завершена!${NC}"
                echo "Для применения настроек bash выполните: source ~/.bashrc"
            else
                echo "Настройка отменена."
            fi
            ;;
        8)
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
