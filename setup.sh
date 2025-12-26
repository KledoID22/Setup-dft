#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Пакеты для установки
PACKAGES=("screen" "ufw" "nano")

# Функция показа меню
show_menu() {
    clear
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${GREEN}          Установка пакетов${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "Список пакетов для установки:"
    
    for i in "${!PACKAGES[@]}"; do
        echo "  $((i+1)). ${PACKAGES[$i]}"
    done
    
    echo ""
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo "  1. Установить все пакеты"
    echo "  2. Выборочная установка"
    echo "  3. Отменить установку"
    echo ""
}

# Функция выборочной установки
selective_install() {
    echo ""
    echo "Выберите пакеты для установки (через пробел):"
    
    for i in "${!PACKAGES[@]}"; do
        echo "  $((i+1)). ${PACKAGES[$i]}"
    done
    
    echo -n "Введите номера: "
    read -a choices
    
    for choice in "${choices[@]}"; do
        index=$((choice-1))
        if [[ $index -ge 0 && $index -lt ${#PACKAGES[@]} ]]; then
            apt-get install -y "${PACKAGES[$index]}"
        fi
    done
}

# Основной скрипт
set -e

# Проверка аргументов (для автоматической установки)
if [[ "$1" == "--auto" || "$1" == "-y" ]]; then
    echo "Автоматическая установка..."
    apt-get update
    apt-get install -y "${PACKAGES[@]}"
    echo -e "${GREEN}Готово!${NC}"
    exit 0
fi

# Показать меню
show_menu

# Чтение выбора
read -p "Ваш выбор [1-3]: " main_choice

case $main_choice in
    1)
        echo "Установка всех пакетов..."
        apt-get update
        apt-get install -y "${PACKAGES[@]}"
        echo -e "${GREEN}Готово! Все пакеты установлены.${NC}"
        ;;
    2)
        apt-get update
        selective_install
        echo -e "${GREEN}Готово!${NC}"
        ;;
    3)
        echo -e "${RED}Установка отменена.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Неверный выбор. Выход.${NC}"
        exit 1
        ;;
esac
