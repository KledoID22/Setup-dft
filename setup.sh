#!/bin/bash

# Функция для запроса подтверждения
confirm_install() {
    echo "========================================"
    echo "Будет установлено:"
    echo "1. screen - менеджер терминалов"
    echo "2. ufw - фаервол"
    echo "3. nano - текстовый редактор"
    echo "========================================"
    
    while true; do
        read -p "Вы действительно хотите установить эти пакеты? (Y/n): " answer
        
        case $answer in
            [Yy]|"")
                echo "Начинаем установку..."
                return 0
                ;;
            [Nn])
                echo "Установка отменена."
                exit 0
                ;;
            *)
                echo "Пожалуйста, введите Y (да) или N (нет)."
                ;;
        esac
    done
}

# Основной скрипт
set -e

# Запрашиваем подтверждение
confirm_install

# Установка пакетов
apt-get update
apt-get install -y screen
apt-get install -y ufw
apt-get install -y nano

echo "Готово!"
echo "Все пакеты успешно установлены!"
