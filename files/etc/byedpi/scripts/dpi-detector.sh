#!/bin/sh
# DPI детектор для ByeDPI
# Проверяет наличие DPI блокировок

LOG="/tmp/dpi-detector.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG"
}

check_url() {
    url="$1"
    timeout="${2:-5}"
    
    if curl -s -I --connect-timeout "$timeout" "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

detect_dpi() {
    log "Запуск DPI детектора"
    
    # Список тестовых URL
    TEST_URLS="https://rutracker.org https://vk.com https://telegram.org https://youtube.com"
    
    blocked_count=0
    total_count=0
    
    for url in $TEST_URLS; do
        total_count=$((total_count + 1))
        if check_url "$url"; then
            log "✓ $url доступен"
        else
            log "✗ $url заблокирован (возможен DPI)"
            blocked_count=$((blocked_count + 1))
        fi
    done
    
    log "Результат: $blocked_count из $total_count сайтов заблокированы"
    
    if [ $blocked_count -gt 0 ]; then
        echo "DPI обнаружен: $blocked_count сайтов заблокированы"
        exit 1
    else
        echo "DPI не обнаружен, все сайты доступны"
        exit 0
    fi
}

case "$1" in
    detect)
        detect_dpi
        ;;
    test)
        echo "Testing DPI detector..."
        detect_dpi
        ;;
    *)
        echo "Usage: $0 {detect|test}"
        echo ""
        echo "Commands:"
        echo "  detect    Проверить наличие DPI блокировок"
        echo "  test      Тестирование скрипта"
        exit 1
        ;;
esac
