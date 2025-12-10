#!/bin/sh

# ============================================================================
# Установщик luci-app-byedpi-advanced
# Автор: maximonchik78
# GitHub: https://github.com/maximonchik78/luci-app-byedpi-advanced
# ============================================================================

set -e

# Цвета для вывода (без -e, используем printf)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Пути установки
LUCI_DIR="/usr/lib/lua/luci"
CONTROLLER_DIR="$LUCI_DIR/controller"
MODEL_DIR="$LUCI_DIR/model/cbi"
VIEW_DIR="$LUCI_DIR/view/byedpi"
CONFIG_DIR="/etc/config"
INIT_DIR="/etc/init.d"
USR_BIN_DIR="/usr/sbin"
USR_LIBEXEC_DIR="/usr/libexec/rpcd"

# Функция для цветного вывода
print_color() {
    local color=$1
    local message=$2
    printf "%b%s%b\n" "$color" "$message" "$NC"
}

# Проверка на root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_color "$RED" "Ошибка: Этот скрипт должен быть запущен от root!"
        exit 1
    fi
}

# Проверка OpenWrt
check_openwrt() {
    if [ ! -f "/etc/openwrt_release" ]; then
        print_color "$YELLOW" "Предупреждение: Не похоже на OpenWrt систему!"
        printf "Продолжить установку? (y/N): "
        read -r reply
        case "$reply" in
            [Yy]*) ;;
            *) exit 1 ;;
        esac
    fi
}

# Проверка зависимостей
check_dependencies() {
    print_color "$BLUE" "Проверка зависимостей..."
    
    local missing=""
    
    # Проверяем LuCI
    if [ ! -d "/usr/lib/lua/luci" ]; then
        missing="$missing luci"
    fi
    
    # Проверяем curl для автоподбора
    if ! command -v curl >/dev/null 2>&1; then
        missing="$missing curl"
    fi
    
    # Проверяем uci
    if ! command -v uci >/dev/null 2>&1; then
        missing="$missing uci"
    fi
    
    if [ -n "$missing" ]; then
        print_color "$YELLOW" "Отсутствуют зависимости: $missing"
        echo "Установите их командой: opkg install$missing"
        printf "Продолжить установку? (y/N): "
        read -r reply
        case "$reply" in
            [Yy]*) ;;
            *) exit 1 ;;
        esac
    fi
}

# Создание директорий
create_directories() {
    print_color "$BLUE" "Создание директорий..."
    
    for dir in "$CONTROLLER_DIR" "$MODEL_DIR" "$VIEW_DIR" "$CONFIG_DIR" "$INIT_DIR" \
               "$USR_BIN_DIR" "$USR_LIBEXEC_DIR" "/etc/byedpi/scripts" "/var/log/byedpi"; do
        mkdir -p "$dir"
    done
    
    print_color "$GREEN" "✓ Директории созданы"
}

# Копирование файлов LuCI
install_luci_files() {
    print_color "$BLUE" "Установка файлов LuCI..."
    
    # Копируем контроллер
    if [ -f "./luasrc/controller/byedpi.lua" ]; then
        cp "./luasrc/controller/byedpi.lua" "$CONTROLLER_DIR/"
        print_color "$GREEN" "✓ Контроллер установлен"
    else
        print_color "$YELLOW" "⚠ Файл контроллера не найден"
    fi
    
    # Копируем CBI модель
    if [ -f "./luasrc/model/cbi/byedpi.lua" ]; then
        cp "./luasrc/model/cbi/byedpi.lua" "$MODEL_DIR/"
        print_color "$GREEN" "✓ CBI модель установлена"
    else
        print_color "$YELLOW" "⚠ Файл CBI модели не найден"
    fi
    
    # Копируем HTML шаблоны
    if [ -d "./luasrc/view/byedpi" ]; then
        cp -r "./luasrc/view/byedpi/"* "$VIEW_DIR/"
        print_color "$GREEN" "✓ HTML шаблоны установлены"
    else
        print_color "$YELLOW" "⚠ Директория с шаблонами не найдена"
    fi
    
    # Копируем JSON RPC
    if [ -f "./files/usr/libexec/rpcd/byedpi" ]; then
        cp "./files/usr/libexec/rpcd/byedpi" "$USR_LIBEXEC_DIR/"
        chmod 755 "$USR_LIBEXEC_DIR/byedpi"
        print_color "$GREEN" "✓ JSON RPC скрипт установлен"
    fi
}

# Копирование конфигурационных файлов
install_config_files() {
    print_color "$BLUE" "Установка конфигурационных файлов..."
    
    # Конфиг byedpi
    if [ -f "./files/etc/config/byedpi" ]; then
        if [ -f "$CONFIG_DIR/byedpi" ]; then
            print_color "$YELLOW" "⚠ Конфиг byedpi уже существует, создаю резервную копию..."
            cp "$CONFIG_DIR/byedpi" "$CONFIG_DIR/byedpi.backup.$(date +%s)"
        fi
        cp "./files/etc/config/byedpi" "$CONFIG_DIR/"
        print_color "$GREEN" "✓ Конфигурационный файл установлен"
    else
        print_color "$YELLOW" "⚠ Конфигурационный файл не найден, создаю базовый..."
        cat > "$CONFIG_DIR/byedpi" << 'EOF'
config settings
    option enabled '1'
    option mode '0'
    option port '443'
    option ipv6 '0'
    option autodetect '1'
    option autodetect_interval '3600'
    option test_urls 'https://rutracker.org https://vk.com https://telegram.org'
    option log_level '1'
    option interface 'br-lan'
    option daemon '1'
EOF
    fi
    
    # Создаем директорию для скриптов
    if [ -d "./files/etc/byedpi/scripts" ]; then
        cp -r "./files/etc/byedpi/scripts/"* "/etc/byedpi/scripts/"
        chmod +x /etc/byedpi/scripts/*.sh 2>/dev/null || true
        print_color "$GREEN" "✓ Скрипты установлены"
    fi
}

# Копирование init скриптов
install_init_scripts() {
    print_color "$BLUE" "Установка init скриптов..."
    
    if [ -f "./files/etc/init.d/byedpi" ]; then
        cp "./files/etc/init.d/byedpi" "$INIT_DIR/"
        chmod 755 "$INIT_DIR/byedpi"
        print_color "$GREEN" "✓ Init скрипт установлен"
    else
        print_color "$RED" "✗ Init скрипт не найден!"
        exit 1
    fi
}

# Копирование исполняемых файлов
install_bin_files() {
    print_color "$BLUE" "Установка исполняемых файлов..."
    
    # Основной скрипт автоподбора
    if [ -f "./files/usr/sbin/byedpi-autodetect" ]; then
        cp "./files/usr/sbin/byedpi-autodetect" "$USR_BIN_DIR/"
        chmod 755 "$USR_BIN_DIR/byedpi-autodetect"
        print_color "$GREEN" "✓ Скрипт автоподбора установлен"
    else
        print_color "$YELLOW" "⚠ Скрипт автоподбора не найден"
    fi
    
    # Менеджер byedpi
    if [ -f "./files/usr/sbin/byedpi-manager" ]; then
        cp "./files/usr/sbin/byedpi-manager" "$USR_BIN_DIR/"
        chmod 755 "$USR_BIN_DIR/byedpi-manager"
        print_color "$GREEN" "✓ Менеджер установлен"
    fi
}

# Установка ByeDPI (если не установлен)
install_byedpi() {
    print_color "$BLUE" "Проверка ByeDPI..."
    
    if [ ! -x "/usr/sbin/byedpi" ]; then
        print_color "$YELLOW" "ByeDPI не найден. Попытка установки..."
        
        if command -v opkg >/dev/null 2>&1; then
            if opkg update >/dev/null 2>&1 && opkg install byedpi >/dev/null 2>&1; then
                print_color "$GREEN" "✓ ByeDPI успешно установлен"
            else
                print_color "$RED" "✗ Не удалось установить ByeDPI через opkg"
                echo "Установите ByeDPI вручную:"
                echo "1. Скачайте с https://github.com/DPITrickster/ByeDPI-OpenWrt"
                echo "2. Установите: opkg install byedpi_*.ipk"
            fi
        else
            print_color "$RED" "✗ opkg не найден. Установите ByeDPI вручную."
        fi
    else
        print_color "$GREEN" "✓ ByeDPI уже установлен"
    fi
}

# Настройка автозапуска
setup_autostart() {
    print_color "$BLUE" "Настройка автозапуска..."
    
    if [ -x "$INIT_DIR/byedpi" ]; then
        "$INIT_DIR/byedpi" enable
        print_color "$GREEN" "✓ Сервис добавлен в автозапуск"
        
        # Запускаем сервис
        printf "Запустить ByeDPI сейчас? (Y/n): "
        read -r reply
        case "$reply" in
            [Nn]*) ;;
            *)
                "$INIT_DIR/byedpi" start
                print_color "$GREEN" "✓ Сервис запущен"
                ;;
        esac
    else
        print_color "$RED" "✗ Не удалось настроить автозапуск"
    fi
}

# Создание симлинков для LuCI
create_luci_symlinks() {
    print_color "$BLUE" "Создание симлинков для LuCI..."
    
    # Проверяем, есть ли директория applications
    if [ -d "/usr/share/luci/menu.d" ]; then
        # Создаем симлинк для меню
        ln -sf "$CONTROLLER_DIR/byedpi.lua" "/usr/share/luci/menu.d/luci-app-byedpi.json" 2>/dev/null || true
        print_color "$GREEN" "✓ Симлинк меню создан"
    fi
    
    # Обновляем кэш LuCI
    if [ -x "/etc/init.d/rpcd" ]; then
        /etc/init.d/rpcd restart >/dev/null 2>&1
        print_color "$GREEN" "✓ RPC сервис перезапущен"
    fi
    
    if [ -x "/etc/init.d/uhttpd" ]; then
        /etc/init.d/uhttpd restart >/dev/null 2>&1
        print_color "$GREEN" "✓ Веб-сервер перезапущен"
    fi
}

# Проверка установки
verify_installation() {
    print_color "$BLUE" "Проверка установки..."
    
    local errors=0
    
    echo "1. Контроллер LuCI: "
    if [ -f "$CONTROLLER_DIR/byedpi.lua" ]; then
        print_color "$GREEN" "   OK"
    else
        print_color "$RED" "   FAIL"
        errors=$((errors + 1))
    fi
    
    echo "2. CBI модель: "
    if [ -f "$MODEL_DIR/byedpi.lua" ]; then
        print_color "$GREEN" "   OK"
    else
        print_color "$RED" "   FAIL"
        errors=$((errors + 1))
    fi
    
    echo "3. Init скрипт: "
    if [ -x "$INIT_DIR/byedpi" ]; then
        print_color "$GREEN" "   OK"
    else
        print_color "$RED" "   FAIL"
        errors=$((errors + 1))
    fi
    
    echo "4. Конфигурация: "
    if [ -f "$CONFIG_DIR/byedpi" ]; then
        print_color "$GREEN" "   OK"
    else
        print_color "$RED" "   FAIL"
        errors=$((errors + 1))
    fi
    
    echo "5. Скрипт автоподбора: "
    if [ -x "$USR_BIN_DIR/byedpi-autodetect" ]; then
        print_color "$GREEN" "   OK"
    else
        print_color "$RED" "   FAIL"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        print_color "$GREEN" "✓ Установка завершена успешно!"
    else
        print_color "$YELLOW" "⚠ Установка завершена с $errors ошибками"
    fi
}

# Показ информации после установки
show_post_install_info() {
    echo ""
    print_color "$BLUE" "========================================"
    print_color "$GREEN" "luci-app-byedpi-advanced установлен!"
    print_color "$BLUE" "========================================"
    echo ""
    print_color "$YELLOW" "Инструкция по использованию:"
    echo "1. Откройте веб-интерфейс LuCI: http://192.168.1.1"
    echo "2. Перейдите: Services → ByeDPI Advanced"
    echo "3. Включите автоопределение DPI"
    echo "4. Нажмите 'Start Auto-detection'"
    echo ""
    print_color "$YELLOW" "Команды для управления:"
    echo "• Запуск сервиса: /etc/init.d/byedpi start"
    echo "• Остановка сервиса: /etc/init.d/byedpi stop"
    echo "• Автоподбор параметров: /usr/sbin/byedpi-autodetect"
    echo "• Тестирование: /etc/init.d/byedpi test"
    echo ""
    print_color "$YELLOW" "Логи:"
    echo "• Лог автоподбора: /tmp/byedpi-autodetect.log"
    echo "• Лог сервиса: /var/log/byedpi.log"
    echo ""
    print_color "$BLUE" "========================================"
}

# Основная функция
main() {
    print_color "$GREEN" "╔══════════════════════════════════════╗"
    print_color "$GREEN" "║  luci-app-byedpi-advanced Installer  ║"
    print_color "$GREEN" "║         для OpenWrt 24+              ║"
    print_color "$GREEN" "╚══════════════════════════════════════╝"
    
    check_root
    check_openwrt
    check_dependencies
    
    echo ""
    print_color "$YELLOW" "Начинаю установку..."
    echo ""
    
    create_directories
    install_luci_files
    install_config_files
    install_init_scripts
    install_bin_files
    install_byedpi
    setup_autostart
    create_luci_symlinks
    verify_installation
    show_post_install_info
}

# Обработка аргументов
case "$1" in
    --help|-h)
        echo "Использование: $0 [опции]"
        echo ""
        echo "Опции:"
        echo "  --help, -h     Показать эту справку"
        echo "  --uninstall    Удалить приложение"
        echo "  --update       Обновить приложение"
        echo ""
        exit 0
        ;;
    --uninstall)
        print_color "$YELLOW" "Запуск удаления..."
        # TODO: Добавить функцию удаления
        exit 0
        ;;
    --update)
        print_color "$YELLOW" "Запуск обновления..."
        # TODO: Добавить функцию обновления
        exit 0
        ;;
    *)
        main
        ;;
esac
