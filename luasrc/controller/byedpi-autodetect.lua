#!/bin/sh

# Автоподбор параметров для ByeDPI
# Версия: 2.0
# Автор: maximonchik78

CONFIG="/etc/config/byedpi"
LOG="/tmp/byedpi-autodetect.log"
PIDFILE="/var/run/byedpi-autodetect.pid"
LOCKFILE="/var/lock/byedpi-autodetect.lock"

# Функция логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG"
    logger -t "byedpi-autodetect" "$1"
}

check_dependencies() {
    missing=""
    
    for cmd in curl wget pgrep kill uci; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing="$missing $cmd"
        fi
    done
    
    if [ -n "$missing" ]; then
        log "Отсутствуют зависимости:$missing"
        return 1
    fi
    
    if [ ! -x "/usr/sbin/byedpi" ]; then
        log "ByeDPI не найден или не исполняемый"
        return 1
    fi
    
    return 0
}

acquire_lock() {
    exec 200>"$LOCKFILE"
    if ! flock -n 200; then
        log "Другой процесс автоподбора уже запущен"
        return 1
    fi
    echo $$ > "$PIDFILE"
    return 0
}

release_lock() {
    rm -f "$PIDFILE"
    flock -u 200
    rm -f "$LOCKFILE"
}

stop_byedpi() {
    if pgrep -f "/usr/sbin/byedpi" >/dev/null 2>&1; then
        log "Останавливаю ByeDPI..."
        pkill -f "/usr/sbin/byedpi"
        sleep 2
        pkill -9 -f "/usr/sbin/byedpi" 2>/dev/null || true
    fi
}

test_connection() {
    url="$1"
    timeout="${2:-10}"
    
    if curl -s -I --connect-timeout "$timeout" "$url" 2>/dev/null | grep -q -E "HTTP.*200|HTTP.*30[0-9]"; then
        return 0
    fi
    
    if wget --spider --timeout="$timeout" -t 1 "$url" >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

test_bypass_method() {
    method="$1"
    port="$2"
    test_url="$3"
    
    log "Тестирование: метод=$method, порт=$port, URL=$test_url"
    
    cmd="/usr/sbin/byedpi"
    
    case "$method" in
        1) cmd="$cmd --ttl" ;;
        2) cmd="$cmd --wrong-chksum" ;;
        3) cmd="$cmd --wrong-seq" ;;
        4) cmd="$cmd --frag" ;;
        5) cmd="$cmd --tamper-tcpack" ;;
        6) cmd="$cmd --tamper-tcpchksum" ;;
        0|*) cmd="$cmd --auto" ;;
    esac
    
    cmd="$cmd -p $port --daemon"
    
    eval "$cmd" >/dev/null 2>&1 &
    pid=$!
    
    sleep 3
    
    if ! ps -p "$pid" >/dev/null 2>&1; then
        log "Ошибка запуска ByeDPI с параметрами: method=$method, port=$port"
        return 1
    fi
    
    success=0
    i=1
    while [ $i -le 3 ]; do
        if test_connection "$test_url" 5; then
            success=1
            break
        fi
        sleep 2
        i=$((i + 1))
    done
    
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    
    if [ $success -eq 1 ]; then
        log "Успех: метод=$method, порт=$port"
        return 0
    else
        log "Не удалось: метод=$method, порт=$port"
        return 1
    fi
}

detect_best_method() {
    best_method="0"
    best_port="443"
    found=0
    
    log "Начинаю сканирование методов обхода DPI..."
    
    PORTS="443 80 8080 53"
    METHODS="0 1 2 3 4 5 6"
    TEST_URLS="https://rutracker.org https://vk.com https://telegram.org https://twitter.com https://github.com"
    
    dpi_detected=0
    for url in $TEST_URLS; do
        if ! test_connection "$url" 10; then
            log "Обнаружена блокировка: $url"
            dpi_detected=1
            break
        fi
    done
    
    if [ $dpi_detected -eq 0 ]; then
        log "DPI блокировки не обнаружены"
        echo "0:443"
        return 0
    fi
    
    for port in $PORTS; do
        for method in $METHODS; do
            for test_url in $TEST_URLS; do
                if ! test_connection "$test_url" 5; then
                    if test_bypass_method "$method" "$port" "$test_url"; then
                        best_method="$method"
                        best_port="$port"
                        found=1
                        break 3
                    fi
                fi
            done
        done
    done
    
    if [ $found -eq 1 ]; then
        log "Найден оптимальный метод: $best_method, порт: $best_port"
        echo "$best_method:$best_port"
        return 0
    else
        log "Не удалось найти рабочий метод обхода DPI"
        return 1
    fi
}

update_config() {
    method="$1"
    port="$2"
    
    log "Обновляю конфигурацию: method=$method, port=$port"
    
    uci set byedpi.@settings[0].mode="$method"
    uci set byedpi.@settings[0].port="$port"
    uci commit byedpi
    
    log "Конфигурация обновлена"
}

main() {
    log "=== Запуск автоподбора параметров ByeDPI ==="
    
    if ! check_dependencies; then
        exit 1
    fi
    
    if ! acquire_lock; then
        exit 1
    fi
    
    stop_byedpi
    
    if result=$(detect_best_method); then
        IFS=':' read -r best_method best_port <<- EOF
$result
EOF
        
        update_config "$best_method" "$best_port"
        
        if [ -x "/etc/init.d/byedpi" ]; then
            /etc/init.d/byedpi restart
            log "ByeDPI перезапущен с новыми параметрами"
        fi
        
        log "Автоподбор успешно завершен!"
        log "Результат: Метод=$best_method, Порт=$best_port"
    else
        log "Использую настройки по умолчанию"
        update_config "0" "443"
        if [ -x "/etc/init.d/byedpi" ]; then
            /etc/init.d/byedpi restart
        fi
    fi
    
    release_lock
    
    log "=== Автоподбор завершен ==="
}

trap 'log "Прерывание..."; release_lock; exit 1' INT TERM

main "$@"
