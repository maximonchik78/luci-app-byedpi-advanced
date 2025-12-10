#!/bin/sh

# Тестирование различных режимов ByeDPI

MODES="0 1 2 3 4 5 6"
PORTS="443 80 8080"
TEST_URL="https://rutracker.org"

test_mode() {
    mode="$1"
    port="$2"
    
    echo "Testing mode $mode on port $port..."
    
    /usr/sbin/byedpi --daemon -p "$port" --mode "$mode" &
    pid=$!
    
    sleep 3
    
    if curl -s -I --connect-timeout 5 "$TEST_URL" >/dev/null 2>&1; then
        echo "Mode $mode on port $port: SUCCESS"
        kill "$pid" 2>/dev/null
        return 0
    else
        echo "Mode $mode on port $port: FAILED"
        kill "$pid" 2>/dev/null
        return 1
    fi
}

echo "Starting ByeDPI mode testing..."
echo "Test URL: $TEST_URL"
echo ""

for port in $PORTS; do
    for mode in $MODES; do
        if test_mode "$mode" "$port"; then
            echo "Found working combination: mode=$mode, port=$port"
            exit 0
        fi
    done
done

echo "No working combination found"
exit 1
