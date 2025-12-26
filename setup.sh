#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Группы пакетов для установки
declare -A PACKAGE_GROUPS=(
    ["system"]="apt-transport-https software-properties-common ca-certificates gnupg lsb-release"
    ["monitoring"]="htop nload iotop iftop ncdu bmon glances"
    ["network"]="net-tools iproute2 dnsutils traceroute mtr telnet netcat-openbsd tcpdump"
    ["security"]="ufw fail2ban clamav rkhunter lynis aide auditd"
    ["development"]="git curl wget vim nano build-essential python3 python3-pip nodejs npm"
    ["files"]="tree rsync unzip zip pv mlocate mc"
    ["utilities"]="screen tmux byobu bash-completion jq bc cron"
    ["services"]="logrotate syslog-ng smartmontools"
    ["docker"]="docker.io docker-compose containerd"
)

# Функция для вывода заголовка
print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║             Установка и настройка Linux                  ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Функция для показа меню
show_menu() {
    clear
    print_header
    
    echo -e "${YELLOW}Доступные группы пакетов:${NC}"
    echo ""
    
    local i=1
    for group in "${!PACKAGE_GROUPS[@]}"; do
        echo -e "  ${GREEN}$i.${NC} ${BLUE}$group${NC}"
        
        # Показываем первые 3 пакета из группы
        local packages=(${PACKAGE_GROUPS[$group]})
        echo -n "     "
        for ((j=0; j<3 && j<${#packages[@]}; j++)); do
            echo -n "${packages[$j]} "
        done
        [[ ${#packages[@]} -gt 3 ]] && echo -n "..."
        echo
        
        i=$((i+1))
    done
    
    echo ""
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo "  1. Полное обновление системы + все пакеты"
    echo "  2. Только полное обновление системы"
    echo "  3. Выбрать группы для установки"
    echo "  4. Индивидуальный выбор пакетов"
    echo "  5. Проверить состояние системы"
    echo "  6. Выйти"
    echo ""
}

# Полное обновление системы
full_system_update() {
    echo -e "${YELLOW}Начинаем полное обновление системы...${NC}"
    echo ""
    
    # 1. Обновление списка пакетов
    echo "📦 Обновление списка пакетов..."
    apt-get update
    
    # 2. Обновление установленных пакетов
    echo "🔄 Обновление установленных пакетов..."
    apt-get upgrade -y
    
    # 3. Обновление дистрибутива (если есть)
    echo "🚀 Обновление дистрибутива..."
    apt-get dist-upgrade -y
    
    # 4. Удаление ненужных пакетов
    echo "🧹 Очистка ненужных пакетов..."
    apt-get autoremove -y
    apt-get autoclean -y
    
    echo -e "${GREEN}✅ Полное обновление завершено!${NC}"
    echo ""
}

# Проверка состояния системы
check_system_status() {
    echo -e "${YELLOW}📊 Проверка состояния системы...${NC}"
    echo ""
    
    echo "💻 Система:"
    echo "  Hostname: $(hostname)"
    echo "  OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p)"
    
    echo ""
    echo "📈 Ресурсы:"
    echo "  CPU: $(grep -c '^processor' /proc/cpuinfo) ядер"
    echo "  RAM: $(free -h | awk '/^Mem:/ {print $2}') всего, $(free -h | awk '/^Mem:/ {print $3}') использовано"
    echo "  Disk: $(df -h / | awk 'NR==2 {print $2}') всего, $(df -h / | awk 'NR==2 {print $3}') использовано"
    
    echo ""
    echo "🌐 Сеть:"
    echo "  IP: $(hostname -I | awk '{print $1}')"
    echo "  Gateway: $(ip route | grep default | awk '{print $3}')"
    
    echo ""
    echo "🔒 Безопасность:"
    echo "  Последний вход: $(last -n 1 | head -1)"
    echo "  Неудачные попытки: $(journalctl _SYSTEMD_UNIT=ssh.service | grep "Failed password" | wc -l) (SSH)"
    
    echo ""
}

# Установка выбранных групп
install_selected_groups() {
    echo -e "${YELLOW}Выберите группы для установки (через пробел):${NC}"
    echo ""
    
    local i=1
    local groups_list=()
    for group in "${!PACKAGE_GROUPS[@]}"; do
        echo -e "  $i. $group"
        groups_list+=("$group")
        i=$((i+1))
    done
    
    echo ""
    read -p "Введите номера групп: " -a selected_indices
    
    local packages_to_install=""
    for index in "${selected_indices[@]}"; do
        local idx=$((index-1))
        if [[ $idx -ge 0 && $idx -lt ${#groups_list[@]} ]]; then
            local group="${groups_list[$idx]}"
            echo -e "${GREEN}✓ Выбрана группа: $group${NC}"
            packages_to_install+="${PACKAGE_GROUPS[$group]} "
        fi
    done
    
    if [[ -n "$packages_to_install" ]]; then
        echo ""
        echo "Установка пакетов: $packages_to_install"
        apt-get install -y $packages_to_install
        echo -e "${GREEN}✅ Установка завершена!${NC}"
    else
        echo -e "${RED}❌ Не выбрано ни одной группы${NC}"
    fi
}

# Индивидуальный выбор пакетов
install_custom_packages() {
    echo -e "${YELLOW}Введите пакеты для установки (через пробел):${NC}"
    echo "Пример: htop vim git curl docker"
    echo ""
    
    read -p "Пакеты: " -a custom_packages
    
    if [[ ${#custom_packages[@]} -gt 0 ]]; then
        echo "Установка: ${custom_packages[*]}"
        apt-get install -y "${custom_packages[@]}"
        echo -e "${GREEN}✅ Установка завершена!${NC}"
    else
        echo -e "${RED}❌ Не указано ни одного пакета${NC}"
    fi
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
    read -p "Ваш выбор [1-6]: " choice
    
    case $choice in
        1)
            echo -e "${YELLOW}Выбрано: Полное обновление + все пакеты${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                full_system_update
                apt-get install -y $(echo "${PACKAGE_GROUPS[@]}")
                echo -e "${GREEN}✅ Все пакеты установлены!${NC}"
            fi
            ;;
        2)
            echo -e "${YELLOW}Выбрано: Только полное обновление${NC}"
            read -p "Продолжить? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                full_system_update
            fi
            ;;
        3)
            echo -e "${YELLOW}Выбрано: Выбор групп${NC}"
            install_selected_groups
            ;;
        4)
            echo -e "${YELLOW}Выбрано: Индивидуальный выбор${NC}"
            install_custom_packages
            ;;
        5)
            check_system_status
            ;;
        6)
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
