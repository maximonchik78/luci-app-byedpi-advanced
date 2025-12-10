#!/bin/sh

# ================================================
# Установщик luci-app-byedpi-advanced для OpenWrt
# Версия: 2.0
# Автор: maximonchik78
# GitHub: https://github.com/maximonchik78/luci-app-byedpi-advanced
# ================================================

set -e

# Цвета для вывода
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

# Проверка на root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Ошибка: Этот скрипт должен быть запущен от root!${NC}"
        exit 1
    fi
}

# Проверка OpenWrt
check_openwrt() {
    if [ ! -f "/etc/openwrt_release" ]; then
        echo -e "${YELLOW}Предупреждение: Не похоже на OpenWrt систему!${NC}"
        read -p "Продолжить установку? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    fi
}

# Проверка зависимостей
check_dependencies() {
    echo -e "${BLUE}Проверка зависимостей...${NC}"
    
    local missing=()
    
    # Проверяем LuCI
    if [ ! -d "/usr/lib/lua/luci" ]; then
        missing+=("luci")
    fi
    
    # Проверяем curl для автоподбора
    if ! command -v curl >/dev/null 2>&1; then
        missing+=("curl")
    fi
    
    # Проверяем uci
    if ! command -v uci >/dev/null 2>&1; then
        missing+=("uci")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Отсутствуют зависимости: ${missing[*]}${NC}"
        echo "Установите их командой: opkg install ${missing[*]}"
        read -p "Продолжить установку? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    fi
}

# Создание директорий
create_directories() {
    echo -e "${BLUE}Создание директорий...${NC}"
    
    mkdir -p "$CONTROLLER_DIR"
    mkdir -p "$MODEL_DIR"
    mkdir -p "$VIEW_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$INIT_DIR"
    mkdir -p "$USR_BIN_DIR"
    mkdir -p "$USR_LIBEXEC_DIR"
    mkdir -p "/etc/byedpi/scripts"
    mkdir -p "/var/log/byedpi"
    
    echo -e "${GREEN}✓ Директории созданы${NC}"
}

# Копирование файлов LuCI
install_luci_files() {
    echo -e "${BLUE}Установка файлов LuCI...${NC}"
    
    # Копируем контроллер
    if [ -f "./luasrc/controller/byedpi.lua" ]; then
        cp "./luasrc/controller/byedpi.lua" "$CONTROLLER_DIR/"
        echo -e "${GREEN}✓ Контроллер установлен${NC}"
    else
        echo -e "${YELLOW}⚠ Файл контроллера не найден${NC}"
    fi
    
    # Копируем CBI модель
    if [ -f "./luasrc/model/cbi/byedpi.lua" ]; then
        cp "./luasrc/model/cbi/byedpi.lua" "$MODEL_DIR/"
        echo -e "${GREEN}✓ CBI модель установлена${NC}"
    else
        echo -e "${YELLOW}⚠ Файл CBI модели не найден${NC}"
    fi
    
    # Копируем HTML шаблоны
    if [ -d "./luasrc/view/byedpi" ]; then
        cp -r "./luasrc/view/byedpi/"* "$VIEW_DIR/"
        echo -e "${GREEN}✓ HTML шаблоны установлены${NC}"
    else
        echo -e "${YELLOW}⚠ Директория с шаблонами не найдена${NC}"
    fi
    
    # Копируем JSON RPC
    if [ -f "./files/usr/libexec/rpcd/byedpi" ]; then
        cp "./files/usr/libexec/rpcd/byedpi" "$USR_LIBEXEC_DIR/"
        chmod 755 "$USR_LIBEXEC_DIR/byedpi"
        echo -e "${GREEN}✓ JSON RPC скрипт установлен${NC}"
    fi
}

# Копирование конфигурационных файлов
install_config_files() {
    echo -e "${BLUE}Установка конфигурационных файлов...${NC}"
    
    # Конфиг byedpi
    if [ -f "./files/etc/config/byedpi" ]; then
        if [ -f "$CONFIG_DIR/byedpi" ]; then
            echo -e "${YELLOW}⚠ Конфиг byedpi уже существует, создаю резервную копию...${NC}"
            cp "$CONFIG_DIR/byedpi" "$CONFIG_DIR/byedpi.backup.$(date +%s)"
        fi
        cp "./files/etc/config/byedpi" "$CONFIG_DIR/"
        echo -e "${GREEN}✓ Конфигурационный файл установлен${NC}"
    else
        echo -e "${YELLOW}⚠ Конфигурационный файл не найден, создаю базовый...${NC}"
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
EOF
    fi
    
    # Создаем директорию для скриптов
    if [ -d "./files/etc/byedpi/scripts" ]; then
        cp -r "./files/etc/byedpi/scripts/"* "/etc/byedpi/scripts/"
        chmod +x /etc/byedpi/scripts/*.sh 2>/dev/null || true
        echo -e "${GREEN}✓ Скрипты установлены${NC}"
    fi
}

# Копирование init скриптов
install_init_scripts() {
    echo -e "${BLUE}Установка init скриптов...${NC}"
    
    if [ -f "./files/etc/init.d/byedpi" ]; then
        cp "./files/etc/init.d/byedpi" "$INIT_DIR/"
        chmod 755 "$INIT_DIR/byedpi"
        echo -e "${GREEN}✓ Init скрипт установлен${NC}"
    else
        echo -e "${RED}✗ Init скрипт не найден!${NC}"
        exit 1
    fi
}

# Копирование исполняемых файлов
install_bin_files() {
    echo -e "${BLUE}Установка исполняемых файлов...${NC}"
    
    # Основной скрипт автоподбора
    if [ -f "./files/usr/sbin/byedpi-autodetect" ]; then
        cp "./files/usr/sbin/byedpi-autodetect" "$USR_BIN_DIR/"
        chmod 755 "$USR_BIN_DIR/byedpi-autodetect"
        echo -e "${GREEN}✓ Скрипт автоподбора установлен${NC}"
    else
        echo -e "${YELLOW}⚠ Скрипт автоподбора не найден${NC}"
    fi
    
    # Менеджер byedpi
    if [ -f "./files/usr/sbin/byedpi-manager" ]; then
        cp "./files/usr/sbin/byedpi-manager" "$USR_BIN_DIR/"
        chmod 755 "$USR_BIN_DIR/byedpi-manager"
        echo -e "${GREEN}✓ Менеджер установлен${NC}"
    fi
}

# Установка ByeDPI (если не установлен)
install_byedpi() {
    echo -e "${BLUE}Проверка ByeDPI...${NC}"
    
    if [ ! -x "/usr/sbin/byedpi" ]; then
        echo -e "${YELLOW}ByeDPI не найден. Попытка установки...${NC}"
        
        if command -v opkg >/dev/null 2>&1; then
            opkg update
            if opkg install byedpi; then
                echo -e "${GREEN}✓ ByeDPI успешно установлен${NC}"
            else
                echo -e "${RED}✗ Не удалось установить ByeDPI через opkg${NC}"
                echo -e "${YELLOW}Установите ByeDPI вручную:${NC}"
                echo "1. Скачайте с https://github.com/DPITrickster/ByeDPI-OpenWrt"
                echo "2. Установите: opkg install byedpi_*.ipk"
            fi
        else
            echo -e "${RED}✗ opkg не найден. Установите ByeDPI вручную.${NC}"
        fi
    else
        echo -e "${GREEN}✓ ByeDPI уже установлен${NC}"
    fi
}

# Настройка автозапуска
setup_autostart() {
    echo -e "${BLUE}Настройка автозапуска...${NC}"
    
    if [ -x "$INIT_DIR/byedpi" ]; then
        "$INIT_DIR/byedpi" enable
        echo -e "${GREEN}✓ Сервис добавлен в автозапуск${NC}"
        
        # Запускаем сервис
        read -p "Запустить ByeDPI сейчас? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [ -z "$REPLY" ]; then
            "$INIT_DIR/byedpi" start
            echo -e "${GREEN}✓ Сервис запущен${NC}"
        fi
    else
        echo -e "${RED}✗ Не удалось настроить автозапуск${NC}"
    fi
}

# Создание симлинков для LuCI
create_luci_symlinks() {
    echo -e "${BLUE}Создание симлинков для LuCI...${NC}"
    
    # Проверяем, есть ли директория applications
    if [ -d "/usr/share/luci/menu.d" ]; then
        # Создаем симлинк для меню
        ln -sf "$CONTROLLER_DIR/byedpi.lua" "/usr/share/luci/menu.d/luci-app-byedpi.json" 2>/dev/null || true
        echo -e "${GREEN}✓ Симлинк меню создан${NC}"
    fi
    
    # Обновляем кэш LuCI
    if [ -x "/etc/init.d/rpcd" ]; then
        /etc/init.d/rpcd restart
        echo -e "${GREEN}✓ RPC сервис перезапущен${NC}"
    fi
    
    if [ -x "/etc/init.d/uhttpd" ]; then
        /etc/init.d/uhttpd restart
        echo -e "${GREEN}✓ Веб-сервер перезапущен${NC}"
    fi
}

# Проверка установки
verify_installation() {
    echo -e "\n${BLUE}Проверка установки...${NC}"
    
    local errors=0
    
    echo -n "1. Контроллер LuCI: "
    if [ -f "$CONTROLLER_DIR/byedpi.lua" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        errors=$((errors+1))
    fi
    
    echo -n "2. CBI модель: "
    if [ -f "$MODEL_DIR/byedpi.lua" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        errors=$((errors+1))
    fi
    
    echo -n "3. Init скрипт: "
    if [ -x "$INIT_DIR/byedpi" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        errors=$((errors+1))
    fi
    
    echo -n "4. Конфигурация: "
    if [ -f "$CONFIG_DIR/byedpi" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        errors=$((errors+1))
    fi
    
    echo -n "5. Скрипт автоподбора: "
    if [ -x "$USR_BIN_DIR/byedpi-autodetect" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        errors=$((errors+1))
    fi
    
    if [ $errors -eq 0 ]; then
        echo -e "\n${GREEN}✓ Установка завершена успешно!${NC}"
    else
        echo -e "\n${YELLOW}⚠ Установка завершена с $errors ошибками${NC}"
    fi
}

# Показ информации после установки
show_post_install_info() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${GREEN}luci-app-byedpi-advanced установлен!${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Инструкция по использованию:${NC}"
    echo "1. Откройте веб-интерфейс LuCI: http://192.168.1.1"
    echo "2. Перейдите: Services → ByeDPI Advanced"
    echo "3. Включите автоопределение DPI"
    echo "4. Нажмите 'Start Auto-detection'"
    echo ""
    echo -e "${YELLOW}Команды для управления:${NC}"
    echo "• Запуск сервиса: /etc/init.d/byedpi start"
    echo "• Остановка сервиса: /etc/init.d/byedpi stop"
    echo "• Автоподбор параметров: /usr/sbin/byedpi-autodetect"
    echo "• Тестирование: /etc/init.d/byedpi test"
    echo ""
    echo -e "${YELLOW}Логи:${NC}"
    echo "• Лог автоподбора: /tmp/byedpi-autodetect.log"
    echo "• Лог сервиса: /var/log/byedpi.log"
    echo ""
    echo -e "${BLUE}========================================${NC}"
}

# Основная функция
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════╗"
    echo "║  luci-app-byedpi-advanced Installer  ║"
    echo "║         для OpenWrt 24+              ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_root
    check_openwrt
    check_dependencies
    
    echo ""
    echo -e "${YELLOW}Начинаю установку...${NC}"
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
        echo -e "${YELLOW}Запуск удаления...${NC}"
        # TODO: Добавить функцию удаления
        exit 0
        ;;
    --update)
        echo -e "${YELLOW}Запуск обновления...${NC}"
        # TODO: Добавить функцию обновления
        exit 0
        ;;
    *)
        main
        ;;
esac
