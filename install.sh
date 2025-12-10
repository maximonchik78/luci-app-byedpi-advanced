#!/bin/bash

# ============================================================================
# Установщик luci-app-byedpi-advanced
# Автор: maximonchik78
# GitHub: https://github.com/maximonchik78/luci-app-byedpi-advanced
# ============================================================================

set -e

# Получаем абсолютный путь к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR"

# Пути установки
LUCI_DIR="/usr/lib/lua/luci"
CONTROLLER_DIR="$LUCI_DIR/controller"
MODEL_DIR="$LUCI_DIR/model/cbi"
VIEW_DIR="$LUCI_DIR/view/byedpi"
CONFIG_DIR="/etc/config"
INIT_DIR="/etc/init.d"
USR_BIN_DIR="/usr/sbin"
USR_LIBEXEC_DIR="/usr/libexec/rpcd"
BYEDPI_SCRIPTS_DIR="/etc/byedpi/scripts"

# Функция цветного вывода
print_color() {
    color="$1"
    message="$2"
    
    case "$color" in
        red) printf '\033[0;31m%s\033[0m\n' "$message" ;;
        green) printf '\033[0;32m%s\033[0m\n' "$message" ;;
        yellow) printf '\033[1;33m%s\033[0m\n' "$message" ;;
        blue) printf '\033[0;34m%s\033[0m\n' "$message" ;;
        *) printf '%s\n' "$message" ;;
    esac
}

# Проверка root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_color red "Ошибка: Этот скрипт должен быть запущен от имени root!"
        exit 1
    fi
}

# Проверка OpenWrt
check_openwrt() {
    if [ ! -f "/etc/openwrt_release" ] && [ ! -f "/etc/os-release" ]; then
        print_color yellow "Внимание: Система не похожа на OpenWrt!"
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
    print_color blue "Проверка зависимостей..."
    
    missing_deps=""
    
    # Проверяем LuCI
    if [ ! -d "/usr/lib/lua/luci" ]; then
        missing_deps="luci"
    fi
    
    # Проверяем curl
    if ! command -v curl >/dev/null 2>&1; then
        if [ -n "$missing_deps" ]; then
            missing_deps="$missing_deps curl"
        else
            missing_deps="curl"
        fi
    fi
    
    # Проверяем uci
    if ! command -v uci >/dev/null 2>&1; then
        if [ -n "$missing_deps" ]; then
            missing_deps="$missing_deps uci"
        else
            missing_deps="uci"
        fi
    fi
    
    # Проверяем bash
    if ! command -v bash >/dev/null 2>&1; then
        if [ -n "$missing_deps" ]; then
            missing_deps="$missing_deps bash"
        else
            missing_deps="bash"
        fi
    fi
    
    if [ -n "$missing_deps" ]; then
        print_color yellow "Отсутствуют зависимости: $missing_deps"
        printf "Продолжить установку? (y/N): "
        read -r reply
        case "$reply" in
            [Yy]*) ;;
            *) exit 1 ;;
        esac
    fi
}

# Создание директорий
create_dirs() {
    print_color blue "Создание директорий..."
    
    for dir in "$CONTROLLER_DIR" "$MODEL_DIR" "$VIEW_DIR" "$CONFIG_DIR" "$INIT_DIR" \
               "$USR_BIN_DIR" "$USR_LIBEXEC_DIR" "$BYEDPI_SCRIPTS_DIR" "/var/log/byedpi"; do
        mkdir -p "$dir"
    done
    
    print_color green "Директории созданы"
}

# Установка файлов LuCI
install_luci() {
    print_color blue "Установка файлов LuCI..."
    
    # Контроллер
    if [ -f "$BASE_DIR/luasrc/controller/byedpi.lua" ]; then
        cp "$BASE_DIR/luasrc/controller/byedpi.lua" "$CONTROLLER_DIR/"
        print_color green "Контроллер установлен"
    else
        print_color red "Файл контроллера не найден"
    fi
    
    # CBI модель
    if [ -f "$BASE_DIR/luasrc/model/cbi/byedpi.lua" ]; then
        cp "$BASE_DIR/luasrc/model/cbi/byedpi.lua" "$MODEL_DIR/"
        print_color green "CBI модель установлена"
    else
        print_color red "Файл CBI модели не найден"
    fi
    
    # HTML шаблоны
    if [ -d "$BASE_DIR/luasrc/view/byedpi" ]; then
        cp -r "$BASE_DIR/luasrc/view/byedpi/"* "$VIEW_DIR/"
        print_color green "HTML шаблоны установлены"
    else
        print_color yellow "Директория с шаблонами не найдена"
    fi
    
    # JSON RPC
    if [ -f "$BASE_DIR/files/usr/libexec/rpcd/byedpi" ]; then
        cp "$BASE_DIR/files/usr/libexec/rpcd/byedpi" "$USR_LIBEXEC_DIR/"
        chmod 755 "$USR_LIBEXEC_DIR/byedpi"
        print_color green "JSON RPC скрипт установлен"
    fi
}

# Установка конфигураций
install_configs() {
    print_color blue "Установка конфигураций..."
    
    # Основной конфиг byedpi
    if [ -f "$BASE_DIR/files/etc/config/byedpi" ]; then
        if [ -f "$CONFIG_DIR/byedpi" ]; then
            print_color yellow "Конфиг уже существует, создаю backup..."
            cp "$CONFIG_DIR/byedpi" "$CONFIG_DIR/byedpi.backup.$(date +%s)"
        fi
        cp "$BASE_DIR/files/etc/config/byedpi" "$CONFIG_DIR/"
        print_color green "Конфиг byedpi установлен"
    else
        print_color yellow "Конфигурационный файл не найден, создаю базовый..."
        cat > "$CONFIG_DIR/byedpi" << 'EOF'
config settings
    option enabled '1'
    option mode '0'
    option port '443,80'
    option ipv6 '0'
    option autodetect '1'
    option autodetect_interval '3600'
    option test_urls 'https://rutracker.org https://vk.com https://telegram.org'
    option log_level '1'
    option interface 'br-lan'
    option daemon '1'

config schedule
    option enabled '0'
    option start_time '00:00'
    option end_time '06:00'
    option days 'mon,tue,wed,thu,fri,sat,sun'

config statistics
    option enabled '0'
    option save_interval '300'
EOF
    fi
    
    # Скрипты автоподбора
    if [ -d "$BASE_DIR/files/etc/byedpi/scripts" ]; then
        cp -r "$BASE_DIR/files/etc/byedpi/scripts/"* "$BYEDPI_SCRIPTS_DIR/"
        chmod +x "$BYEDPI_SCRIPTS_DIR"/*.sh 2>/dev/null || true
        print_color green "Скрипты установлены"
    fi
}

# Установка init скрипта
install_init() {
    print_color blue "Установка init скрипта..."
    
    if [ -f "$BASE_DIR/files/etc/init.d/byedpi" ]; then
        cp "$BASE_DIR/files/etc/init.d/byedpi" "$INIT_DIR/"
        chmod 755 "$INIT_DIR/byedpi"
        print_color green "Init скрипт установлен"
    else
        print_color red "Init скрипт не найден"
    fi
}

# Установка скриптов автоподбора
install_autodetect() {
    print_color blue "Установка скриптов автоподбора..."
    
    # Основной скрипт автоподбора
    if [ -f "$BASE_DIR/files/usr/sbin/byedpi-autodetect" ]; then
        cp "$BASE_DIR/files/usr/sbin/byedpi-autodetect" "$USR_BIN_DIR/"
        chmod 755 "$USR_BIN_DIR/byedpi-autodetect"
        print_color green "Скрипт автоподбора установлен"
    else
        print_color yellow "Скрипт автоподбора не найден, создаю базовый..."
        cat > "$USR_BIN_DIR/byedpi-autodetect" << 'EOF'
#!/bin/sh
echo "Auto-detection is not fully implemented yet."
echo "Run: /usr/sbin/byedpi --help for available options."
exit 0
EOF
        chmod 755 "$USR_BIN_DIR/byedpi-autodetect"
    fi
    
    # Менеджер byedpi
    if [ -f "$BASE_DIR/files/usr/sbin/byedpi-manager" ]; then
        cp "$BASE_DIR/files/usr/sbin/byedpi-manager" "$USR_BIN_DIR/"
        chmod 755 "$USR_BIN_DIR/byedpi-manager"
        print_color green "Менеджер установлен"
    fi
}

# Настройка автозапуска
setup_autostart() {
    print_color blue "Настройка автозапуска..."
    
    if [ -x "$INIT_DIR/byedpi" ]; then
        "$INIT_DIR/byedpi" enable
        print_color green "Автозапуск включен"
        
        printf "Запустить ByeDPI сейчас? (Y/n): "
        read -r reply
        case "$reply" in
            [Nn]*) ;;
            *)
                "$INIT_DIR/byedpi" start
                print_color green "Сервис запущен"
                ;;
        esac
    else
        print_color red "Не удалось настроить автозапуск"
    fi
}

# Проверка ByeDPI
check_byedpi() {
    print_color blue "Проверка ByeDPI..."
    
    if [ -x "/usr/sbin/byedpi" ]; then
        print_color green "ByeDPI установлен"
    else
        print_color yellow "ByeDPI НЕ установлен!"
        echo "Установите ByeDPI командой: opkg update && opkg install byedpi"
        echo "Или скачайте с: https://github.com/DPITrickster/ByeDPI-OpenWrt"
    fi
}

# Обновление меню LuCI
update_luci_menu() {
    print_color blue "Обновление меню LuCI..."
    
    # Перезапускаем rpcd
    if [ -x "/etc/init.d/rpcd" ]; then
        /etc/init.d/rpcd restart >/dev/null 2>&1
        print_color green "RPC сервис перезапущен"
    fi
    
    # Перезапускаем uhttpd
    if [ -x "/etc/init.d/uhttpd" ]; then
        /etc/init.d/uhttpd restart >/dev/null 2>&1
        print_color green "Веб-сервер перезапущен"
    fi
    
    print_color yellow "Если меню не появилось, перезагрузите страницу"
}

# Главная функция
main() {
    print_color green "╔══════════════════════════════════════╗"
    print_color green "║  luci-app-byedpi-advanced Installer  ║"
    print_color green "╚══════════════════════════════════════╝"
    
    check_root
    check_openwrt
    check_dependencies
    
    echo ""
    print_color yellow "Начинаю установку..."
    echo ""
    
    create_dirs
    install_luci
    install_configs
    install_init
    install_autodetect
    setup_autostart
    check_byedpi
    update_luci_menu
    
    print_color green "========================================"
    print_color green "Установка завершена успешно!"
    print_color green "========================================"
    echo ""
    print_color yellow "Дальнейшие действия:"
    echo "1. Откройте веб-интерфейс: http://192.168.1.1"
    echo "2. Перейдите: Services → ByeDPI"
    echo "3. Настройте параметры и включите сервис"
    echo ""
    print_color yellow "Полезные команды:"
    echo "• Статус: /etc/init.d/byedpi status"
    echo "• Запуск: /etc/init.d/byedpi start"
    echo "• Остановка: /etc/init.d/byedpi stop"
    echo ""
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
        print_color yellow "Запуск удаления..."
        if [ -f "$BASE_DIR/uninstall.sh" ]; then
            sh "$BASE_DIR/uninstall.sh"
        else
            print_color red "Скрипт удаления не найден"
        fi
        exit 0
        ;;
    --update)
        print_color yellow "Запуск обновления..."
        echo "Обновление пока не реализовано"
        exit 0
        ;;
    *)
        main
        ;;
esac
