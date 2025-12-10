#!/bin/bash

# Конфигурация
CONFIG_FILE="/etc/config/byedpi"
LOG_FILE="/tmp/byedpi-autodetect.log"
TEST_URLS=(
    "https://rutracker.org"
    "https://vk.com" 
    "https://telegram.org"
    "https://youtube.com"
    "https://google.com"
)

# Методы ByeByeDPI
MODES=(
    "1 --frag"
    "2 --wrong-chksum"
    "3 --wrong-seq"
    "4 --tamper-tcpack"
    "5 --tamper-tcpchksum"
    "0 --auto"
)

# Портты для тестирования
PORTS=("443" "80" "8080")

# Функция логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Функция проверки доступности сайта
check_site() {
    local url=$1
    local timeout=${2:-10}
    
    # Пробуем разные методы проверки
    if curl -s -I --connect-timeout "$timeout" "$url" 2>/dev/null | grep -q "HTTP"; then
        return 0
    fi
    
    if wget -q --spider --timeout="$timeout" "$url" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Функция тестирования комбинации
test_combo() {
    local mode=$1
    local port=$2
    local test_url=$3
    
    log "Тестирование: mode=$mode, port=$port, url=$test_url"
    
    # Запускаем byedpi с тестовыми параметрами
    /usr/sbin/byedpi -p "$port" --mode "$mode" > /dev/null 2>&1 &
    local pid=$!
    
    # Даем время на запуск
    sleep 3
    
    # Проверяем доступность
    if check_site "$test_url" 5; then
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null
        log "✓ Успех: mode=$mode, port=$port"
        return 0
    else
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null
        log "✗ Не удалось: mode=$mode, port=$port"
        return 1
    fi
}

# Функция обнаружения DPI
detect_dpi() {
    log "Начинаем обнаружение DPI..."
    
    # Проверяем базовую доступность
    for url in "${TEST_URLS[@]}"; do
        if check_site "$url" 10; then
            log "Сайт $url доступен без обхода DPI"
        else
            log "Сайт $url недоступен - возможен DPI"
            DPI_BLOCKED=1
            break
        fi
    done
    
    if [ -z "$DPI_BLOCKED" ]; then
        log "DPI не обнаружен, все сайты доступны"
        return 1
    fi
    
    # Тестируем комбинации
    for test_url in "${TEST_URLS[@]}"; do
        if ! check_site "$test_url" 10; then
            log "Определение параметров для $test_url"
            
            for port in "${PORTS[@]}"; do
                for mode_combo in "${MODES[@]}"; do
                    mode_num=$(echo "$mode_combo" | cut -d' ' -f1)
                    mode_arg=$(echo "$mode_combo" | cut -d' ' -f2-)
                    
                    if test_combo "$mode_arg" "$port" "$test_url"; then
                        BEST_MODE="$mode_num"
                        BEST_PORT="$port"
                        BEST_URL="$test_url"
                        log "Найдена рабочая комбинация: mode=$BEST_MODE, port=$BEST_PORT"
                        return 0
                    fi
                done
            done
        fi
    done
    
    log "Не удалось найти рабочую комбинацию"
    return 1
}

# Основная функция
main() {
    log "Запуск автоподбора параметров ByeDPI"
    
    # Проверяем наличие byedpi
    if [ ! -f "/usr/sbin/byedpi" ]; then
        log "Ошибка: byedpi не установлен"
        exit 1
    fi
    
    # Обнаруживаем DPI и находим параметры
    if detect_dpi; then
        log "Обновление конфигурации: mode=$BEST_MODE, port=$BEST_PORT"
        
        # Обновляем конфиг
        uci set byedpi.@settings[0].mode="$BEST_MODE"
        uci set byedpi.@settings[0].port="$BEST_PORT"
        uci commit byedpi
        
        # Перезапускаем службу
        /etc/init.d/byedpi restart
        
        log "Автоподбор завершен успешно!"
        echo "success:$BEST_MODE:$BEST_PORT"
    else
        log "Автоподбор не удался, используются значения по умолчанию"
        echo "fail:0:443"
    fi
}

# Запуск
main "$@"
