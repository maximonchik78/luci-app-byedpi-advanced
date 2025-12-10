#!/bin/sh

# ============================================================================
# Установщик luci-app-byedpi-advanced
# Автор: maximonchik78
# GitHub: https://github.com/maximonchik78/luci-app-byedpi-advanced
# ============================================================================

set -e

# Получаем абсолютный путь к директории скрипта для надежности
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Пути установки
LUCI_DIR="/usr/lib/lua/luci"
CONTROLLER_DIR="$LUCI_DIR/controller"
MODEL_DIR="$LUCI_DIR/model/cbi"
VIEW_DIR="$LUCI_DIR/view/byedpi"
CONFIG_DIR="/etc/config"
INIT_DIR="/etc/init.d"
USR_BIN_DIR="/usr/sbin"
USR_LIBEXEC_DIR="/usr/libexec/rpcd"

# Функция для цветного вывода (POSIX-совместимая)
print_color() {
    color_code=""
    case "$1" in
        red) color_code="\033[0;31m" ;;
        green) color_code="\033[0;32m" ;;
        yellow) color_code="\033[1;33m" ;;
        blue) color_code="\033[0;34m" ;;
        *) color_code="" ;;
    esac
    printf "%b%s\033[0m\n" "$color_code" "$2"
}

# Проверка на root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_color red "Ошибка: Этот скрипт должен быть запущен от root!"
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
    missing=""
    
    if [ ! -d "/usr/lib/lua/luci" ]; then
        missing="luci"
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        missing="$missing curl"
    fi
    
    if ! command -v uci >/dev/null 2>&1; then
        missing="$missing uci"
    fi
    
    if [ -n "$missing" ]; then
        print_color yellow "Отсутствуют зависимости:$missing"
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
               "$USR_BIN_DIR" "$USR_LIBEXEC_DIR" "/etc/byedpi/scripts" "/var/log/byedpi"; do
        mkdir -p "$dir"
    done
    print_color green "Директории созданы"
}

# Установка файлов LuCI
install_luci() {
    print_color blue "Установка файлов LuCI..."
    
    if [ -f "$BASE_DIR/luasrc/controller/byedpi.lua" ]; then
        cp "$BASE_DIR/luasrc/controller/byedpi.lua" "$CONTROLLER_DIR/"
        print_color green "Контроллер установлен"
    else
        print_color red "Файл контроллера не найден"
    fi
    
    if [ -f "$BASE_DIR/luasrc/model/cbi/byedpi.lua" ]; then
        cp "$BASE_DIR/luasrc/model/cbi/byedpi.lua" "$MODEL_DIR/"
        print_color green "CBI модель установлена"
    else
        print_color red "Файл CBI модели не найден"
    fi
    
    if [ -d "$BASE_DIR/luasrc/view/byedpi" ]; then
        cp -r "$BASE_DIR/luasrc/view/byedpi/"* "$VIEW_DIR/"
        print_color green "HTML шаблоны установлены"
    fi
}

# Установка конфигов
install_configs() {
    print_color blue "Установка конфигураций..."
    
    if [ -f "$BASE_DIR/files/etc/config/byedpi" ]; then
        if [ -f "$CONFIG_DIR/byedpi" ]; then
            print_color yellow "Конфиг уже существует, создаю backup..."
            cp "$CONFIG_DIR/byedpi" "$CONFIG_DIR/byedpi.backup.$(date +%s)"
        fi
        cp "$BASE_DIR/files/etc/config/byedpi" "$CONFIG_DIR/"
        print_color green "Конфиг byedpi установлен"
    else
        cat > "$CONFIG_DIR/byedpi" << 'EOF'
config settings
    option enabled '0'
    option mode '0'
    option port '443'
    option ipv6 '0'
    option autodetect '0'
EOF
        print_color yellow "Создан базовый конфиг"
    fi
}

# Установка init скрипта
install_init() {
    print_color blue "Установка init скрипта..."
    if [ -f "$BASE_DIR/files/etc/init.d/byedpi" ]; then
        cp "$BASE_DIR/files/etc/init.d/byedpi" "$INIT_DIR/"
        chmod +x "$INIT_DIR/byedpi"
        print_color green "Init скрипт установлен"
    else
        print_color red "Init скрипт не найден"
    fi
}

# Установка скриптов автоподбора
install_autodetect() {
    print_color blue "Установка скриптов автоподбора..."
    
    # Основной скрипт автоподбора
    cat > "$USR_BIN_DIR/byedpi-autodetect" << 'EOF'
#!/bin/sh
echo "Auto-detection placeholder. Replace with actual logic."
exit 0
EOF
    chmod +x "$USR_BIN_DIR/byedpi-autodetect"
    print_color green "Скрипт автоподбора установлен"
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
    fi
}

# Обновление меню LuCI
update_luci_menu() {
    print_color blue "Обновление меню LuCI..."
    if [ -x "/etc/init.d/rpcd" ]; then
        /etc/init.d/rpcd restart >/dev/null 2>&1
        print_color green "RPC сервис перезапущен"
    fi
    
    if [ -x "/etc/init.d/uhttpd" ]; then
        /etc/init.d/uhttpd restart >/dev/null 2>&1
        print_color green "Веб-сервер перезапущен"
    fi
}

# Проверка ByeDPI
check_byedpi() {
    print_color blue "Проверка ByeDPI..."
    if [ -x "/usr/sbin/byedpi" ]; then
        print_color green "ByeDPI установлен"
    else
        print_color red "ByeDPI НЕ установлен!"
        echo "Установите ByeDPI командой:"
        echo "  opkg update && opkg install byedpi"
    fi
}

# Главная функция
main() {
    print_color green "╔══════════════════════════════════════╗"
    print_color green "║  luci-app-byedpi-advanced Installer  ║"
    print_color green "╚══════════════════════════════════════╝"
    
    check_root
    check_openwrt
    check_dependencies
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
}

# Обработка аргументов
case "$1" in
    --help|-h)
        echo "Использование: $0 [опции]"
        echo ""
        echo "Опции:"
        echo "  --help, -h     Показать эту справку"
        echo "  --uninstall    Удалить приложение"
        echo ""
        exit 0
        ;;
    --uninstall)
        print_color yellow "Запуск удаления..."
        # Функция удаления должна быть в uninstall.sh
        if [ -f "$BASE_DIR/uninstall.sh" ]; then
            sh "$BASE_DIR/uninstall.sh"
        fi
        exit 0
        ;;
    *)
        main
        ;;
esac
