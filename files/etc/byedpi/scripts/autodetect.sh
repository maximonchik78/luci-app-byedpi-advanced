#!/bin/sh

# Скрипт автоподбора для ByeDPI
# Используется byedpi-autodetect

CONFIG="/etc/config/byedpi"
LOG="/tmp/byedpi-detection.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG"
}

check_site() {
    url="$1"
    timeout="${2:-10}"
    
    if curl -s -I --connect-timeout "$timeout" "$url" 2>/dev/null | grep -q "HTTP"; then
        return 0
    fi
    
    if wget -q --spider --timeout="$timeout" "$url" 2>/dev/null; then
        return 0
    fi
    
    return 1
}

run_detection() {
    log "Запуск обнаружения DPI..."
    
    TEST_URLS="https://rutracker.org https://vk.com https://telegram.org"
    
    for url in $TEST_URLS; do
        if check_site "$url" 10; then
            log "Сайт $url доступен без обхода DPI"
        else
            log "Сайт $url недоступен - возможен DPI"
            echo "1"
            return
        fi
    done
    
    log "DPI не обнаружен, все сайты доступны"
    echo "0"
}

case "$1" in
    detect)
        run_detection
        ;;
    test)
        echo "Testing autodetect script..."
        run_detection
        ;;
    *)
        echo "Usage: $0 {detect|test}"
        exit 1
        ;;
esac
